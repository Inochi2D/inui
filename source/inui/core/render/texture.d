/**
    Renderer Texture

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.texture;
import inui.core.render.device;
import sdl.gpu;

/**
    A 2D texture.
*/
class Texture2D : GPUObject {
private:
@nogc:
    bool owned = true;
    TextureDescriptor desc;
    SDL_GPUTexture* handle_;

public:

    /**
        Width of the texture in pixels.
    */
    final @property uint width() => desc.width;

    /**
        Height of the texture in pixels.
    */
    final @property uint height() => desc.height;

    /**
        Mipmapping levels.
    */
    final @property uint levels() => desc.height;

    /**
        The format of the texture.
    */
    final @property TextureFormat format() => desc.format;

    /**
        The underlying SDL_GPU handle.
    */
    final @property SDL_GPUTexture* handle() => handle_;

    // Destructor
    ~this() {
        if (owned)
            SDL_ReleaseGPUTexture(gpuHandle, handle_);
    }

    /**
        Constructs a new texture
        
        Once created the texture's dimensions and format are immutable.

        Params:
            device =    The owning device.
            desc =      Texture descriptor
    */
    this(RenderingDevice device, TextureDescriptor desc) {
        super(device);

        this.desc = desc;
        this.handle_ = SDL_CreateGPUTexture(device.handle, SDL_GPUTextureCreateInfo(
            SDL_GPUTextureType.SDL_GPU_TEXTURETYPE_2D,
            desc.format,
            SDL_GPUTextureUsageFlags.SDL_GPU_TEXTUREUSAGE_COLOR_TARGET |
            SDL_GPUTextureUsageFlags.SDL_GPU_TEXTUREUSAGE_SAMPLER,
            desc.width,
            desc.height,
            1,
            mipLevels,
            SDL_GPUSampleCount.SDL_GPU_SAMPLECOUNT_1,
            null
        ));
    }

    /**
        Creates texture from existing handle.

        This handle will not be owned by the Texture2D.
    */
    this(SDL_GPUTexture* texture, TextureFormat format, uint width, uint height) {
        this.handle_ = handle;
        this.desc.format = format;
        this.desc.width = width;
        this.desc.height = height;
        this.desc.mipLevels = 1;
    }
}

/**
    Texture formats
*/
enum TextureFormat : SDL_GPUTextureFormat {
    none                = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_INVALID,
    a8Unorm             = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_A8_UNORM,
    r8Unorm             = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_R8_UNORM,
    rg8Unorm            = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_R8G8_UNORM,
    rgba8Unorm          = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
    bgra8Unorm          = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM,
    bc1RGBAUnorm        = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM,
    bc2RGBAUnorm        = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM,
    bc3RGBAUnorm        = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM,
    bc4RUnorm           = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC4_R_UNORM,
    bc5RGUnorm          = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC5_RG_UNORM,
    bc7RGBAUnorm        = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM,
    rgba8Unorm_sRGB     = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB,
    bgra8Unorm_sRGB     = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB,
    bc1RGBAUnorm_sRGB   = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB,
    bc2RGBAUnorm_sRGB   = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB,
    bc3RGBAUnorm_sRGB   = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB,
    bc7RGBAUnorm_sRGB   = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB,
    rgba32f             = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT,
    d24s8               = SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT,
}

/**
    Texture descriptor.
*/
struct TextureDescriptor {
    TextureFormat format;
    uint width;
    uint height;
    uint mipLevels;
}

/**
    A texture sampler
*/
class Sampler : GPUObject {
private:
@nogc:
    SamplerDescriptor desc;
    SDL_GPUSampler* handle_;

public:

    /**
        The underlying SDL_GPU handle.
    */
    final @property SDL_GPUSampler* handle() => handle_;

    this(RenderingDevice device, SamplerDescriptor desc) {
        super(device);
        this.desc = desc;

        auto createInfo = desc.toSamplerCreateInfo();
        this.handle_ = SDL_CreateGPUSampler(gpuHandle, &createInfo);
    }
}

/**
    Sampler descriptor
*/
struct SamplerDescriptor {

    /**
        Minification filter.
    */
    TextureFilter minFilter = TextureFilter.bilinear;
    
    /**
        Magnification filter.
    */
    TextureFilter magFilter = TextureFilter.bilinear;
    
    /**
        Wrapping mode for texture U coordinate.
    */
    TextureWrap wrapU = TextureWrap.repeat;
    
    /**
        Wrapping mode for texture V coordinate.
    */
    TextureWrap wrapV = TextureWrap.repeat;

    /**
        Mas anisotropy.
    */
    float maxAnisotropy = 1;

    SDL_GPUSamplerCreateInfo toSamplerCreateInfo() {
        return SDL_GPUSamplerCreateInfo(
            min_filter: minFilter.toGPUFilter(),
            mag_filter: magFilter.toGPUFilter(),
            mipmap_mode: magFilter.toMipmapSampleMode(),
            address_mode_u: wrapU,
            address_mode_v: wrapV,
            address_mode_w: SDL_GPUSamplerAddressMode.SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
            mip_lod_bias: 0,
            min_lod: 0,
            max_lod: 0,
            max_anisotropy: maxAnisotropy,
            enable_anisotropy: maxAnisotropy > 1,
            enable_compare: false
        );
    }
}

/**
    Texture filter
*/
enum TextureFilter {
    nearest,
    linear,
}

/**
    Gets SDL_GPUFilter from a TextureFilter

    Params:
        filter = The filter to query
    
    Returns:
        A corrosponding SDL_GPUFilter
*/
SDL_GPUFilter toGPUFilter(TextureFilter filter) @nogc nothrow pure {
    switch(filter) {
        case TextureFilter.nearest: return SDL_GPUFilter.SDL_GPU_FILTER_NEAREST;
        case TextureFilter.bilinear: return SDL_GPUFilter.SDL_GPU_FILTER_LINEAR;
        case TextureFilter.trilinear: return SDL_GPUFilter.SDL_GPU_FILTER_LINEAR;
        default: return SDL_GPUFilter.SDL_GPU_FILTER_LINEAR;
    }
}

/**
    Gets SDL_GPUSamplerMipmapMode from a TextureFilter

    Params:
        filter = The filter to query
    
    Returns:
        A corrosponding SDL_GPUSamplerMipmapMode
*/
SDL_GPUSamplerMipmapMode toMipmapSampleMode(TextureFilter filter) @nogc nothrow pure {
    switch(filter) {
        case TextureFilter.nearest: return SDL_GPUSamplerMipmapMode.SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
        case TextureFilter.bilinear: return SDL_GPUSamplerMipmapMode.SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
        case TextureFilter.trilinear: return SDL_GPUSamplerMipmapMode.SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
        default: return SDL_GPUSamplerMipmapMode.SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
    }
}

/**
    Texture wrapping modes.
*/
enum TextureWrap : SDL_GPUSamplerAddressMode {
    repeat = SDL_GPUSamplerAddressMode.SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
    mirroredRepeat = SDL_GPUSamplerAddressMode.SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT,
    clampToEdge = SDL_GPUSamplerAddressMode.SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE
}