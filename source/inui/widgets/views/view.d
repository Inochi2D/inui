/**
    View Widgets

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.views.view;
import inui.widgets.widget;
import inui.window;

import inmath.linalg;
import i2d.imgui;

/**
    A view
*/
abstract
class View : Widget {
protected:

    /**
        Called when a view is docked to another view.
    */
    abstract void onDocked(View to);

public:

    /**
        Whether the view is in focus.
    */
    abstract @property bool isFocused();

    /**
        Whether the view is "open" and being rendered.
    */
    abstract @property bool isOpen();

    /**
        Constructor
    */
    this(string kind, string name) {
        super(kind, name, false);
    }
}

/**
    A view widget which covers the root view functionality of a window.

    Depending on the views inserted into the view its semantics changes.
*/
class RootView : View {
private:
    bool focused_;

    bool onPsuedo(string name, string arg) {
        switch(name) {
            case "hover":
                return this.isHovered;

            case "open":
                return true;

            case "focused":
                return focused_;
            
            default:
                return false;
        }
    }

protected:

    /**
        Called when a view is docked to another view.
    */
    override
    void onDocked(View to) {
        assert(0, "Cannot dock a root-view to other views!");
    }

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        ImGuiID did = igDockSpaceOverViewport(0, null, ImGuiDockNodeFlagsI.NoCloseButton | ImGuiDockNodeFlagsI.NoTabBar | ImGuiDockNodeFlagsI.NoDockingOverMe | ImGuiDockNodeFlagsI.NoDockingOverOther);

        if (children.length > 0) {
            igSetNextWindowBgAlpha(0);
            igSetNextWindowDockID(did);
            igBegin(imName.ptr, null, ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoSavedSettings);
                this.isHovered = igIsWindowHovered();
                focused_ = igIsWindowFocused();
                Widget.onUpdate(delta);
            igEnd();
        }
    }

    override
    void onRefresh() {
        super.onRefresh();
    }

public:

    /**
        Whether the view is in focus.
    */
    override @property bool isFocused() => focused_;

    /**
        Whether the view is "open" and being rendered.
    */
    override @property bool isOpen() => true;

    /**
        Constructor
    */
    this() {
        super("root", "RootView");
    }
}
