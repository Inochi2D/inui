/**
    Metal Data Buffer

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module mtl.buffer;
import foundation.core;
import inrndr.context;
import inmath;
import numem;

public import inrndr.buffer;
public import metal.device;
public import metal.buffer;
public import metal.resource;

class MetalBuffer : Buffer {
private:
@nogc:
    uint bufferSize_;
    MTLBuffer buffer_;

public:

    /**
        Length of the buffer in bytes.
    */
    override @property uint length() => bufferSize_;

    /**
        The underlying metal buffer.
    */
    @property MTLBuffer buffer() => buffer_;

    ~this() {
        buffer_.autorelease();
    }

    /// Constructor
    this(MTLDevice device, uint length) {
        auto flags = cast(MTLResourceOptions)(MTLResourceOptions.HazardTrackingModeDefault | MTLResourceOptions.StorageModeShared);
        
        this.bufferSize_ = length;
        this.buffer_ = device.newBuffer(length, flags);
    }


    /**
        Maps the buffer to a CPU-visible slice.

        Returns:
            A mapped slice.
    */
    override
    void[] map() {
        return buffer_.contents[0..buffer_.length];
    }

    /**
        Ummap the given CPU-visible buffer.
        
        Params:
            buffer = The CPU-visible slice to unmap, owned by this Buffer.
    */
    override
    void unmap(ref void[] slice) {
        slice = null;
    }
}