/**
    Renderer Device

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.device;
import sdl.video;
import sdl.gpu;
import numem;
import nulib;
import inui.core.render.cmdqueue;
import inui.core.render.gpucache;
import inui.core.render.swapchain;
import inui.core.render.texture;
import inui.core.render.buffer;

/**
    A device that can render 3D graphics to the screen
*/
class RenderingDevice : NuRefCounted {
private:
@nogc:
    SDL_GPUDevice* handle_;
    Swapchain swapchain_;
    GPUPipelineCache pipelines_;

public:

    /**
        The SDL_GPUDevice handle that backs this rendering device.
    */
    final @property SDL_GPUDevice* handle() => handle_;

    /**
        The device's swapchain.
    */
    final @property Swapchain swapchain() => swapchain_;

    /**
        The device's shader pipeline cache.
    */
    final @property GPUPipelineCache pipelineCache() => pipelines_;

    /// Destructor
    ~this() {
        SDL_ReleaseWindowFromGPUDevice(handle_, window);
        SDL_DestroyGPUDevice(handle_);
    }

    /**
        Creates a new rendering device for the given window.

        Params:
            window = The window to create the rendering device for.
    */
    this() {
        this.handle_ = SDL_CreateGPUDevice(SDL_SHADER_FORMAT, DEBUG_MODE, null);
        this.pipelines_ = nogc_new!GPUPipelineCache(this);
    }

    /**
        Attaches this rendering device to the given window.

        Params:
            window = The window to attach the device to.
    */
    void attachTo(SDL_Window* window) {
        swapchain_ = nogc_new!Swapchain(this, window);
    }

    /**
        Creates a new command queue.

        Returns:
            A new $(D CommandQueue) instance.
    */
    CommandQueue createQueue() {
        return nogc_new!CommandQueue(this);
    }

    /**
        Creates a new texture.

        Params:
            desc = The descriptor for the texture.

        Returns:
            A new $(D Texture2D) instance.
    */
    Texture2D createTexture(TextureDescriptor desc) {
        return nogc_new!Texture2D(this, desc);
    }

    /**
        Creates a new buffer.

        Params:
            desc = The descriptor for the buffer.

        Returns:
            A new $(D Buffer) instance.
    */
    Buffer createBuffer(BufferDescriptor desc) {
        return nogc_new!Buffer(this, desc);
    }
}

/**
    Objects which are owned by a RenderingDevice.
*/
abstract
class GPUObject : NuRefCounted {
private:
@nogc:
    RenderingDevice device;

protected:

    /**
        The SDL_GPUDevice handle that backs this object.
    */
    final @property SDL_GPUDevice* gpuHandle() => device.handle;

public:

    /**
        Gets the object's device.
    */
    final @property RenderingDevice device() => device;

    /**
        Base constructor.
    */
    this(RenderingDevice device) {
        this.device = device;
    }
}


// The shader format in use.
version(OSX) enum SDL_SHADER_FORMAT = SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_MSL;
else version(iOS) enum SDL_SHADER_FORMAT = SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_MSL;
else enum SDL_SHADER_FORMAT = SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV;

//
//              IMPLEMENTATION DETAILS
//
private:

// Whether to use a debug mode context.
debug enum DEBUG_MODE = true;
else enum DEBUG_MODE = false;