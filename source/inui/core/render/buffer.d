/**
    Renderer Buffers

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.buffer;
import inui.core.render.device;
import sdl.gpu;
import numem;

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
                    0
                );
                return cast(void*)SDL_CreateGPUTransferBuffer(
                    gpuHandle, 
                    &createInfo
                );

            case BufferType.uniform:
                return nu_malloc(desc.size);

            case BufferType.vertex:
            case BufferType.index:
                auto createInfo = SDL_GPUBufferCreateInfo(
                    cast(SDL_GPUBufferUsageFlags)desc.type,
                    desc.size,
                    0
                );
                return cast(void*)SDL_CreateGPUBuffer(
                    gpuHandle, 
                    &createInfo
                );
            
            default:
                return null;
        }
    }

    void destroyBuffer(BufferType type, ref void* handle) {
        switch(type) {
            case BufferType.uniform:
                nu_free(handle_);
                handle_ = null;
                break;

            case BufferType.staging:
                SDL_ReleaseGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle);
                break;

            case BufferType.vertex:
            case BufferType.index:
                SDL_ReleaseGPUBuffer(gpuHandle, cast(SDL_GPUBuffer*)handle);
                break;
            
            default:
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
            The buffer MUST be either a uniform or staging buffer.
    */
    void[] map() {
        if (desc.type == BufferType.staging)
            return SDL_MapGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle_, true)[0..desc.size];
        
        if (desc.type == BufferType.uniform)
            return handle_[0..desc.size];

        return null;
    }

    /**
        Unmaps the buffer.
    */
    void unmap() {
        if (desc.type != BufferType.staging)
            return;
        
        SDL_UnmapGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle_);
    }

    /**
        
        Notes:
            The buffer MUST be either a uniform or staging buffer.
    */
    void set(void[] data) {
        import nulib.math : min;
        
        if (data.length == 0)
            return;

        auto mapped = map();
        size_t toSet = min(data.length, mapped.length);
        mapped[0..toSet] = data[0..toSet];
        this.unmap();
    }
}

/**
    A cache of buffers.
*/
class BufferCache : GPUObject {
private:
@nogc:
    import nulib.collections : vector;

    struct BufferEntry {
        size_t generation;
        Buffer buffer;
    }

    BufferType toCreate;
    vector!BufferEntry buffers;

public:

    @property uint bufferCount() => cast(uint)buffers.length;

    /**
        Constructs a new buffer cache for the given context.

        Params:
            owner = The owning render context of the buffer cache.
            type =  The type of buffers to create.
    */
    this(RenderingDevice owner, BufferType type) {
        super(owner);
        this.toCreate = type;
    }

    /**
        Dequeues a buffer from the cache.
        If no fitting buffer is found, 
    */
    Buffer dequeueBuffer(uint length) {
        Buffer result = null;

        foreach_reverse(i; 0..buffers.length) {
            buffers[i].generation++;
            if (buffers[i].generation > 10) {
                buffers[i].buffer.release();
                buffers.removeAt(i);
            }

            if (i >= buffers.length)
                break;

            if (!result) {
                if (!buffers[i].buffer && buffers[i].buffer.size >= length) {
                    buffers[i].generation = 0;
                    result = buffers[i].buffer;
                }
            }
        }

        if (!result) {
            buffers ~= BufferEntry(0, device.createBuffer(BufferDescriptor(
                toCreate,
                length
            )));
            result = buffers[$-1].buffer;
        }
        return result;
    }
}