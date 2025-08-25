/**
    Data Buffer

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inrndr.buffer;
import inrndr.context;
import inmath;
import numem;

/**
    A buffer storing data that can be passed to a shader.
*/
abstract
class Buffer : NuRefCounted {
public:
@nogc:

    /**
        Length of the buffer in bytes.
    */
    abstract @property uint length();

    /**
        Maps the buffer to a CPU-visible slice.

        Returns:
            A mapped slice.
    */
    abstract void[] map();

    /**
        Ummap the given CPU-visible buffer.
        
        Params:
            slice = The CPU-visible slice to unmap, owned by this Buffer.
    */
    abstract void unmap(ref void[] slice);

    /**
        Sets data in the buffer.
    */
    final void set(void[] data, size_t offset = 0) {
        void[] data_ = cast(ubyte[])map();
        (cast(ubyte[])data_)[offset..offset+data.length] = cast(ubyte[])data[0..$];
        this.unmap(data_);
    }
}

/**
    A cache of buffers.
*/
class BufferCache : NuRefCounted {
private:
@nogc:
    import nulib.collections : vector;

    struct BufferEntry {
        size_t generation;
        Buffer buffer;
    }

    RenderContext owner;
    vector!BufferEntry buffers;

public:

    @property uint bufferCount() => cast(uint)buffers.length;

    /**
        Constructs a new buffer cache for the given context.

        Params:
            owner = The owning render context of the buffer cache.
    */
    this(RenderContext owner) {
        this.owner = owner;
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
                if (!buffers[i].buffer && buffers[i].buffer.length >= length) {
                    buffers[i].generation = 0;
                    result = buffers[i].buffer;
                }
            }
        }

        if (!result) {
            buffers ~= BufferEntry(0, owner.createBuffer(length));
            result = buffers[$-1].buffer;
        }
        return result;
    }
}