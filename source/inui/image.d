module inui.image;
import inui.core.render.texture;
import numem;

/**
    An image.
*/
class Image : NuRefCounted {
private:
@nogc:
    TextureFormat format_;
    void[] data_;
    uint width_;
    uint height_;
    uint stride_;

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
    @property uint stride() { return stride_; }

    /**
        Format of the image.
    */
    @property TextureFormat format() { return format_; }

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
    this(TextureFormat format, uint width, uint height) {
        this.format_ = format;
        this.width_ = width;
        this.height_ = height;
        this.stride_ = format.toStride();

        // Create and zero-init data.
        this.data_ = data_.nu_resize(width*height*stride_);
        nogc_zeroinit(cast(ubyte[])data_[0..$]);
    }
}
