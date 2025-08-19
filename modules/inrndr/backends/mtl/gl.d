/**
    Apple-Metal OpenGL Context

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module mtl.gl;
import inrndr.texture;
import inrndr.gl;
import metal;
import mtl.bindings.cv;
import numem.core.exception;
import corefoundation;
import corefoundation.cfdictionary;
import corefoundation.cfnumber;
import coregraphics.opengl;
import foundation;
import nulib;
import objc;

class AppleGLContext : GLContext {
private:
@nogc:
    CGLPixelFormatObj glFormat_;
    CGLContextObj glContext_;

    // Bridged textures
    CVPixelBufferRef glPixbuf_;
    CVOpenGLTextureCacheRef glTextureCache_;
    CVOpenGLTextureRef glTexture_;

    // Creates the GL context.
    void create(uint width, uint height) {
        int npix;
        CGLPixelFormatAttribute[4] attribs = [
            kCGLPFAAccelerated,
            kCGLPFAOpenGLProfile,
            kCGLOGLPVersion_GL4_Core,
            0
        ];

        // CV Buffer Props
        void*[2] keys = [cast(void*)kCVPixelBufferOpenGLCompatibilityKey, cast(void*)kCVPixelBufferMetalCompatibilityKey];
        void*[2] values = [cast(void*)kCFBooleanTrue, cast(void*)kCFBooleanTrue];
        CFDictionaryRef cvBufferProps = CFDictionaryCreate(null, cast(const(void)**)keys.ptr, cast(const(void)**)values.ptr, values.length, null, null);

        // Create GL Context
        enforce(CGLChoosePixelFormat(attribs.ptr, glFormat_, npix) == kCGLNoError, "Could not create a pixel format for an OpenGL 4.1 Core context!");
        enforce(CGLCreateContext(glFormat_, null, glContext_) == kCGLNoError, "Could not create an OpenGL 4.1 Core context!");

        // Create the pixel buffer
        enforce(
            CVPixelBufferCreate(null, width, height, __gl_mtl_format.cvPixelFormat, cvBufferProps, glPixbuf_) == kCVReturnSuccess, 
            "Failed to create pixel buffer."
        );

        // Create Texture Cache
        enforce(
            CVOpenGLTextureCacheCreate(null, null, glContext_, glFormat_, null, glTextureCache_) == kCVReturnSuccess, 
            "Failed to create OpenGL Texture Cache"
        );

        // Create Color Image
        enforce(
            CVOpenGLTextureCacheCreateTextureFromImage(null, glTextureCache_, glPixbuf_, null, glTexture_) == kCVReturnSuccess,
            "Failed to create framebuffer texture!"
        );
    }

public:

    /**
        Major version of the OpenGL Context
    */
    override
    @property uint major() => 0;

    /**
        Minor version of the OpenGL Context
    */
    override
    @property uint minor() => 0;

    /**
        List of extensions supported by the OpenGL Context
    */
    override
    @property string[] extensions() => [];

    /**
        The framebuffer of the given context.
    */
    override
    @property Texture framebuffer() => null;

    /**
        Makes the given 
    */
    override
    void makeCurrent() {

        CGLSetCurrentContext(glContext_);
        super.makeCurrent();
    }
}

unittest {
    AppleGLContext glctx = new AppleGLContext();
    glctx.create(640, 480);
}

struct AAPLTextureFormatInfo {
    int                 cvPixelFormat;
    MTLPixelFormat      mtlFormat;
    GLuint              glInternalFormat;
    GLuint              glFormat;
    GLuint              glType;
}

// Table of equivalent formats across CoreVideo, Metal, and OpenGL
__gshared const AAPLTextureFormatInfo __gl_mtl_format = 
    // Core Video Pixel Format,               Metal Pixel Format,             GL internalformat, GL format,   GL type
    { CVPixelFormatType.k32BGRA,              MTLPixelFormat.BGRA8Unorm,      GL_RGBA,           GL_BGRA,     GL_UNSIGNED_INT_8_8_8_8_REV };