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
        Called when OpenGL is in control of drawing.
    */
    abstract void onGLDraw(float delta);

    override
    void onDraw(DrawContext ctx, float delta) {
        if (!gl)
            return;

        gl.beginFrame();
            this.onGLDraw(delta);
        gl.endFrame();
        igImage(ImTextureRef(null, cast(ImTextureID)cast(void*)gl.hostFramebuffer), cssbox.requestedSize.toImGui!ImVec2);
    }

    override
    void onSizeChanged(vec2 oldSize, vec2 newSize) {
        if (newSize.x == 0 || newSize.y == 0)
            return;

        if (!gl) {
            this.gl = window.renderer.createSubContext(cast(uint)newSize.x, cast(uint)newSize.y, "opengl");
            return;
        }

        this.gl.resize(cast(uint)newSize.x, cast(uint)newSize.y);
    }

public:

    this() {
        super("glview");
    }
}