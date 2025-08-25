module gl.texture;
import gl.context;
import inmath;
import numem;

public import inrndr.texture;

class GLTexture : Texture {
public:
@nogc:

    override @property uint width() const => 0;

    override @property uint height() const => 0;

    override @property PixelFormat format() const => PixelFormat.init;

    override @property bool isSurface() const => false;

    override @property TextureFilter minFilter() => TextureFilter.init;
    override @property void minFilter(TextureFilter) { }

    override @property TextureFilter magFilter() => TextureFilter.init;
    override @property void magFilter(TextureFilter) { }

    override @property TextureWrap wrapMode() => TextureWrap.init;
    override @property void wrapMode(TextureWrap) { }

    override
    void updateRegion(void[] data, uint width, uint height, PixelFormat format, vec2i position = vec2i(0, 0)) {

    }

    override
    void updateRegion(void[] data, uint width, uint height, PixelFormat format, recti area, vec2i position = vec2i(0, 0)) {

    }
}

/**
    A swap chain.
*/
class GLSwapChain : SwapChain {
@nogc:

    /**
        Gets the next texture in the swapchain.
    */
    override Texture next() => null;
}
