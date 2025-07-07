/**
    ImGui Widget Container

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.imgui;
import inui.widgets.widget;
import inui.window;
import i2d.imgui;

/**
    A workspace, contains a main docking node that windows can
    dock into.
*/
class ImWorkspace : Container {
protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        igDockSpaceOverViewport(0, null, ImGuiDockNodeFlags.PassthruCentralNode | ImGuiDockNodeFlagsI.NoWindowMenuButton);
        super.onUpdate(delta);
    }

public:

    /**
        Constructor
    */
    this() {
        super("Workspace", false);
    }
}