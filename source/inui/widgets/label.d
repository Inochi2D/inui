/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.label;
import bindbc.imgui;
import bindbc.opengl;
import inmath.linalg;

void uiImLabel(string text) {
    igTextEx(text.ptr, text.ptr+text.length);
}

void uiImLabelColored(string text, vec4 color) {
    igPushStyleColor(ImGuiCol.Text, ImVec4(color.x, color.y, color.z, color.w));
        igTextEx(text.ptr, text.ptr+text.length);
    igPopStyleColor();
}

/**
    Render disabled text
*/
void uiImLabelDisabled(string text) {
    igPushStyleColor(ImGuiCol.Text, igGetStyle().Colors[ImGuiCol.TextDisabled]);
        igTextUnformatted(text.ptr, text.ptr+text.length);
    igPopStyleColor();
}

/**
    Render wrapped text
*/
void uiImLabelWrapped(string text, float wrapPosition=0f) {
    uiImPushTextWrapPos(wrapPosition);
        igTextUnformatted(text.ptr, text.ptr+text.length);
    uiImPopTextWrapPos();
}

/**
    Pushes a text wrap position
*/
void uiImPushTextWrapPos(float wrapPosition=0f) {
    igPushTextWrapPos(wrapPosition);
}

/**
    Pops a text wrap position
*/
void uiImPopTextWrapPos() {
    igPopTextWrapPos();
}