/**
    Inui OpenGL Interface

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.gl;
import inui.core.window;
import inmath;
import nulib;
import numem;
import sdl;

import bindbc.opengl;
import numem.core.exception;
public import bindbc.opengl : GLSupport;

public import inui.core.render.shader;
public import inui.core.render.buffer;
public import inui.core.render.texture;

/**
    Primitive shapes
*/
enum Primitive : GLenum {
    triangles = GL_TRIANGLES,
    lines = GL_LINES,
    points = GL_POINTS,
    triangleStrip = GL_TRIANGLE_STRIP
}

/**
    An OpenGL Context
*/
final
class GLContext : NuObject {
private:
@nogc:
    // Enum used to automatically try different OpenGL Versions.
    enum VERSIONS_TO_TRY = [[4, 6], [4, 5], [3, 2]];

    __gshared weak_vector!GLContext __glContexts;
    weak_vector!GLObject __glObjects;

    NativeWindow window;
    SDL_GLContext ctx;
    GLuint vao;
    bool hasComplexBlending;
    bool hasComplexBlendingCoherent;

    // Helper that attempts to create an OpenGL Context
    SDL_GLContext tryCreateContextVersion(int major, int minor) {
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLProfile.SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_CONTEXT_MAJOR_VERSION, major);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_CONTEXT_MINOR_VERSION, minor);
        return SDL_GL_CreateContext(window.windowHandle);
    }

    // Helper that sets up and creates a GL context.
    SDL_GLContext createGLContext() {
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_DEPTH_SIZE, 24);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_STENCIL_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_RED_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_GREEN_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_BLUE_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_ALPHA_SIZE, 8);

        // Attempt every version from highest to lowest.
        static foreach(glv; VERSIONS_TO_TRY) {
            if (auto handle = this.tryCreateContextVersion(glv[0], glv[1])) {
                SDL_GL_MakeCurrent(window.windowHandle, handle);
                if (loadOpenGL() > GLSupport.noContext) {
                    this.queryFeatures();
                    return handle;
                }
                
                import std.stdio : printf;
                printf("Couldn't create %d.%d, trying again...\n", glv[0], glv[1]);

                // Try again.
                SDL_GL_DestroyContext(handle);
            }
        }

        throw nogc_new!NuException("Could not create OpenGL 3.2 or newer context!");
    }

    void enforceRequiredFeatures() {
        uint major = this.majorVersion;
        uint minor = this.minorVersion;
        bool hasDSA = 
            (major >= 4 && minor >= 5) ||
            extensionSupported("EXT_direct_state_access") ||
            extensionSupported("ARB_direct_state_access");

        enforce(hasDSA, "Missing required OpenGL Feature 'direct_state_access'!");
    }

    void queryFeatures() {
        this.enforceRequiredFeatures();
        this.hasComplexBlending = extensionSupported("KHR_blend_equation_advanced");
        this.hasComplexBlendingCoherent = extensionSupported("GL_KHR_blend_equation_advanced_coherent");
    }

    // Sets up the GL context
    void setup() {
        this.ctx = this.createGLContext();
        glGenVertexArrays(1, &vao);
    }

    // Shuts the GL context down
    void shutdown() {
        if (ctx) {
            // Make current before we try to destroy anything.
            SDL_GL_MakeCurrent(window.windowHandle, ctx);

            // Kill all objects belonging to this context.
            foreach(ref GLObject object; __glObjects[]) 
                nogc_delete(object);
            __glObjects.clear();
            glDeleteVertexArrays(1, &vao);

            // Destroy our active context
            SDL_GL_DestroyContext(ctx);
        }
    }

public:

    /**
        Major GL version of the context.
    */
    @property uint majorVersion() {
        GLint major;
        glGetIntegerv(GL_MAJOR_VERSION, &major);
        return major;
    }

    /**
        Minor GL version of the context.
    */
    @property uint minorVersion() {
        GLint major;
        glGetIntegerv(GL_MINOR_VERSION, &major);
        return major;
    }

    /**
        Whether Vertical Sync is enabled.
    */
    @property bool vsync() {
        this.makeCurrent();
        int swapInterval;
        return SDL_GL_GetSwapInterval(&swapInterval) && swapInterval != 0;
    }
    @property void vsync(bool value) {
        this.makeCurrent();
        if (value && !SDL_GL_SetSwapInterval(-1)) {
            cast(void)SDL_GL_SetSwapInterval(1);
            return;
        }
        cast(void)SDL_GL_SetSwapInterval(0);
    }
    
    /**
        Whether the context has Advanced Binding support
    */
    @property bool doesHaveAdvancedBlending() { return hasComplexBlending; }
    
    /**
        Whether the context has coherent Advanced Binding support
    */
    @property bool doesHaveAdvancedBlendingCoherent() { return hasComplexBlendingCoherent; }

    /**
        The current viewport
    */
    @property void viewport(recti value) { glViewport(value.x, value.y, value.width, value.height); }
    @property recti viewport() {
        this.makeCurrent();

        recti r;
        glGetIntegerv(GL_VIEWPORT, cast(int*)r.ptr);
        return r;
    }

    /**
        Destructor
    */
    ~this() {
        this.shutdown();

        // Clean up context.
        __glContexts.remove(this);
    }

    /**
        Constructor
    */
    this(NativeWindow window) {
        this.window = window;
        this.setup();

        __glContexts ~= this;
    }

    /**
        Gets whether the given extension is supported.

        Params:
            extension = The OpenGL extension to query.
        
        Returns:
            $(D true) if this context supports the requested extension.
            $(D false) otherwise.
    */
    bool extensionSupported(string extension) {
        nstring tmp = extension;
        return SDL_GL_ExtensionSupported(tmp.ptr);
    }

    /**
        Makes the context current.
        
        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool makeCurrent() {
        return SDL_GL_MakeCurrent(window.windowHandle, ctx);
    }

    /**
        Binds the GL Context's VAO
    */
    void bindVAO() {
        glBindVertexArray(vao);
    }

    /**
        Sets the active blending mode.

        Params:
            src = Source blending flag
            dst = Destination blending flag
    */
    void blendFunc(GLenum src, GLenum dst) {
        this.makeCurrent();
        glBlendFunc(src, dst);
    }

    /**
        Sets the current scissor rectangle
    */
    void scissor(recti area) {
        this.makeCurrent();
        recti vp = viewport;
        glScissor(area.x, vp.height-area.height, area.width - area.x, area.height - area.y);
    }

    /**
        Enables the given feature.

        Params:
            feature = The feature to enable.
    */
    void enable(GLenum feature) {
        this.makeCurrent();
        glEnable(feature);
    }

    /**
        Disables the given feature.

        Params:
            feature = The feature to disable.
    */
    void disable(GLenum feature) {
        this.makeCurrent();
        glDisable(feature);
    }

    /**
        Sets the specified uniform to the given value.

        Params:
            location = The location of the uniform to set
            value = The value to set the uniform to.
    */
    void setUniform(GLint location, float value) { glUniform1f(location, value); }
    void setUniform(GLint location, int value) { glUniform1i(location, value); }
    void setUniform(GLint location, vec2 value) { glUniform2f(location, value.x, value.y); }
    void setUniform(GLint location, vec3 value) { glUniform3f(location, value.x, value.y, value.z); }
    void setUniform(GLint location, vec4 value) { glUniform4f(location, value.x, value.y, value.z, value.w); }
    void setUniform(GLint location, mat4 value) { glUniformMatrix4fv(location, value.matrix.length, GL_TRUE, value.ptr); }
}

/**
    Object which is used from a GL context.
*/
abstract
class GLObject : NuRefCounted {
private:
@nogc:
    GLContext parent;
    GLuint objId;

protected:
    
    /**
        Makes the context that this object originates from current.
    */
    final
    void makeCurrent() {
        parent.makeCurrent();
    }

public:
    
    /**
        The owning context of the object.
    */
    final
    @property GLContext context() { return parent; }
    
    /**
        The ID of the object.
    */
    final
    @property GLuint id() { return objId; }

    /**
        Destructor
    */
    ~this() {
        parent.__glObjects.remove(this);
    }

    /**
        Constructs a new GL Object.

        Params:
            parent = The parent context that created this object.
            objId = Object ID
    */
    this(GLContext parent, GLuint objId) {
        assert(parent, "Can't create object for no parent!");
        this.parent = parent;
        this.objId = objId;
        parent.__glObjects ~= this;
    }
}

