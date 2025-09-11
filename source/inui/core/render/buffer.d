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

            case BufferType.uniform:
                return nu_malloc(desc.size);
            
            default:
                return null;
        }
    }

    void destroyBuffer(BufferType type) {
        switch(type) {
            case BufferType.staging:
                SDL_ReleaseGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle_);
                break;

            case BufferType.vertex:
            case BufferType.index:
                SDL_ReleaseGPUBuffer(gpuHandle, cast(SDL_GPUBuffer*)handle_);
                break;
            
            case BufferType.uniform:
                nu_free(handle_);
                break;
            
            default:
                break;
        }
        this.handle_ = null;
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
        this.destroyBuffer(desc.type);
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
        this.destroyBuffer(type);
        this.desc.size = newSize;
        this.handle_ = this.createBuffer(desc);
    }

    /**
        Sets the content of the buffer, either directly or by using the
        device's staging buffer queue.

        Params:
            data =      The data to upload to the buffer.
            offset =    The offset to upload the data at.
    */
    void set(void[] data, uint offset = 0) {
        import nulib.math : min;
        
        if (data.length == 0)
            return;
        
        switch(desc.type) {
            case BufferType.staging:
                auto mapped = SDL_MapGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle_, true)[0..desc.size];
                    size_t toSet = min(data.length, mapped.length);
                    mapped[offset..offset+toSet] = data[0..toSet];
                SDL_UnmapGPUTransferBuffer(gpuHandle, cast(SDL_GPUTransferBuffer*)handle_);
                break;
            
            case BufferType.uniform:
                auto mapped = handle_[0..desc.size];
                
                size_t toSet = min(data.length, mapped.length);
                mapped[offset..offset+toSet] = data[0..toSet];
                break;

            default:
                device.staging.enqueue(this, data, offset);
                break;

        }
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