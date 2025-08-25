/**
    Inui Render Context

    Copyright © 2020-2025, Inochi2D Project
    Copyright © 2020-2025, Kitsunebi Games
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inrndr.context;
import inrndr.texture;
import inrndr.buffer;
import inrndr.shader;
import inmath;
import numem;
import sdl;
import inrndr.pass;

/**
    The main renderer object used for a inui window.

    This may be backed by OpenGl, Vulkan or any other technology.
    Any OpenGL Context created for views will be seperate
    from this renderer context.
*/
abstract
class RenderContext : NuRefCounted {
public:
@nogc:

    /**
        The active swap chain for the rendering context.
    */
    abstract @property SwapChain swapchain();

    /**
        Creates a new rendering context for the given native window.

        This context will only be usable with the Window.
    */
    static RenderContext createContext(SDL_Window* window) {
        return __inui_create_render_context_for(window);
    }

    /**
        Creates an embedded GL context which can be rendered by the render context.

        Params:
            width = Width of the context's framebuffer.
            height = Height of the context's framebuffer.
        
        Returns:
            A new sub context if possible,
            $(D null) otherwise.
    */
    abstract SubRenderContext createGLSubContext(uint width, uint height);

    /**
        Creates a new texture for the context.

        The creation attributes of a texture are immutable, but the
        data allocated for the texture is not.

        Params:
            width = The width of the texture
            height = The height of the texture
            format = The pixel format of the texture.
    
        Returns:
            A newly allocated texture with the given dimensions and
            pixel format.
    */
    abstract Texture createTexture(uint width, uint height, PixelFormat format);

    /**
        Creates a new buffer.

        The creation attributes of a buffer are immutable,
        the data allocated for the buffer is not.

        Params:
            sizeInBytes = How many bytes to allocate for the buffer.

        Returns:
            A newly allocated buffer with the given size.
    */
    abstract Buffer createBuffer(uint sizeInBytes);

    /**
        Creates a new shader with the given source code.

        Params:
            source = The source code of the shader.

        Returns:
            A newly allocated shader object.
    */
    abstract Shader createShader(string source);

    /**
        Begins a rendering pass.

        Params:
            desc = The render pass descriptor.

        Returns:
            A command buffer which gets consumed for the pass.
    */
    abstract CommandBuffer beginPass(RenderPassDescriptor desc);

    /**
        Ends the current active rendering pass, swapping the
        swapchain backbuffer if neccesary.
    */
    abstract void submit(ref CommandBuffer buffer);

    /**
        Makes the context current.
    */
    void makeCurrent() { }

    /**
        Called by the user at the start of a frame.
    */
    void beginFrame() { }

    /**
        Called by the user at the end of a frame.
    */
    void endFrame() { }
}

/**
    A sub-context.
*/
abstract
class SubRenderContext : NuRefCounted {
private:
@nogc:
    RenderContext parent;

protected:

    /**
        Creates a new sub render context.
    */
    this(RenderContext parent) {
        this.parent = parent;
    }

public:

    /**
        Gets the framebuffer texture in the format used internally
        by the sub-render context.
    */
    abstract @property void* viewFramebuffer();

    /**
        Gets the framebuffer texture in the format used by
        the host for rendering the sub context to the screen.
    */
    abstract @property Texture hostFramebuffer();

    /**
        Width of the framebuffer of the context.
    */
    abstract @property uint fbWidth();

    /**
        Height of the framebuffer of the context.
    */
    abstract @property uint fbHeight();

    /**
        Resizes the render context.
    */
    abstract void resize(uint width, uint height);

    /**
        Called by the user at the start of a frame.
    */
    abstract void beginFrame();

    /**
        Called by the user at the end of a frame.
    */
    abstract void endFrame();
}

//
//      BACKEND IMPLEMENTATION DETAILS.
//
private:
extern(C)

extern RenderContext __inui_create_render_context_for(SDL_Window* window) @nogc;