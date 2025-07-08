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
private:

    // CSS
    vec4 bgcolor_;
    vec4 color_;

protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onDraw(DrawContext ctx, float delta) {
        this.pushStyleColor(ImGuiCol.ButtonActive, bgcolor_);
        this.pushStyleColor(ImGuiCol.ButtonHovered, bgcolor_);
        this.pushStyleColor(ImGuiCol.Button, bgcolor_);
        this.pushStyleColor(ImGuiCol.Text, color_);

        if (igButton(imName.ptr, sizeRequest.toImGui!ImVec2)) {
            if (onSubmit)
                this.onSubmit(this);
        }
    }

    override
    void onRefresh() {
        super.onRefresh();

        bgcolor_ = computedStyle.backgroundColor;
        color_ = computedStyle.color;
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
    this(string text) {
        super("button");
        this.name = text;
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