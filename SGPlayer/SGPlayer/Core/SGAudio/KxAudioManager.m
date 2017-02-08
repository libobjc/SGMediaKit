//
//  KxAudioManager.m
//  kxmovie
//
//  Created by Kolyvan on 23.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

// ios-only and output-only version of Novocaine https://github.com/alexbw/novocaine
// Copyright (c) 2012 Alex Wiltschko


#import "KxAudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>

#define MAX_FRAME_SIZE 4096
#define MAX_CHAN       2

static BOOL checkError(OSStatus error, const char *operation);
static OSStatus renderCallback (void *inRefCon, AudioUnitRenderActionFlags	*ioActionFlags, const AudioTimeStamp * inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData);

@interface KxAudioManager ()

{
    BOOL _initialized;
    BOOL _activated;
    float * _outData;
    AudioUnit _audioUnit;
    AudioStreamBasicDescription _outputFormat;
}

@end

@implementation KxAudioManager

+ (instancetype)audioManager
{
    static KxAudioManager * audioManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioManager = [[self alloc] init];
    });
    return audioManager;
}

- (instancetype)init
{
	if (self = [super init]) {
        _outData = (float *)calloc(MAX_FRAME_SIZE*MAX_CHAN, sizeof(float));
	}	
	return self;
}

- (BOOL)setupAudio
{
    // ----- Audio Unit Setup -----
    
    // Describe the output unit.

    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_RemoteIO;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent component = AudioComponentFindNext(NULL, &description);
    if (checkError(AudioComponentInstanceNew(component, &_audioUnit),
                   "Couldn't create the output audio unit"))
        return NO;
    
    UInt32 size;
	
	// Check the output stream format
	size = sizeof(AudioStreamBasicDescription);
	if (checkError(AudioUnitGetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        &size),
                   "Couldn't get the hardware output stream format"))
        return NO;
    
    
    _outputFormat.mSampleRate = self.samplingRate;
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        size),
                   "Couldn't set the hardware output stream format")) {
        
        // just warning
    }

    _numBytesPerSample = _outputFormat.mBitsPerChannel / 8;
    _numOutputChannels = _outputFormat.mChannelsPerFrame;
    
    // Slap a render callback on the unit
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_SetRenderCallback,
                                        kAudioUnitScope_Input,
                                        0,
                                        &callbackStruct,
                                        sizeof(callbackStruct)),
                   "Couldn't set the render callback on the audio unit"))
        return NO;
    
	if (checkError(AudioUnitInitialize(_audioUnit),
                   "Couldn't initialize the audio unit"))
        return NO;
    
    return YES;
}

- (BOOL)renderFrames:(UInt32)numFrames ioData:(AudioBufferList *)ioData
{
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    
    if (_playing && self.delegate) {
//        NSTimeInterval time = [NSDate date].timeIntervalSince1970;
//        NSLog(@"audio callback");
        [self.delegate audioManager:self outputData:_outData numberOfFrames:numFrames numberOfChannels:_numOutputChannels];
//        NSLog(@"audio done time : %f", [NSDate date].timeIntervalSince1970 - time);
        // Put the rendered data into the output buffer
        if (_numBytesPerSample == 4) // then we've already got floats
        {
            float zero = 0.0;
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    vDSP_vsadd(_outData+iChannel, _numOutputChannels, &zero, (float *)ioData->mBuffers[iBuffer].mData, thisNumChannels, numFrames);
                }
            }
        }
        else if (_numBytesPerSample == 2) // then we need to convert SInt16 -> Float (and also scale)
        {
            float scale = (float)INT16_MAX;
            vDSP_vsmul(_outData, 1, &scale, _outData, 1, numFrames*_numOutputChannels);

            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    vDSP_vfix16(_outData+iChannel, _numOutputChannels, (SInt16 *)ioData->mBuffers[iBuffer].mData+iChannel, thisNumChannels, numFrames);
                }
            }
        }        
    }

    return noErr;
}

- (BOOL)activateAudioSession
{
    if (!_activated) {
        if ([self setupAudio]) {
            _activated = YES;
        }
    }
    return _activated;
}

- (void)deactivateAudioSession
{
    if (_activated) {
        [self pause];
        checkError(AudioUnitUninitialize(_audioUnit),
                   "Couldn't uninitialize the audio unit");
        
        /*
        fails with error (-10851) ? 
         
        checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_SetRenderCallback,
                                        kAudioUnitScope_Input,
                                        0,
                                        NULL,
                                        0),
                   "Couldn't clear the render callback on the audio unit");
        */
                
        checkError(AudioComponentInstanceDispose(_audioUnit),
                   "Couldn't dispose the output audio unit");
        _activated = NO;
    }
}

- (void) pause
{	
	if (_playing) {
        _playing = checkError(AudioOutputUnitStop(_audioUnit), "Couldn't stop the output unit");
	}
}

- (BOOL)play
{    
    if (!_playing) {
        if ([self activateAudioSession]) {
            _playing = !checkError(AudioOutputUnitStart(_audioUnit), "Couldn't start the output unit");
        }
	}
    return _playing;
}

- (Float32)outputVolume
{
    return [AVAudioSession sharedInstance].outputVolume;
}

- (Float64)samplingRate
{
    return [AVAudioSession sharedInstance].sampleRate;
}

- (void)dealloc
{
    if (_outData) {
        free(_outData);
        _outData = NULL;
    }
}

@end

#pragma mark - callbacks

static OSStatus renderCallback (void						*inRefCon,
                                AudioUnitRenderActionFlags	* ioActionFlags,
                                const AudioTimeStamp 		* inTimeStamp,
                                UInt32						inOutputBusNumber,
                                UInt32						inNumberFrames,
                                AudioBufferList				* ioData)
{
	KxAudioManager *sm = (__bridge KxAudioManager *)inRefCon;
    return [sm renderFrames:inNumberFrames ioData:ioData];
}

static BOOL checkError(OSStatus error, const char *operation)
{
	if (error == noErr)
        return NO;
	
	char str[20] = {0};
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)error);
    return YES;
}
