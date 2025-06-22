/**
    ImGui Widget Container

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.imgui;
import inui.widgets.widget;
import inui.window;

/**
    An imgui workspace
*/
class ImWorkspace : Container {
private:
    Window window;

public:
    this(Window window) {
        this.window = window;
        super("Workspace", false);
    }
}