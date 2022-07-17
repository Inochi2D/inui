/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets;
import bindbc.imgui;

public import inui.widgets.dummy;
public import inui.widgets.image;
public import inui.widgets.input;
public import inui.widgets.menu;
public import inui.widgets.label;
public import inui.widgets.dialog;
public import inui.widgets.progress;
public import inui.widgets.popup;

void uiImPush(int id) {
    igPushID(id);
}

void uiImPush(string id) {
    igPushID(id.ptr, id.ptr+id.length);
}

void uiImPush(T)(T* id) {
    igPushID(id);
}

void uiImPop() {
    igPopID();
}

void uiImIndent(float indentW = 0f) {
    igIndent(indentW);
}

void uiImUnindent() {
    igUnindent();
}

bool uiImHeader(const(char)* label, bool defaultOpen=false) {
    return igCollapsingHeader(label, defaultOpen ? ImGuiTreeNodeFlags.DefaultOpen : ImGuiTreeNodeFlags.None);
}