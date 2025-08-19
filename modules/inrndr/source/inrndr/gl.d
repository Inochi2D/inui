/**
    Inui OpenGL Context

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inrndr.gl;
import inrndr.texture;
import nulib;

public import bindbc.opengl;

/**
    A wrapper over an OpenGL Context that may be shared with a
    RenderContext.
*/
abstract
class GLContext : NuRefCounted {
private:
@nogc:
    static GLContext __current_glctx;

public:

    /**
        Major version of the OpenGL Context
    */
    abstract @property uint major();

    /**
        Minor version of the OpenGL Context
    */
    abstract @property uint minor();

    /**
        List of extensions supported by the OpenGL Context
    */
    abstract @property string[] extensions();

    /**
        The framebuffer of the given context.
    */
    abstract @property Texture framebuffer();

    /**
        The current active OpenGL Context for this thread.
    */
    final @property GLContext current() => __current_glctx;

    /**
        Makes this GLContext current.
    */
    void makeCurrent() {
        __current_glctx = this;
    }
}