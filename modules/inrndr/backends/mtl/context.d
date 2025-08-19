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

    /**
        The active swap chain for the rendering context.
    */
    override
    @property SwapChain swapchain() {
        return swapchain_;
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

// Entrypoint for rendering system
export extern(C)
RenderContext __inui_create_render_context_for(SDL_Window* window) @nogc {
    return nogc_new!MetalRenderContext(window);
}