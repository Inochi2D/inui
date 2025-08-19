/**
    Inui Metal Render Context

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module mtl.context;
import mtl.texture;
import mtl.buffer;
import mtl.shader;
import mtl.pass;
import inmath;
import numem;
import sdl;

import objc.autorelease : arpool_ctx, autoreleasepool_push, autoreleasepool_pop;

public import inrndr.context;
public import metal.device;
public import metal.drawable;
public import metal.commandqueue;
public import metal.types;

class MetalRenderContext : RenderContext {
private:
@nogc:
    SDL_Window* window;
    MTLDevice device;
    MTLCommandQueue queue;
    MetalSwapChain swapchain_;
    arpool_ctx arctx;

public:

    override
    @property SwapChain swapchain() {
        return swapchain_;
    }

    override
    @property string[] validSubContextTypes() => __supported_sub_ctx;

    /**
        Creates an embedded GL context which can be rendered by the render context.

        Params:
            type = The type of sub context to create.
        
        Returns:
            A new sub context if possible,
            $(D null) otherwise.
    */
    override
    SubRenderContext createSubContext(uint width, uint height, string type) {
        switch(type) {
            case "opengl":
                return nogc_new!GLSubContext(this, width, height);
            
            default:
                return null;
        }
    }


    /// Destructor
    ~this() {
        queue.release();
        swapchain_.release();

        this.device = null;
        this.queue = null;
    }

    /// Constructor
    this(SDL_Window* window) {
        this.window = window;

        this.device = MTLDevice.createSystemDefaultDevice();
        this.swapchain_ = nogc_new!MetalSwapChain(SDL_Metal_CreateView(window), device);
        this.queue = device.newCommandQueue();
    }

    override
    Texture createTexture(uint width, uint height, PixelFormat format) {

        import mtl.texture : MetalTexture;
        return nogc_new!MetalTexture(device, width, height, format);
    }

    override
    Buffer createBuffer(uint sizeInBytes) {
        
        import mtl.buffer : MetalBuffer;
        return nogc_new!MetalBuffer(device, sizeInBytes);
    }

    override
    Shader createShader(string source) {
        
        import mtl.shader : MetalShader;
        return nogc_new!MetalShader(device, source);
    }

    override
    CommandBuffer beginPass(RenderPassDescriptor desc) {
        
        import mtl.pass : MetalCommandBuffer;
        return nogc_new!MetalCommandBuffer(queue, desc);
    }

    override
    void submit(ref CommandBuffer buffer) {
        import metal.commandbuffer : MTLCommandBuffer;
        MTLCommandBuffer mtlcmdbuf = (cast(MetalCommandBuffer)buffer).finalize();
        
        foreach(target; buffer.descriptor.targets) {
            if (target.target.isSurface) {
                mtlcmdbuf.present((cast(MetalTexture)target.target).drawable);
                (cast(MetalTexture)target.target).release();
            }
        }
        mtlcmdbuf.commit();
        mtlcmdbuf.waitUntilCompleted();
        buffer.release();
        buffer = null;
    }

    /**
        Called by the user at the start of a frame.
    */
    override
    void beginFrame() {
        arctx = autoreleasepool_push();
    }

    /**
        Called by the user at the end of a frame.
    */
    override
    void endFrame() {
        autoreleasepool_pop(arctx);
    }
}

//
//              SUB-CONTEXTS
//


public import bindbc.opengl;
import nulib.collections.stack;

class GLSubContext : SubRenderContext {
private:
@nogc:
    MTLDevice device;
    CGLContext ctx;
    Texture ctxTexture;

    uint width_, height_;

public:

    ~this() {
        this.ctx.release();
    }

    // Constructor
    this(MetalRenderContext rctx, uint width, uint height) {
        this.device = rctx.device;
        this.resize(width, height);
        super(rctx);
    }

    override @property uint fbWidth() => this.width_;
    override @property uint fbHeight() => this.height_;
    override @property Texture hostFramebuffer() => ctxTexture;
    override @property void* viewFramebuffer() => cast(void*)ctx.glTexture;

    override
    void resize(uint width, uint height) {
        this.width_ = width;
        this.height_ = height;
        if (ctx) {
            ctx.release();
            ctxTexture.release();
        }

        this.ctx = nogc_new!CGLContext(device, width, height);
        this.ctxTexture = nogc_new!MetalTexture(ctx.mtlTexture);
    }

    override
    void beginFrame() {
        ctx.makeCurrent();
    }

    override
    void endFrame() {
        ctx.flush();
    }
}


//
//                  IMPLEMENTATION DETAILS.
//
private:
import mtl.bindings.cv;
import coregraphics.opengl;
import corefoundation.cfdictionary;
import corefoundation.cfnumber;

// Entrypoint for rendering system
export extern(C)
RenderContext __inui_create_render_context_for(SDL_Window* window) @nogc {
    return nogc_new!MetalRenderContext(window);
}

final
class CGLContext : NuRefCounted {
private:
@nogc:
    static
    struct AAPLTextureFormatInfo {
        int                 cvPixelFormat;
        MTLPixelFormat      mtlFormat;
        GLuint              glInternalFormat;
        GLuint              glFormat;
        GLuint              glType;
    }

    static const CGLPixelFormatAttribute[4] __attribs = [
        kCGLPFAAccelerated,
        kCGLPFAOpenGLProfile,
        kCGLOGLPVersion_GL4_Core,
        0
    ];

    static const AAPLTextureFormatInfo __gl_mtl_format = {
        // Core Video Pixel Format,             Metal Pixel Format,             GL internalformat, GL format,   GL type
        CVPixelFormatType.k32BGRA,              MTLPixelFormat.BGRA8Unorm,      GL_RGBA,           GL_BGRA,     GL_UNSIGNED_INT_8_8_8_8_REV
    };

    MTLDevice mtlDevice_;
    CVMetalTextureCacheRef mtlTextureCache_;
    CVMetalTextureRef mtlTexture_;

    CGLPixelFormatObj glFormat_;
    CGLContextObj glContext_;
    CVOpenGLTextureCacheRef glTextureCache_;
    CVOpenGLTextureRef glTexture_;
    
    uint width_, height_;
    CVPixelBufferRef pixbuf_;
    GLuint fbo_;

    // Helper that sets up the OpenGL state
    void create(uint width, uint height) {
        this.width_ = width;
        this.height_ = height;
        int npix;

        // Create GL Context
        enforce(CGLChoosePixelFormat(__attribs.ptr, glFormat_, npix) == kCGLNoError, "Could not create a pixel format for an OpenGL 4.1 Core context!");
        enforce(CGLCreateContext(glFormat_, null, glContext_) == kCGLNoError, "Could not create an OpenGL 4.1 Core context!");

        // Create the pixel buffer
        enforce(
            CVPixelBufferCreate(null, width, height, __gl_mtl_format.cvPixelFormat, getCVBufferProperties(), pixbuf_) == kCVReturnSuccess, 
            "Failed to create pixel buffer."
        );

        // Create Texture Cache
        enforce(
            CVOpenGLTextureCacheCreate(null, null, glContext_, glFormat_, null, glTextureCache_) == kCVReturnSuccess, 
            "Failed to create OpenGL Texture Cache"
        );

        // Create Color Image
        enforce(
            CVOpenGLTextureCacheCreateTextureFromImage(null, glTextureCache_, pixbuf_, null, glTexture_) == kCVReturnSuccess,
            "Failed to create framebuffer texture!"
        );
        
        enforce(
            CVMetalTextureCacheCreate(null, null, mtlDevice_, null, mtlTextureCache_) == kCVReturnSuccess,
            "Failed to create Metal Texture Cache!"
        );
        
        enforce(
            CVMetalTextureCacheCreateTextureFromImage(null, mtlTextureCache_, pixbuf_, null, __gl_mtl_format.mtlFormat, width, height, 0, mtlTexture_) == kCVReturnSuccess,
            "Failed to create Metal Texture!"
        );

        CGLLockContext(glContext_);
        CGLSetCurrentContext(glContext_);
        CGLUnlockContext(glContext_);
        if (!isOpenGLLoaded) 
            loadOpenGL();

        glGenFramebuffers(1, &fbo_);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo_);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE, CVOpenGLTextureGetName(glTexture_), 0);
    }

    // Helper which creates a single reused CFDictionary for the
    // CV buffer properties.
    static CFDictionaryRef getCVBufferProperties() {
        static CFDictionaryRef __cvBufferProps;

        if (!__cvBufferProps) {
            void*[2] keys = [cast(void*)kCVPixelBufferOpenGLCompatibilityKey, cast(void*)kCVPixelBufferMetalCompatibilityKey];
            void*[2] values = [cast(void*)kCFBooleanTrue, cast(void*)kCFBooleanTrue];
            __cvBufferProps = CFDictionaryCreate(null, cast(const(void)**)keys.ptr, cast(const(void)**)values.ptr, values.length, null, null);
        }
        return __cvBufferProps;
    }

public:

    // Destructor
    ~this() {
        CVOpenGLTextureRelease(glTexture_);
        CVOpenGLTextureCacheRelease(glTextureCache_);
        CVPixelBufferRelease(pixbuf_);

        CGLReleaseContext(glContext_);
        CGLReleasePixelFormat(glFormat_);
    }

    @property GLenum glTexture() => CVOpenGLTextureGetName(glTexture_);
    @property MTLTexture mtlTexture() => CVMetalTextureGetTexture(mtlTexture_);
    
    // Constructor
    this(MTLDevice device, uint width, uint height) {
        this.mtlDevice_ = device;
        this.create(width, height);
    }

    void makeCurrent() {
        CGLLockContext(glContext_);
        CGLSetCurrentContext(glContext_);
        CGLUnlockContext(glContext_);
        
        glBindFramebuffer(GL_FRAMEBUFFER, fbo_);
    }

    void flush() {
        glFlush();
    }
}

__gshared string[] __supported_sub_ctx = ["opengl"];