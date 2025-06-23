/**
    Inui Texture Interface

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.texture;
import inui.core.render.gl;
import inui.image;
import bindbc.opengl;
import nulib.math;
import inmath : recti;

/**
    Texture filter method.
*/
enum TextureFilter : int {
    nearest = GL_NEAREST,
    linear = GL_LINEAR,
    nearestMipmap = GL_NEAREST_MIPMAP_LINEAR,
    linearMipmap = GL_LINEAR_MIPMAP_LINEAR,
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
    Converts a PixelFormat to its symbolic OpenGL equivalent.
*/
pragma(inline, true)
GLenum toSymbolicFormat(PixelFormat fmt) @nogc nothrow {
    final switch(fmt) {
        case PixelFormat.ds24_8:
            return GL_DEPTH_COMPONENT;

        case PixelFormat.r8:
            return GL_RED;

        case PixelFormat.rgb24:
        case PixelFormat.srgb24:
            return GL_RGB;
        
        case PixelFormat.rgb32:
        case PixelFormat.srgb32:
        case PixelFormat.rgba32:
        case PixelFormat.srgba32:
        case PixelFormat.rgba128f:
            return GL_RGBA;
    }
}

/**
    Converts a PixelFormat to its symbolic OpenGL equivalent.
*/
pragma(inline, true)
GLenum toSpecificFormat(PixelFormat fmt) @nogc nothrow {
    final switch(fmt) {
        case PixelFormat.ds24_8:
            return GL_DEPTH24_STENCIL8;

        case PixelFormat.r8:
            return GL_R8;

        case PixelFormat.rgb24:
        case PixelFormat.srgb24:
            return GL_RGB8;
        
        case PixelFormat.rgb32:
        case PixelFormat.rgba32:
            return GL_RGBA8;

        case PixelFormat.srgb32:
        case PixelFormat.srgba32:
            return GL_SRGB8_ALPHA8;

        case PixelFormat.rgba128f:
            return GL_RGBA32F;
    }
}

/**
    Converts a PixelFormat to its symbolic OpenGL data size.
*/
pragma(inline, true)
GLenum toSymbolicSize(PixelFormat fmt) @nogc nothrow {
    final switch(fmt) {
        case PixelFormat.ds24_8:
            return GL_FLOAT;

        case PixelFormat.r8:
            return GL_UNSIGNED_BYTE;

        case PixelFormat.rgb24:
        case PixelFormat.srgb24:
            return GL_UNSIGNED_BYTE;

        case PixelFormat.rgb32:
        case PixelFormat.srgb32:
        case PixelFormat.rgba32:
        case PixelFormat.srgba32:
            return GL_UNSIGNED_BYTE;
        
        case PixelFormat.rgba128f:
            return GL_FLOAT;
    }
}

/**
    A texture.

    Textures are immutable after creation; they can not be resized or have their
    format changed, their data however, can be changed.
*/
class Texture : GLObject {
private:
@nogc:
    // Per-thread active texture
    static Texture active;

    // Texture info
    PixelFormat txFormat;
    uint txWidth;
    uint txHeight;
    uint txLevels;

    // Parameter helpers.
    float getParameterf(GLenum pname) {
        float value;
        glGetTextureParameterfv(id, pname, &value);
        return value;
    }
    void setParameterf(GLenum pname, float value) {
        glTextureParameterf(id, pname, value);
    }

    void setParameteri(GLenum pname, int value) {
        glTextureParameteri(id, pname, value);
    }
    int getParameteri(GLenum pname) {
        int value;
        glGetTextureParameteriv(id, pname, &value);
        return value;
    }

    GLuint create(PixelFormat format, uint width, uint height, uint levels) {
        this.txFormat = format;
        this.txWidth = max(1, width);
        this.txHeight = max(1, height);
        this.txLevels = max(1, levels);

        GLuint _id;
        glGenTextures(1, &_id);
        glBindTexture(GL_TEXTURE_2D, _id);
        glTextureStorage2D(_id, txLevels, format.toSpecificFormat(), txWidth, txHeight);
        return _id;
    }

public:

    /**
        Destructor
    */
    ~this() {
        GLuint _id = id;
        glDeleteTextures(1, &_id);
    }

    /**
        Constructor
    */
    this(GLContext context, PixelFormat format, uint width, uint height, uint levels) {
        context.makeCurrent();
        super(context, this.create(format, width, height, levels));
    }

    /**
        Format of the texture.
    */
    @property PixelFormat format() { return txFormat; }

    /**
        Width of the texture.
    */
    @property uint width() { return txWidth; }

    /**
        Height of the texture.
    */
    @property uint height() { return txHeight; }

    /**
        Mip levels of the texture.
    */
    @property uint levels() { return txLevels; }

    /**
        The lowest defined mipmap level
    */
    @property int baseLevel() { return getParameteri(GL_TEXTURE_BASE_LEVEL); }
    @property void baseLevel(int value) { setParameteri(GL_TEXTURE_BASE_LEVEL, value); }

    /**
        Level of detail bias.
    */
    @property float lodBias() { return getParameterf(GL_TEXTURE_LOD_BIAS); }
    @property void lodBias(float value) { return setParameterf(GL_TEXTURE_LOD_BIAS, value); }

    /**
        Minification filter.
    */
    @property TextureFilter minFilter() { return cast(TextureFilter)getParameteri(GL_TEXTURE_MIN_FILTER); }
    @property void minFilter(TextureFilter value) { return setParameteri(GL_TEXTURE_MIN_FILTER, value); }

    /**
        Magnification filter.
    */
    @property TextureFilter magFilter() { return cast(TextureFilter)getParameteri(GL_TEXTURE_MAG_FILTER); }
    @property void magFilter(TextureFilter value) { return setParameteri(GL_TEXTURE_MAG_FILTER, value); }

    /**
        U coordinate wrapping mode
    */
    @property TextureWrap wrapU() { return cast(TextureWrap)getParameteri(GL_TEXTURE_WRAP_S); }
    @property void wrapU(TextureWrap value) { return setParameteri(GL_TEXTURE_WRAP_S, value); }

    /**
        V coordinate wrapping mode
    */
    @property TextureWrap wrapV() { return cast(TextureWrap)getParameteri(GL_TEXTURE_WRAP_T); }
    @property void wrapV(TextureWrap value) { return setParameteri(GL_TEXTURE_WRAP_T, value); }

    /**
        Uploads data to the texture.

        Params:
            format  = The format of the data being uploaded
            data    = The data to upload to the texture
            width   = The width of the data, or -1 for destination size.
            height  = The height of the data, or -1 for destination size.
            x       = X offset into the destination
            y       = Y offset into the destination
            level   = The mip level to assign.
        
        Note:
            The width and 
    */
    void upload(PixelFormat format, void[] data, int width, int height, int x = 0, int y = 0, int level = 0) {
        assert(format.toStride()*width*height <= data.length);

        // Safely escape in release mode. 
        if (format.toStride()*width*height > data.length)
            return;
        
        glTextureSubImage2D(
            id, 
            min(abs(level), txLevels), 
            x, 
            y, 
            width, 
            height, 
            format.toSymbolicFormat,
            format.toSymbolicSize, 
            data.ptr
        );
    }

    /**
        Uploads data to the texture.

        Params:
            format  = The format of the data being uploaded
            data    = The data to upload to the texture
            width   = The total width of the image to copy.
            src     = The source rectangle to copy.
            x       = X offset into the destination
            y       = Y offset into the destination
            level   = The mip level to assign.
        
        Note:
            The width and 
    */
    void upload(PixelFormat format, void[] data, int width, recti src, int x = 0, int y = 0, int level = 0) {
        assert(format.toStride()*width*height <= data.length);

        uint bitsPerPixel = format.toStride();
        uint rowStride = width*bitsPerPixel;

        // Calculate area to copy.
        recti dst = recti(x, y, width, cast(int)(data.length/width)).clipped(recti(0, 0, txWidth, txHeight));
        src.width = dst.width;
        src.height = dst.height;

        // Ensure no invalid copies.
        if (src.width <= 0 || src.height <= 0)
            return;

        // Calculate start data offset.
        void* rdata = data.ptr+(rowStride*src.y)+(src.x*bitsPerPixel);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, width);
        glTextureSubImage2D(
            id, 
            min(abs(level), txLevels), 
            dst.x, 
            dst.y, 
            src.width, 
            src.height, 
            format.toSymbolicFormat, 
            format.toSymbolicSize, 
            rdata
        );
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    }

    /**
        Uploads an image to the texture

        Params:
            image   = The image to upload.
            x       = X offset into the destination
            y       = Y offset into the destination
            level   = The mip level to assign.
        
        Note:
            The width and 
    */
    void upload(Image image, int x = 0, int y = 0, int level = 0) {
        glTextureSubImage2D(
            id, 
            level, 
            min(abs(x), txWidth), 
            min(abs(y), txHeight), 
            image.width, 
            image.height, 
            image.format.toSymbolicFormat, 
            image.format.toSymbolicSize, 
            image.rawData.ptr
        );
    }

    /**
        Binds this texture to the given index.

        Params:
            index = The index to bind the texture at.
    */
    void bind(uint index) {
        glBindTextureUnit(index, id);
        glBindTexture(GL_TEXTURE_2D, id);
    }
}