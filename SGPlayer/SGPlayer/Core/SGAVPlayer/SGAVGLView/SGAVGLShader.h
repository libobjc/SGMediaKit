//
//  SGAVGLShader.h
//  SGPlayer
//
//  Created by Single on 2016/10/8.
//  Copyright © 2016年 single. All rights reserved.
//

#ifndef SGAVGLShader_h
#define SGAVGLShader_h

#define SG_GLES_STRINGIZE(x) #x

static const char vertexShaderString[] = SG_GLES_STRINGIZE
(
     attribute vec4 position;
     attribute vec2 textureCoord;
     uniform mat4 mvpMatrix;
     varying vec2 v_textureCoordinate;
 
     void main()
     {
         v_textureCoordinate = textureCoord;
         gl_Position = mvpMatrix * position;
     }
);

static const char fragmentShaderString[] = SG_GLES_STRINGIZE
(
     precision mediump float;
     
     uniform sampler2D SamplerY;
     uniform sampler2D SamplerUV;
     uniform mat3 colorConversionMatrix;
     varying mediump vec2 v_textureCoordinate;
     
     void main()
     {
         mediump vec3 yuv;
         lowp vec3 rgb;
         
         yuv.x = texture2D(SamplerY, v_textureCoordinate).r - (16.0/255.0);
         yuv.yz = texture2D(SamplerUV, v_textureCoordinate).rg - vec2(0.5, 0.5);
         
         rgb = colorConversionMatrix * yuv;
         
         gl_FragColor = vec4(rgb, 1);
     }
);

#endif
