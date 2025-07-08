/**
    Buttons

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.button;
import inui.widgets.control;
import inui.core.utils;
import inmath.linalg;
import i2d.imgui;

/**
    A button
*/
class Button : Control {
protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onDraw(DrawContext ctx, StyleRule computed, float delta) {
        int pstyles = 0;

        ImGuiCol btnStyleState = isActive ? ImGuiCol.ButtonActive : isHovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button;
        vec4 bgcolor = computed.backgroundColor;
        vec4 color = computed.color;

        if (bgcolor.isFinite) {
            igPushStyleColor(btnStyleState, bgcolor.toImGui!ImVec4);
            pstyles++;
        }

        if (color.isFinite) {
            igPushStyleColor(ImGuiCol.Text, color.toImGui!ImVec4);
            pstyles++;
        }

        if (igButton(imName.ptr, sizeRequest.toImGui!ImVec2)) {
            if (onSubmit)
                this.onSubmit(this);
        }

        if (pstyles > 0) igPopStyleColor(pstyles);
    }

public:

    /**
        The text of the button
    */
    @property string text() => this.name;
    @property void text(string text) { this.name = text; }

    /**
        Constructs a new button.

        Params:
            text        = The text that should be on the button
            size        = The size of the button.
    */
    this(string text, vec2 size = vec2(0, 0)) {
        super("button");
        this.name = text;
        this.sizeRequest = size;
    }

    /**
        Called when the button is clicked.
    */
    void delegate(Button self) onSubmit;

    /**
        Sets the submit callback for the button.
    */
    Button setOnSubmit(void delegate(Button self) submit) {
        this.onSubmit = submit;
        return this;
    }
}