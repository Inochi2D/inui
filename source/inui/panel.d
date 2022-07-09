/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.panel;
import inui.core;
import inui.core.settings;
import bindbc.imgui;
import std.string;
import i18n;

/**
    A Widget
*/
abstract class Panel {
private:
    string name_;
    string displayName_;
    bool defaultVisibility;
    const(char)* windowID;
    const(char)* displayNamePtr;

    bool drewContents;
    bool wasVisible;

protected:
    ImVec2 panelSpace;
    abstract void onUpdate();
    ImGuiWindowFlags flags;

    void onBeginUpdate() {

        // Try to begin panel
        flags |= ImGuiWindowFlags.NoCollapse;
        drewContents = igBegin(windowID, &visible, flags);

        // Handle panel visibility settings save for closing tabs
        // and skipping content draw
        if (wasVisible != visible) inSettingsSet(name~".visible", visible);
        if (!drewContents) return;

        // Setup debug state and such.
        igGetContentRegionAvail(&panelSpace);
    }
    
    void onEndUpdate() {
        igEnd();

        wasVisible = visible;
    }

    void onInit() { }

public:

    /**
        Whether the panel is visible
    */
    bool visible;

    /**
        Whether the panel is always visible
    */
    bool alwaysVisible = false;

    /**
        Constructs a panel
    */
    this(string name, string displayName, bool defaultVisibility) {
        this.name_ = name;
        this.displayName_ = displayName;
        this.visible = defaultVisibility;
        this.defaultVisibility = defaultVisibility;
    }

    /**
        Initializes the Panel
    */
    final void init_() {
        onInit();

        // Workaround for the fact that panels are initialized in shared static this
        this.displayName_ = _(this.displayName_);
        if (inSettingsCanGet(this.name_~".visible")) {
            visible = inSettingsGet!bool(this.name_~".visible");
            wasVisible = visible;
        }

        windowID = "%s###%s".format(displayName_, name_).toStringz;
        displayNamePtr = displayName_.toStringz;
    }

    final string name() {
        return name_;
    }

    final string displayName() {
        return displayName_;
    }

    final const(char)* displayNameC() {
        return displayNamePtr;
    }

    /**
        Draws the panel
    */
    final void update() {
        this.onBeginUpdate();
            if (drewContents) this.onUpdate();
        this.onEndUpdate();
    }

    final bool getDefaultVisibility() {
        return defaultVisibility;
    }
}

/**
    Auto generate panel adder
*/
template inPanel(T) {
    static this() {
        inAddPanel(new T);
    }
}

/**
    Adds panel to panel list
*/
void inAddPanel(Panel panel) {
    inPanels ~= panel;
}

/**
    Draws panels
*/
void inUpdatePanels() {
    foreach(panel; inPanels) {
        if (!panel.visible && !panel.alwaysVisible) continue;

        panel.update();
    }
}

/**
    Draws panels
*/
void inInitPanels() {
    foreach(panel; inPanels) {
        panel.init_();
    }
}

/**
    Panel list
*/
Panel[] inPanels;