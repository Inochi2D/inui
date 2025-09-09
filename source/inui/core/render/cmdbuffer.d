/**
    Renderer Command Buffers

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.cmdbuffer;
import inui.core.render.cmdqueue;
import inui.core.render.swapchain;
import inui.core.render.device;
import inui.core.render.texture;
import inui.core.render.buffer;
import nulib;
import numem;
import sdl.gpu;

public import inui.core.render.renderencoder;
public import inui.core.render.transferencoder;

/**
    An ephemeral command buffer object.
*/
class CommandBuffer : NuObject {
private:
@nogc:
    SDL_GPUCommandBuffer* handle_;
    CommandQueue queue;
    CommandEncoder current;
    Texture2D swapchainTexture;

public:

    /**
        The owning device.
    */
    final @property RenderingDevice device() => queue.device;

    /**
        The underlying SDL_GPU handle.
    */
    final @property SDL_GPUCommandBuffer* handle() => handle_;

    // Destructor
    ~this() {
        if (swapchainTexture)
            swapchainTexture.release();
    }

    /**
        Acquires a new command buffer.
    */
    this(CommandQueue queue, SDL_GPUCommandBuffer* handle) {
        this.queue = queue;
        this.handle_ = handle;
    }

    /**
        Acquires texture from the swapchain.

        This texture must only be used by this command buffer,
        the swapchain will flip with the conclusion of this
        command buffer.
    */
    Texture2D acquireSwapchainTexture() {
        if (!swapchainTexture) {
            SDL_GPUTexture* tex;
            uint width;
            uint height;
            SDL_WaitAndAcquireGPUSwapchainTexture(handle_, device.swapchain.handle, &tex, &width, &height);
            swapchainTexture = nogc_new!Texture2D(tex, device.swapchain.textureFormat, width, height);
        }
        return swapchainTexture;
    }

    /**
        Begins a new render pass.
    */
    RenderCommandEncoder beginRenderPass(RenderPassDescriptor desc) {
        if (current)
            return null;

        this.current = nogc_new!RenderCommandEncoder(desc);
        return current;
    }

    /**
        Begins a new transfering pass.

        Returns:
            A new encoder if the operation succeeded,
            $(D null) otherwise.
    */
    TransferCommandEncoder beginTransferPass() {
        if (current)
            return null;

        this.current = nogc_new!TransferCommandEncoder(SDL_BeginGPUCopyPass(handle_));
        return current;
    }

    /**
        Generates mimaps for the given texture.

        Params:
            texture = The texture to generate mimpmaps for.
    */
    void generateMipmapsFor(Texture2D texture) {
        if (current)
            return;
        
        SDL_GenerateMipmapsForGPUTexture(handle_, texture.handle);
    }
}

/**
    Base type for command encoders.

    See_Also:
        $(D TransferCommandEncoder)
        $(D RenderCommandEncoder)
*/
abstract
class CommandEncoder : NuObject {
private:
@nogc:
    CommandBuffer parent;

protected:

    /// Shared Constructor
    this(CommandBuffer parent) {
        this.parent = parent;
    }

public:

    /**
        Stops recording commands into the pass, returning
        control to the parent command buffer.

        Notes:
            This encoder will become invalid after this call,
            any attempts to record to it after ending it will
            result in undefined behaviour.
    */
    void end() {
        nogc_delete(parent.current);
    }
}