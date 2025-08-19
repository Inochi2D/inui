/**
    Panel Widget

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.panel;
import inui.widgets.widget;
import inui.window;

import inmath.linalg;
import i2d.imgui;

/**
    A workspace, contains a main docking node that panels can
    dock into.
*/
class Workspace : Widget {
private:
    Panel[] panels;

protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        igDockSpaceOverViewport(0, null, ImGuiDockNodeFlags.PassthruCentralNode | ImGuiDockNodeFlagsI.NoWindowMenuButton);
        foreach(child; panels) {
            child.update(delta);
        }
    }

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override
    void onRefresh() {
        foreach(child; panels) {
            child.refresh();
        }
    }

public:

    /**
        Adds a new panel to the workspace.
    */
    override
    Widget add(Widget widget) {
        if (Panel panel = cast(Panel)widget) {
            if (panel.parent)
                return this;
            
            this.panels ~= panel;
            panel.reparentTo(this);

            panel.styleElement.parent = this.styleElement;
            return this;
        }
        return super.add(widget);
    }

    /**
        Constructor
    */
    this() {
        super("workspace", "Workspace", false);
    }
}

/**
    A panel
*/
class Panel : Container {
private:
    bool open_ = true;
    bool hovered_;
    bool focused_;

    // CSS
    vec4 bgcolor_;
    vec4 color_;

    bool onPsuedo(string name, string arg) {
        switch(name) {
            case "hover":
                return hovered_;

            case "open":
                return open_;

            case "focused":
                return focused_;
            
            default:
                return false;
        }
    }

protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        this.pushStyleColor(ImGuiCol.WindowBg, bgcolor_);
        this.pushStyleColor(ImGuiCol.Text, color_);

        igBegin(imName.ptr, &open_, ImGuiWindowFlags.None);
            hovered_ = igIsWindowHovered();
            focused_ = igIsWindowFocused();
            super.onUpdate(delta);
        igEnd();
    }

    override
    void onRefresh() {
        super.onRefresh();
        bgcolor_ = computedStyle.backgroundColor;
        color_ = computedStyle.color;
    }

public:

    /**
        Whether the panel is shown.
    */
    @property bool shown() => open_;
    @property void shown(bool value) { this.open_ = value; }

    /**
        Constructor
    */
    this(string name) {
        super("panel", name, false);
    }
}