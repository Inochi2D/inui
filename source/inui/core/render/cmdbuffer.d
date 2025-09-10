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
import inui.core.render.eh;
import nulib;
import numem;
import sdl.gpu;
import sdl.error;

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
    Texture2D swapchainTexture;
    uint encoderDepth = 0;

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
    this(CommandQueue queue) {
        this.queue = queue;
        this.handle_ = enforceSDL(SDL_AcquireGPUCommandBuffer(queue.device.handle));
    }

    /**
        Acquires texture from the swapchain.

        This texture must only be used by this command buffer,
        the swapchain will flip with the conclusion of this
        command buffer.
    */
    Texture2D acquireSwapchainTexture() {
        if (!device.swapchain)
            return null;

        if (!swapchainTexture) 
            swapchainTexture = device.swapchain.claimNext(this);
        return swapchainTexture;
    }

    /**
        Begins a new render pass.
    */
    RenderCommandEncoder beginRenderPass(RenderPassDescriptor desc) {
        encoderDepth++;
        return nogc_new!RenderCommandEncoder(this, desc);
    }

    /**
        Begins a new transfering pass.

        Returns:
            A new encoder if the operation succeeded,
            $(D null) otherwise.
    */
    TransferCommandEncoder beginTransferPass() {
        encoderDepth++;
        return nogc_new!TransferCommandEncoder(this, SDL_BeginGPUCopyPass(handle_));
    }

    /**
        Generates mimaps for the given texture.

        Params:
            texture = The texture to generate mimpmaps for.
    */
    void generateMipmapsFor(Texture2D texture) {
        if (encoderDepth > 0)
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
protected:
@nogc:
    CommandBuffer parent;

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
        parent.encoderDepth--;

        auto self = this;
        nogc_delete(self);
    }
}