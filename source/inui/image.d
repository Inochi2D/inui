module inui.image;
import numem;

public import inrndr.texture : PixelFormat, toStride;

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
