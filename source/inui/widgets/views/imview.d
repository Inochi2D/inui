/**
    A view backed by ImGui

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.views.imview;
import inui.widgets.views.view;
import inui.widgets.widget;
import inui.window;

import inmath.linalg;
import i2d.imgui;

/**
    An ImGui View
*/
class ImGuiView : View {
private:
    bool isOpen_;
    ImGuiWindowFlags flags;

protected:

    /**
        Called when a view is docked to another view.
    */
    override
    void onDocked(View to) { }

    override
    void onUpdate(float delta) {
        igBegin(imName.ptr, &isOpen_, flags);
            this.isHovered = igIsWindowHovered();
            this.isFocused = igIsWindowFocused();

            Widget.onUpdate(delta);
            
            if (&this.onImDraw)
                this.onImDraw(igGetCurrentContext());
        igEnd();
    }

public:

    /**
        Function called when the imgui view is being drawn.
    */
    void delegate(ImGuiContext* ctx) onImDraw;

    /**
        Whether the view is "open" and being rendered.
    */
    override @property bool isOpen() => isOpen_;

    /**
        Constructor
    */
    this(string kind, string name, ImGuiWindowFlags flags = ImGuiWindowFlags.None) {
        super(kind, name);
        this.flags = flags;
    }
}