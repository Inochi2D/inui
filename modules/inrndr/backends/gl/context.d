module gl.context;
import gl.texture;
import gl.buffer;
import gl.shader;
import gl.pass;
import inmath;
import numem;
import sdl;

public import inrndr.context;
public import bindbc.opengl;

class GLRenderContext : RenderContext {
private:
@nogc:
    SDL_Window* window;

public:

    this(SDL_Window* window) {
        this.window = window;
    }

    override @property SwapChain swapchain() => null;

    override
    SubRenderContext createGLSubContext(uint width, uint height) {
        return null;
    }

    override Texture createTexture(uint width, uint height, PixelFormat format) {
        return null;
    }

    override Buffer createBuffer(uint sizeInBytes) {
        return null;
    }

    override Shader createShader(string source) {
        return null;
    }

    override CommandBuffer beginPass(RenderPassDescriptor desc) {
        return null;
    }

    override void submit(ref CommandBuffer buffer) {
        
    }

    override
    void makeCurrent() { }

    override
    void beginFrame() { }

    override
    void endFrame() { }
}

class GLSubRenderContext : SubRenderContext {
private:
@nogc:


public:

    this(RenderContext ctx) {
        super(ctx);
    }

    override @property void* viewFramebuffer() => null;

    override @property Texture hostFramebuffer() => null;

    override @property uint fbWidth() => 0;

    override @property uint fbHeight() => 0;

    override
    void resize(uint width, uint height) {

    }

    override
    void beginFrame() {

    }

    override
    void endFrame() {

    }
}


private:
extern(C)
export RenderContext __inui_create_render_context_for(SDL_Window* window) @nogc {
    return nogc_new!GLRenderContext(window);
}