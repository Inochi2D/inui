/**
    Renderer Command Queues

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.cmdqueue;
import nulib;
import numem;
import sdl.gpu;

/**
    A command queue.
*/
class CommandQueue : GPUObject {
private:
@nogc:
    vector!(SDL_GPUFence*) fences;
    void clearFences() {
        foreach(fence; fences) {
            SDL_ReleaseGPUFence(gpuHandle, fence);
            fence = null;
        }
        
        fences.clear();
    }

public:

    /**
        Acquires a new command buffer.
    */
    this(RenderingDevice device) {
        super(device);
    }

    /**
        Acquires a new command buffer from the queue.
    */
    CommandBuffer newCommandBuffer() {
        return nogc_new!CommandBuffer(this, SDL_AcquireGPUCommandBuffer(gpuHandle));
    }

    /**
        Submits a command buffer to the queue.
    */
    void submit(CommandBuffer buffer) {
        fences ~= SDL_SubmitGPUCommandBufferAndAcquireFence(buffer.handle);
    }

    /**
        Awaits completion of the command buffer.
    */
    void awaitCompletion() {
        if (fences.length > 0)
            SDL_WaitForGPUFences(gpuHandle, true, fences.ptr, fences.length);
        this.clearFences();
    }
}