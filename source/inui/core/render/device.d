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
import inui.core.render.staging;
import inui.core.render.buffer;
import inui.core.render.shader;
import inui.core.render.eh;

/**
    A device that can render 3D graphics to the screen.
*/
class RenderingDevice : NuRefCounted {
private:
@nogc:
    SDL_GPUDevice* handle_;
    Swapchain swapchain_;
    GPUPipelineCache pipelines_;
    StagingBuffer staging_;
    
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
        The device's internal staging buffer.
    */
    final @property StagingBuffer staging() => staging_;

    /**
        The device's shader pipeline cache.
    */
    final @property GPUPipelineCache pipelineCache() => pipelines_;

    /// Destructor
    ~this() {
        nogc_delete(swapchain_);
        nogc_delete(pipelines_);
        nogc_delete(staging_);
        SDL_DestroyGPUDevice(handle_);
    }

    /**
        Creates a new rendering device for the given window.

        Params:
            window = The window to create the rendering device for.
    */
    this(SDL_Window* window) {
        this();
        this.attachTo(window);
    }

    /**
        Creates a new stand-alone rendering device
    */
    this() {
        this.handle_ = enforceSDL(SDL_CreateGPUDevice(SDL_SHADER_FORMAT, DEBUG_MODE, null));
        this.pipelines_ = nogc_new!GPUPipelineCache(this);
        this.staging_ = nogc_new!StagingBuffer(this);
    }

    /**
        Attaches this rendering device to the given window.

        Params:
            window = The window to attach the device to.
    */
    void attachTo(SDL_Window* window) {
        swapchain_ = nogc_new!Swapchain(this, window);
        swapchain_.applySettings();
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
        Creates a new sampler.

        Params:
            desc = The descriptor for the sampler.

        Returns:
            A new $(D Sampler) instance.
    */
    Sampler createSampler(SamplerDescriptor desc) {
        return nogc_new!Sampler(this, desc);
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

    /**
        Creates a new shader.

        Params:
            desc = The descriptor for the shader.

        Returns:
            A new $(D Shader) instance.
    */
    Shader createShader(ShaderDescriptor desc) {
        return nogc_new!Shader(this, desc);
    }

    /**
        Flushes any pending staging requests for the device.
    */
    void flush() {
        staging_.flush();
    }
}

/**
    Objects which are owned by a RenderingDevice.
*/
abstract
class GPUObject : NuRefCounted {
private:
@nogc:
    RenderingDevice device_;

protected:

    /**
        The SDL_GPUDevice handle that backs this object.
    */
    final @property SDL_GPUDevice* gpuHandle() => device_.handle;

public:

    /**
        Gets the object's device.
    */
    final @property RenderingDevice device() => device_;

    /**
        Base constructor.
    */
    this(RenderingDevice device) {
        this.device_ = device;
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