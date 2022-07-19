/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.toolwindow;
import bindbc.imgui;
import std.string;
import std.conv;
import i18n;
import inmath;

private {
    ImGuiWindowClass* windowClass;
    uint spawnCount = 0;
}

/**
    A Widget
*/
abstract class ToolWindow {
private:
    string name_;
    bool visible = true;
    bool disabled;
    int spawnedId;
    const(char)* imName;

protected:
    bool onlyOne;
    bool drewWindow;
    ImGuiWindowFlags flags;

    bool allowResize = true;
    float minWidth = 500;
    float minHeight = 400;

    abstract void onUpdate();

    void onBeginUpdate() {
        if (imName is null) this.setTitle(name);
        igSetNextWindowClass(windowClass);
        igSetNextWindowSizeConstraints(
            ImVec2(minWidth, minHeight), 
            allowResize ? ImVec2(float.max, float.max) : ImVec2(minWidth, minHeight)
        );
        drewWindow = igBegin(
            imName,
            &visible, 
            flags
        );
    }
    
    void onEndUpdate() {
        igEnd();
    }

    void onClose() { }

public:


    /**
        Constructs a frame
    */
    this(string name) {
        this.name_ = name;
        this.restore();
    }

    final void close() {
        this.visible = false;
    }

    final string name() {
        return name_;
    }

    final void setTitle(string title) {
        this.name_ = title;
        imName = "%s###%s".format(name_, spawnedId).toStringz;
    }

    /**
        Draws the frame
    */
    final void update() {
        igPushItemFlag(ImGuiItemFlags.Disabled, disabled);
            this.onBeginUpdate();
                this.onUpdate();
            this.onEndUpdate();
        igPopItemFlag();

        if (disabled && !visible) visible = true;
    }

    ImVec2 getPosition() {
        ImVec2 pos;
        igGetWindowPos(&pos);
        return pos;
    }

    void disable() {
        this.flags = ImGuiWindowFlags.NoDocking | 
            ImGuiWindowFlags.NoCollapse | 
            ImGuiWindowFlags.NoNav | 
            ImGuiWindowFlags.NoMove |
            ImGuiWindowFlags.NoScrollWithMouse |
            ImGuiWindowFlags.NoScrollbar;
        disabled = true;
    }

    void restore() {
        disabled = false;
        this.flags = ImGuiWindowFlags.NoDocking | ImGuiWindowFlags.NoCollapse | ImGuiWindowFlags.NoSavedSettings;

        windowClass = ImGuiWindowClass_ImGuiWindowClass();
        windowClass.ViewportFlagsOverrideClear = ImGuiViewportFlags.NoDecoration | ImGuiViewportFlags.NoTaskBarIcon;
        windowClass.ViewportFlagsOverrideSet = ImGuiViewportFlags.NoAutoMerge;
    }
}

private {
    ToolWindow[] windowStack;
    ToolWindow[] windowList;
}

/**
    Pushes window to stack
*/
void inPushToolWindow(ToolWindow window) {
    window.spawnedId = spawnCount++;
    
    // Only allow one instance of the window
    if (window.onlyOne) {
        foreach(win; windowStack) {
            if (win.name == window.name) return;
        }
    }

    if (windowStack.length > 0) {
        windowStack[$-1].disable();
    }

    windowStack ~= window;
}

/**
    Pushes window to stack
*/
void inPushToolWindowList(ToolWindow window) {
    window.spawnedId = spawnCount++;

    // Only allow one instance of the window
    if (window.onlyOne) {
        foreach(win; windowList) {
            if (win.name == window.name) return;
        }
    }

    windowList ~= window;
}

/**
    Pop window from Window List
*/
void inPopToolWindowList(ToolWindow window) {
    import std.algorithm.searching : countUntil;
    import std.algorithm.mutation : remove;

    ptrdiff_t i = windowList.countUntil(window);
    if (i != -1) {
        if (windowList.length == 1) windowList.length = 0;
        else windowList = windowList.remove(i);
    }
}

/**
    Pop window from Window List
*/
void inPopToolWindowListAll() {
    foreach(window; windowList) {
        window.onClose();
        window.visible = false;
    }
    windowList.length = 0;
}

/**
    Pops a window
*/
void inPopToolWindow() {
    windowStack[$-1].onClose();
    windowStack.length--;
    if (windowStack.length > 0) windowStack[$-1].restore();
}

/**
    Update windows
*/
void inUpdateToolWindows() {
    int id = 0;
    foreach(window; windowStack) {
        window.update();
        if (!window.visible) inPopToolWindow();
    }
    
    ToolWindow[] closedWindows;
    foreach(window; windowList) {
        window.update();
        if (!window.visible) closedWindows ~= window;
    }

    foreach(window; closedWindows) {
        inPopToolWindowList(window);
    }
}

/**
    Gets top window
*/
ToolWindow inGetTopToolWindow() {
    return windowStack.length > 0 ? windowStack[$-1] : null;
}