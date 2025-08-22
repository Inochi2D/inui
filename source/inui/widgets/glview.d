/**
    OpenGL Interop

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.glview;
import inui.widgets.control;
import inui.core.utils;
import inmath.linalg;
import inmath : max;
import i2d.imgui;
import inrndr;

public import bindbc.opengl;

/**
    An OpenGL View that can be drawn to by an OpenGL 4 context.
*/
class GLView : Control {
private:
    SubRenderContext gl;

protected:

    /**
        Gets the main view framebuffer.
    */
    @property GLuint mainFBO() => cast(GLuint)gl.viewFramebuffer();

    /**
        Called when OpenGL is in control of drawing.
    */
    abstract void onDrawGL(float delta);

    /**
        Called when OpenGL is first initialized.
    */
    abstract void onGLInit();

    override
    void onDraw(DrawContext ctx, float delta) {
        if (!gl)
            return;

        gl.beginFrame();
            this.onDrawGL(delta);
        gl.endFrame();
        igImage(
            ImTextureRef(null, cast(ImTextureID)cast(void*)gl.hostFramebuffer), 
            cssbox.requestedSize.toImGui!ImVec2,
            ImVec2(1, 1),
            ImVec2(0, 0)
        );
    }

    override
    void onSizeChanged(vec2 oldSize, vec2 newSize) {
        if (newSize.x <= 1 || newSize.y <= 1) {
            if (gl) {
                this.gl.release();
                this.gl = null;
            }
            return;
        }

        if (!gl) {
            this.gl = window.renderer.createGLSubContext(cast(uint)newSize.x, cast(uint)newSize.y);
            this.gl.beginFrame();
                this.onGLInit();
            this.gl.endFrame();
            return;
        }

        this.gl.resize(cast(uint)newSize.x, cast(uint)newSize.y);
    }

public:

    ~this() {
        if (gl) {
            this.gl.release();
            this.gl = null;
        }
    }

    this() {
        super("glview");
    }
}