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
    A docking node.
*/
class DockNode : Widget {
private:

public:

    /**
        Constructor
    */
    this() {
        super("docknode", "DockNode", false);
    }
}
