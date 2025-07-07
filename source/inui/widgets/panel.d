/**
    Panel Widget

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.panel;
import inui.widgets.widget;
import inui.window;
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
        Adds a panel to the workspace.
    */
    Workspace add(Panel panel) {
        this.panels ~= panel;
        return this;
    }

    /**
        Constructor
    */
    this() {
        super("Workspace", false);
    }
}

/**
    A panel
*/
class Panel : Container {
protected:
    bool _open = true;

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        igBegin(imName.ptr, &_open, ImGuiWindowFlags.None);
        super.onUpdate(delta);
        igEnd();
    }

public:

    /**
        Whether the panel is shown.
    */
    @property bool shown() => _open;
    @property void shown(bool value) { this._open = value; }

    /**
        Constructor
    */
    this(string name) {
        super(name, false);
    }
}