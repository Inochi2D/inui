/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.input;
import bindbc.imgui;
import inmath;

enum MouseButton {
    Left = ImGuiMouseButton.Left,
    Middle = ImGuiMouseButton.Middle,
    Right = ImGuiMouseButton.Right,
}

private {
    bool[3] wasMouseDown;
    bool[3] isMouseDown;

    bool[3] downBeganInWindow;
}

void inInputUpdate() {
    wasMouseDown[0] = isMouseDown[0];
    wasMouseDown[1] = isMouseDown[1];
    wasMouseDown[2] = isMouseDown[2];

    isMouseDown[0] = igIsMouseDown(ImGuiMouseButton.Left);
    isMouseDown[1] = igIsMouseDown(ImGuiMouseButton.Middle);
    isMouseDown[2] = igIsMouseDown(ImGuiMouseButton.Right);


    // Handle data for querying whether the mouse input began in the UI
    if (!wasMouseDown[0] && isMouseDown[0] && inInputIsInUI()) downBeganInWindow[0] = true;
    if (!wasMouseDown[1] && isMouseDown[1] && inInputIsInUI()) downBeganInWindow[1] = true;
    if (!wasMouseDown[2] && isMouseDown[2] && inInputIsInUI()) downBeganInWindow[2] = true;
    if (!isMouseDown[0]) downBeganInWindow[0] = false;
    if (!isMouseDown[1]) downBeganInWindow[1] = false;
    if (!isMouseDown[2]) downBeganInWindow[2] = false;

}

/**
    Whether the mouse being down began in the UI
*/
bool inInputMouseDownBeganInUI(MouseButton button) {
    return isMouseDown[cast(int)button] && downBeganInWindow[cast(int)button];
}

/**
    Whether the mouse is within the UI
*/
bool inInputIsInUI() {
    return igGetCurrentContext().HoveredWindow != null;
}

/**
    Gets whether the mouse was clicked
*/
bool inInputMouseDown(MouseButton button) {
    return isMouseDown[cast(int)button];
}

/**
    Gets whether the mouse was clicked
*/
bool inInputWasMouseDown(MouseButton button) {
    return wasMouseDown[cast(int)button];
}

/**
    Gets whether the mouse was clicked
*/
bool inInputMouseClicked(MouseButton button, bool repeat=false) {
    return igIsMouseClicked(cast(ImGuiMouseButton)button, repeat);
}

/**
    Gets whether the mouse was double clicked
*/
bool inInputMouseDoubleClicked(MouseButton button) {
    return igIsMouseDoubleClicked(cast(ImGuiMouseButton)button);
}

/**
    Gets whether the mouse is being dragged
*/
bool inInputMouseDragging(MouseButton button) {
    return igIsMouseDragging(cast(ImGuiMouseButton)button);
}

/**
    Gets the delta (offset) of the mouse being dragged
*/
vec2 inInputMouseDragDelta(MouseButton button, float lockThreshold=-1.0) {
    ImVec2 v2;
    igGetMouseDragDelta(&v2, cast(ImGuiMouseButton)button, lockThreshold);
    return vec2(v2.x, v2.y);
}

/**
    Gets the position of the mouse cursor
*/
vec2 inInputMousePosition() {
    ImVec2 v2;
    igGetMousePos(&v2);
    return vec2(v2.x, v2.y);
}

/**
    Gets the scrolling delta of the mouse
*/
float inInputMouseScrollDelta() {
    return igGetIO().MouseWheel;
}