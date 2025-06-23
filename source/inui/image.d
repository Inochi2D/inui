module inui.image;
import numem;

/**
    Texture format.
*/
enum PixelFormat : int {

    /**
        Depth-stencil format with 24 bits for depth,
        and 8 bits for stencil.
    */
    ds24_8,

    /**
        Single 8-bit channel.
    */
    r8,

    /**
        RGB in the linear RGB colorspace, 8 bits per channel.
    */
    rgb24,

    /**
        RGB in the sRGB colorspace, 8 bits per channel.
    */
    srgb24,

    /**
        RGB in the linear RGB colorspace, 
        8 bits per channel, padded to 32 bits.
    */
    rgb32,

    /**
        RGB in the sRGB colorspace, 
        8 bits per channel, padded to 32 bits.
    */
    srgb32,

    /**
        RGBA in the linear RGB colorspace, 
        8 bits per channel.
    */
    rgba32,

    /**
        RGBA in the sRGB colorspace, 
        8 bits per channel.
    */
    srgba32,

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

        case PixelFormat.r8:
            return 1;

        case PixelFormat.rgb24:
        case PixelFormat.srgb24:
            return 3;

        case PixelFormat.ds24_8:
        case PixelFormat.rgb32:
        case PixelFormat.srgb32:
        case PixelFormat.rgba32:
        case PixelFormat.srgba32:
            return 4;

        case PixelFormat.rgba128f:
            return 16;
    }
}

/**
    An image.
*/
class Image : NuRefCounted {
private:
@nogc:
    PixelFormat format_;
    void[] data_;
    uint width_;
    uint height_;
    uint pxStride_;

public:

    /**
        Format of the image.
    */
    @property uint width() { return width_; }

    /**
        Format of the image.
    */
    @property uint height() { return height_; }

    /**
        Row stride of the image.
    */
    @property uint stride() { return width_*pxStride_; }

    /**
        Bits-per-pixel
    */
    @property uint bpc() { return pxStride_*8; }

    /**
        Format of the image.
    */
    @property PixelFormat format() { return format_; }

    /**
        Raw data of the image.
    */
    @property void[] rawData() { return data_; }

    /**
        Destructor
    */
    ~this() {
        this.data_ = data_.nu_resize(0);
        this.width_ = 0;
        this.height_ = 0;
    }

    /**
        Creates a new empty image.
    */
    this(PixelFormat format, uint width, uint height) {
        this.format_ = format;
        this.width_ = width;
        this.height_ = height;
        this.pxStride_ = format.toStride();

        // Create and zero-init data.
        this.data_ = data_.nu_resize(width*height*pxStride_);
        nogc_zeroinit(cast(ubyte[])data_[0..$]);
    }
}
