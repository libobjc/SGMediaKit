//
//  SGAudioManager.m
//  SGMediaKit
//
//  Created by Single on 09/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGAudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

static int const max_frame_size = 4096;
static int const max_chan = 2;

static NSError * checkError(OSStatus result, NSString * domain);
static OSStatus renderCallback (void * inRefCon,
                                AudioUnitRenderActionFlags * ioActionFlags,
                                const AudioTimeStamp * inTimeStamp,
                                UInt32 inOutputBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList * ioData);

@interface SGAudioManager ()

{
    float * _outData;
    AudioUnit _audioUnit;
    AudioStreamBasicDescription _audioOutputFormat;
}

@property (nonatomic, assign) BOOL registered;
@property (nonatomic, strong) AVAudioSession * audioSession;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) NSError * warning;

@end

@implementation SGAudioManager

+ (instancetype)manager
{
    static SGAudioManager * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _outData = (float *)calloc(max_frame_size * max_chan, sizeof(float));
    }
    return self;
}

- (BOOL)registerAudioSession
{
    if (!self.registered) {
        if ([self setupAudioUnit]) {
            self.registered = YES;
        }
    }
    return self.registered;
}

- (void)unregisterAudioSession
{
    if (self.registered) {
        OSStatus result = AudioUnitUninitialize(self->_audioUnit);
        self.warning = checkError(result, @"uninitialize the audio unit error");
        if (self.warning) {
            [self delegateWarningCallback];
        }
        
        result = AudioComponentInstanceDispose(self->_audioUnit);
        self.warning = checkError(result, @"dispose the output audio unit error");
        if (self.warning) {
            [self delegateWarningCallback];
        }
        self.registered = NO;
    }
}

- (BOOL)setupAudioUnit
{
    self.audioSession = [AVAudioSession sharedInstance];
    
    OSStatus result;
    UInt32 size;
    
    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_RemoteIO;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponent component = AudioComponentFindNext(NULL, &description);
    result = AudioComponentInstanceNew(component, &self->_audioUnit);
    self.error = checkError(result, @"create audio unit error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    size = sizeof(AudioStreamBasicDescription);
    result = AudioUnitGetProperty(self->_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input, 0,
                                  &self->_audioOutputFormat,
                                  &size);
    self.warning = checkError(result, @"get hardware output stream format error");
    if (self.warning) {
        [self delegateWarningCallback];
    } else {
        if (self.audioSession.sampleRate != self->_audioOutputFormat.mSampleRate) {
            result = AudioUnitSetProperty(self->_audioUnit,
                                          kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Input,
                                          0,
                                          &self->_audioOutputFormat,
                                          size);
            self.warning = checkError(result, @"set hardware output stream format error");
            if (self.warning) {
                [self delegateWarningCallback];
            }
        }
    }
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    result = AudioUnitSetProperty(self->_audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  0,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    self.error = checkError(result, @"set audio unit render callback error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    result = AudioUnitInitialize(self->_audioUnit);
    self.error = checkError(result, @"initialize the audio unit error");
    if (self.error) {
        [self delegateErrorCallback];
        return NO;
    }
    
    return YES;
}

- (OSStatus)renderFrames:(UInt32)numFrames ioData:(AudioBufferList *)ioData
{
    for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    
    if (self.playing && self.delegate)
    {
        [self.delegate audioManager:self outputData:_outData numberOfFrames:numFrames numberOfChannels:self.channelCount];
        
        UInt32 numBytesPerSample = self->_audioOutputFormat.mBitsPerChannel / 8;
        if (numBytesPerSample == 4) {
            float zero = 0.0;
            for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
                    vDSP_vsadd(_outData+iChannel, self.channelCount, &zero, (float *)ioData->mBuffers[iBuffer].mData, thisNumChannels, numFrames);
                }
            }
        }
        else if (numBytesPerSample == 2)
        {
            float scale = (float)INT16_MAX;
            vDSP_vsmul(_outData, 1, &scale, _outData, 1, numFrames*self.channelCount);
            
            for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
                    vDSP_vfix16(_outData+iChannel, self.channelCount, (SInt16 *)ioData->mBuffers[iBuffer].mData+iChannel, thisNumChannels, numFrames);
                }
            }
        }
    }
    
    return noErr;
}

- (void)play
{
    if (!self->_playing) {
        if ([self registerAudioSession]) {
            OSStatus result = AudioOutputUnitStart(self->_audioUnit);
            self.error = checkError(result, @"start output unit error");
            if (self.error) {
                [self delegateErrorCallback];
            } else {
                self->_playing = YES;
            }
        }
    }
}

- (void)pause
{
    if (self->_playing) {
        OSStatus result = AudioOutputUnitStop(self->_audioUnit);
        self.error = checkError(result, @"stop output unit error");
        if (self.error) {
            [self delegateErrorCallback];
        } else {
            self->_playing = NO;
        }
    }
}

- (Float64)samplingRate
{
    return (Float64)self.audioSession.sampleRate;
}

- (UInt32)channelCount
{
    UInt32 number = self->_audioOutputFormat.mChannelsPerFrame;
    if (number > 0) {
        return number;
    }
    return (UInt32)self.audioSession.outputNumberOfChannels;
}

- (void)delegateErrorCallback
{
    if (self.error) {
        NSLog(@"SGAudioManager did error : %@", self.error);
    }
}

- (void)delegateWarningCallback
{
    if (self.warning) {
        NSLog(@"SGAudioManager did warning : %@", self.warning);
    }
}

- (void)dealloc
{
    [self unregisterAudioSession];
    if (_outData) {
        free(_outData);
        _outData = NULL;
    }
}

@end

static NSError * checkError(OSStatus result, NSString * domain)
{
    if (result == noErr) return nil;
    NSError * error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
    return error;
}

static OSStatus renderCallback (void						*inRefCon,
                                AudioUnitRenderActionFlags	* ioActionFlags,
                                const AudioTimeStamp 		* inTimeStamp,
                                UInt32						inOutputBusNumber,
                                UInt32						inNumberFrames,
                                AudioBufferList				* ioData)
{
    SGAudioManager * manager = (__bridge SGAudioManager *)inRefCon;
    return [manager renderFrames:inNumberFrames ioData:ioData];
}
