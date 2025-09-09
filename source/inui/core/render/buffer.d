/**
    Renderer Buffers

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.buffer;
import inui.core.render.device;
import sdl.gpu;

/**
    Types of buffers.
*/
enum BufferType : uint {
    staging = SDL_GPUTransferBufferUsage.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
    vertex  = SDL_GPUBufferUsageFlags.SDL_GPU_BUFFERUSAGE_VERTEX,
    index   = SDL_GPUBufferUsageFlags.SDL_GPU_BUFFERUSAGE_INDEX,
    uniform = SDL_GPUBufferUsageFlags.SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
}

/**
    Buffer creation descriptor.
*/
struct BufferDescriptor {
    BufferType type;
    uint size;
}

/**
    A GPU Buffer
*/
class Buffer : GPUObject {
private:
@nogc:
    BufferDescriptor desc;
    void* handle_;

    void* createBuffer(BufferDescriptor desc) {
        switch(desc.type) {
            case BufferType.staging:
                auto createInfo = SDL_GPUTransferBufferCreateInfo(
                    cast(SDL_GPUTransferBufferUsage)desc.type,
                    desc.size,
                    null
                );
                return cast(void*)SDL_CreateGPUTransferBuffer(
                    gpuHandle, 
                    &createInfo
                );
                break;

            case BufferType.vertex:
            case BufferType.index:
            case BufferType.uniform:
                auto createInfo = SDL_GPUBufferCreateInfo(
                    cast(SDL_GPUBufferUsageFlags)desc.type,
                    desc.size,
                    null
                );
                return cast(void*)SDL_CreateGPUBuffer(
                    gpuHandle, 
                    &createInfo
                );
                break;
        }
    }

    void destroyBuffer(BufferType type, ref void* handle) {
        switch(type) {
            case BufferType.staging:
                SDL_ReleaseGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle);
                break;

            case BufferType.vertex:
            case BufferType.index:
            case BufferType.uniform:
                SDL_ReleaseGPUBuffer(gpuHandle, cast(SDL_GPUBuffer*)handle);
                break;
        }
        handle = null;
    }

public:

    /**
        The type of the buffer.
    */
    final @property BufferType type() => desc.type;

    /**
        The size of the buffer in bytes.
    */
    final @property uint size() => desc.size;

    /**
        The SDL_GPU handle to the buffer.
    */
    final @property void* handle() => handle_;

    // Destructor
    ~this() {
        this.destroyBuffer(desc.type, handle_);
    }

    /**
        Construcst a new buffer.

        Params:
            device =    The owning device.
            desc =      The buffer creation descriptor.
    */
    this(RenderingDevice device, BufferDescriptor desc) {
        super(device);
        this.desc = desc;
        this.handle_ = this.createBuffer(desc);
    }

    /**
        Resizes the buffer, invalidating the old low level buffer.

        Params:
            newSize = The new size of the buffer.
    */
    void resize(uint newSize) {
        this.destroyBuffer(type, handle_);
        desc.size = newSize;
        this.handle_ = this.createBuffer(desc);
    }

    /**
        Maps the buffer into system visible memory.
        
        Returns:
            The mapped buffer region as a slice,
            returns an empty slice for non-staging buffers.

        Notes:
            The buffer MUST be a staging buffer.
    */
    void[] map() {
        if (desc.type != BufferType.staging)
            return null;

        return SDL_MapGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle_, true)[0..desc.size];
    }

    /**
        Unmaps the buffer.
    */
    void unmap() {
        if (desc.type != BufferType.staging)
            return;
        SDL_UnmapGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle_);
    }
}