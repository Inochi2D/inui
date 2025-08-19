/**
    Textures

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inrndr.texture;
import inrndr.context;
import inmath;
import numem;

/**
    Texture format.
*/
enum PixelFormat : uint {

    /**
        Depth-stencil format with 24 bits for depth,
        and 8 bits for stencil.
    */
    ds24_8,

    /**
        Single 8-bit channel.
    */
    r8Unorm,

    /**
        RGB in the linear RGB colorspace, 8 bits per channel.
    */
    rgb24Unorm,

    /**
        RGB in the sRGB colorspace, 8 bits per channel.
    */
    srgb24Unorm,

    /**
        RGB in the linear RGB colorspace, 
        8 bits per channel, padded to 32 bits.
    */
    rgb32Unorm,

    /**
        RGB in the sRGB colorspace, 
        8 bits per channel, padded to 32 bits.
    */
    srgb32Unorm,

    /**
        RGBA in the linear RGB colorspace, 
        8 bits per channel.
    */
    rgba32Unorm,

    /**
        BGRA in the linear RGB colorspace, 
        8 bits per channel.
    */
    bgra32Unorm,

    /**
        BGRA in the sRGB colorspace, 
        8 bits per channel, padded to 32 bits.
    */
    sbgra32Unorm,

    /**
        RGBA in the sRGB colorspace, 
        8 bits per channel.
    */
    srgba32Unorm,

    /**
        RGBA in the sRGB colorspace, 
        32 bits per channel as floating point units.
    */
    rgba128f
}

/**
    Gets the byte stride for a pixel format.
*/
pragma(inline, true)
uint toStride(PixelFormat fmt) @nogc nothrow {
    final switch(fmt) {

        case PixelFormat.r8Unorm:
            return 1;

        case PixelFormat.rgb24Unorm:
        case PixelFormat.srgb24Unorm:
            return 3;

        case PixelFormat.ds24_8:
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


/**
    Texture filter method.
*/
enum TextureFilter : int {
    nearest,
    linear,
    nearestMipmap,
    linearMipmap,
}

/**
    Texture wrapping mode
*/
enum TextureWrap : int {
    clampToEdge,
    repeat,
    mirrorRepeat
}

/**
    Blending modes
*/
enum BlendMode : uint {
    zero,
    one,
    srcColor,
    oneMinusSrcColor,
    srcAlpha,
    oneMinusSrcAlpha,
    dstColor,
    oneMinusDstColor,
    dstAlpha,
    oneMinusDstAlpha,
}

/**
    A texture that can be used within a rendering context.
*/
abstract
class Texture : NuRefCounted {
public:
@nogc:

    /**
        Width of the texture
    */
    abstract @property uint width() const;

    /**
        Height of the texture
    */
    abstract @property uint height() const;

    /**
        The pixel format of the texture
    */
    abstract @property PixelFormat format() const;

    /**
        Whether the texture belongs to a swapchain surface.
    */
    abstract @property bool isSurface() const;

    /**
        Minification filter.
    */
    abstract @property TextureFilter minFilter();
    abstract @property void minFilter(TextureFilter);

    /**
        Magnification filter.
    */
    abstract @property TextureFilter magFilter();
    abstract @property void magFilter(TextureFilter);

    /**
        Wrapping mode.
    */
    abstract @property TextureWrap wrapMode();
    abstract @property void wrapMode(TextureWrap);

    /**
        Uploads the texture data of the given image into the texture.

        Params:
            data =      The pixel data to upload.
            width =     The width of the data in pixels.
            height =    The height of the data in pixels.
            format =    The pixel format of the data.
            position =  The position within the texture to upload the data to.
    */
    abstract void updateRegion(void[] data, uint width, uint height, PixelFormat format, vec2i position = vec2i(0, 0));

    /**
        Uploads the texture data of the given image into the texture.

        Params:
            data =      The pixel data to upload.
            width =     The width of the data in pixels.
            height =    The height of the data in pixels.
            format =    The pixel format of the data.
            area =      The area of the source data to copy.
            position =  The position within the texture to upload the data to.
    */
    abstract void updateRegion(void[] data, uint width, uint height, PixelFormat format, recti area, vec2i position = vec2i(0, 0));
}

/**
    A swap chain.
*/
abstract
class SwapChain : NuRefCounted {
@nogc:

    /**
        Gets the next texture in the swapchain.
    */
    abstract Texture next();
}
