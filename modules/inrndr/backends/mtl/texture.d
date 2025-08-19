/**
    Metal Textures

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module mtl.texture;
import metal.device;
import metal.types;
import metal.drawable;
import inmath;
import numem;

public import inrndr.texture;
public import metal.texture;
public import metal.pixelformat;
public import sdl.metal;

/**
    Converts inui pixel format to metal pixel format.
*/
MTLPixelFormat toMTLPixelFormat(PixelFormat format) @nogc {
    final switch(format) {
        case PixelFormat.ds24_8:
            return MTLPixelFormat.Depth24Unorm_Stencil8;

        case PixelFormat.r8Unorm:
            return MTLPixelFormat.R8Unorm;

        case PixelFormat.rgb24Unorm:
        case PixelFormat.rgb32Unorm:
        case PixelFormat.rgba32Unorm:
            return MTLPixelFormat.RGBA8Unorm;

        case PixelFormat.bgra32Unorm:
            return MTLPixelFormat.BGRA8Unorm;

        case PixelFormat.sbgra32Unorm:
            return MTLPixelFormat.BGRA8Unorm_sRGB;

        case PixelFormat.srgb24Unorm:
        case PixelFormat.srgb32Unorm:
        case PixelFormat.srgba32Unorm:
            return MTLPixelFormat.RGBA8Unorm_sRGB;
            
        case PixelFormat.rgba128f:
            return MTLPixelFormat.RGBA32Float;
    }
}

/**
    Converts metal pixel format to inui pixel format.
*/
PixelFormat fromMTLPixelFormat(MTLPixelFormat format) @nogc {
    switch(format) {
        case MTLPixelFormat.Depth24Unorm_Stencil8:
            return PixelFormat.ds24_8;

        case MTLPixelFormat.R8Unorm:
            return PixelFormat.r8Unorm;

        case MTLPixelFormat.RGBA8Unorm:
            return PixelFormat.rgba32Unorm;

        case MTLPixelFormat.RGBA8Unorm_sRGB:
            return PixelFormat.srgba32Unorm;

        case MTLPixelFormat.BGRA8Unorm:
            return PixelFormat.bgra32Unorm;

        case MTLPixelFormat.BGRA8Unorm_sRGB:
            return PixelFormat.sbgra32Unorm;
            
        case MTLPixelFormat.RGBA32Float:
            return PixelFormat.rgba128f;
        
        default:
            return PixelFormat.rgba32Unorm;
    }
}

/**
    Gets the byte stride for a pixel format.
*/
pragma(inline, true)
uint toMTLStride(PixelFormat fmt) @nogc nothrow {
    final switch(fmt) {

        case PixelFormat.r8Unorm:
            return 1;

        case PixelFormat.ds24_8:
        case PixelFormat.rgb24Unorm:
        case PixelFormat.srgb24Unorm:
        case PixelFormat.rgb32Unorm:
        case PixelFormat.srgb32Unorm:
        case PixelFormat.rgba32Unorm:
        case PixelFormat.srgba32Unorm:
        case PixelFormat.bgra32Unorm:
        case PixelFormat.sbgra32Unorm:
            return 4;

        case PixelFormat.rgba128f:
            return 16;
    }
}

class MetalTexture : Texture {
private:
@nogc:
    uint width_;
    uint height_;
    PixelFormat format_;
    MTLTexture texture_;
    MTLDrawable drawable_;

    TextureFilter minFilter_;
    TextureFilter magFilter_;
    TextureWrap wrapMode_;

public:

    /**
        Width of the texture
    */
    override @property uint width() const => width_;

    /**
        Height of the texture
    */
    override @property uint height() const => height_;

    /**
        The pixel format of the texture
    */
    override @property PixelFormat format() const => format_;

    /**
        Whether the texture belongs to a swapchain surface.
    */
    override @property bool isSurface() const => drawable_ !is null;

    /**
        Minification filter.
    */
    override @property TextureFilter minFilter() => minFilter_;
    override @property void minFilter(TextureFilter value) {
        this.minFilter_ = value;
    }

    /**
        Magnification filter.
    */
    override @property TextureFilter magFilter() => magFilter_;
    override @property void magFilter(TextureFilter value) {
        this.magFilter_ = value;
    }

    /**
        Wrapping mode.
    */
    override @property TextureWrap wrapMode() => wrapMode_;
    override @property void wrapMode(TextureWrap value) {
        this.wrapMode_ = value;
    }

    /**
        The underlying metal texture.
    */
    @property MTLTexture texture() => texture_;

    /**
        The underlying metal drawable.
    */
    @property MTLDrawable drawable() => drawable_;

    ~this() {
        if (!drawable_ && texture_)
            this.texture_.release();
    }

    /// Constructor
    this(MTLDevice device, uint width, uint height, PixelFormat format) {
        this.width_ = width;
        this.height_ = height;
        this.format_ = format;
        this.texture_ = device.newTexture(MTLTextureDescriptor.create2D(
            format.toMTLPixelFormat(),
            width,
            height,
            false
        ));
    }

    this(MTLTexture texture) {
        this.width_ = cast(uint)texture.width;
        this.height_ = cast(uint)texture.height;
        this.format_ = texture.pixelFormat.fromMTLPixelFormat();
        this.texture_ = texture;
    }

    this(CAMetalDrawable drawable) {
        this.width_ = cast(uint)drawable.texture.width;
        this.height_ = cast(uint)drawable.texture.height;
        this.format_ = drawable.texture.pixelFormat.fromMTLPixelFormat();
        this.texture_ = drawable.texture;
        this.drawable_ = drawable;
    } 

    override
    void updateRegion(void[] data, uint width, uint height, PixelFormat format, vec2i position = vec2i(0, 0)) {
        texture_.replace(
            MTLRegion(
                MTLOrigin(position.x, position.y, 0), 
                MTLSize(width, height, 1)
            ), 
            0, 
            data.ptr, 
            width*format.toMTLStride()
        );
    }

    override
    void updateRegion(void[] data, uint width, uint height, PixelFormat format, recti area, vec2i position = vec2i(0, 0)) {

        // The clipped region of the update region
        recti src = area.clipped(recti(0, 0, width, height));
        recti dst = recti(position.x, position.y, src.width, src.height).clipped(recti(0, 0, this.width, this.height));

        // Out of bounds update.
        if (dst.width <= 0 || src.width <= 0 || dst.height <= 0 || src.height <= 0)
            return;
        
        size_t stride = format.toMTLStride();
        size_t dataOffset = ((width * area.y) * stride) + (area.x * stride);
        size_t dataSize = (area.width * area.height * stride);
        
        // Out of bounds read.
        if (dataOffset+dataSize >= data.length)
            return;

        texture_.replace(
            MTLRegion(
                MTLOrigin(dst.x, dst.y, 0), 
                MTLSize(dst.width, dst.height, 1)
            ), 
            0, 
            data.ptr + dataOffset, 
            width*stride
        );
    }
}

class MetalSwapChain : SwapChain {
private:
@nogc:
    SDL_MetalView view;
    CAMetalLayer layer;
    CAMetalDrawable drawable_;

public:
    ~this() {
        layer.release();
        SDL_Metal_DestroyView(view);
    }

    this(SDL_MetalView view, MTLDevice device) {
        this.view = view;
        this.layer = cast(CAMetalLayer)SDL_Metal_GetLayer(view);
        this.layer.device = device;
    }

    override
    Texture next() {

        import mtl.texture : MetalTexture;
        this.drawable_ = this.layer.next();
        return nogc_new!MetalTexture(this.layer.next());
    }
}
