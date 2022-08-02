/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.input;
import inui.widgets.dummy;

import core.memory : GC;
import bindbc.imgui;
import bindbc.sdl;
import inmath.linalg;
import core.stdc.string : memcpy;
import core.stdc.stdlib : malloc;
import std.string;

private {

    struct TextCallbackUserData {
        string* str;
    }
}

/**
    D compatible text input
*/
bool uiImInputText(string id, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {
    return uiImInputText(id, uiImAvailableSpace().x, buffer, flags);
}

/**
    D compatible text input
*/
bool uiImInputText(string wId, float width, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {

    // NOTE: null strings would result in segfault, make sure it's at least just empty.
    if (buffer.ptr is null) {
        buffer = "";
    }

    // Push ID
    igPushID(igGetID(wId.ptr, wId.ptr+wId.length));
    scope(exit) igPopID();

    // Set callback
    TextCallbackUserData cb;
    cb.str = &buffer;

    // Set desired width
    igPushItemWidth(width);
    scope(exit) igPopItemWidth();

    if (igInputText(
        "###INPUT",
        cast(char*)buffer.ptr, 
        buffer.length+1,
        flags | ImGuiInputTextFlags.CallbackResize,
        cast(ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data) {
            TextCallbackUserData* udata = cast(TextCallbackUserData*)data.UserData;

            // Allow resizing strings on GC heap
            if (data.EventFlag == ImGuiInputTextFlags.CallbackResize) {
            
                // Resize and pass buffer ptr in
                (*udata.str).length = data.BufTextLen+1;
                data.Buf = cast(char*)(*udata.str).ptr;
                
                data.Buf[data.BufTextLen] = '\0';
                (*udata.str) = (*udata.str)[0..$-1];
            }
            return 0;
        },
        &cb
    )) {
        return true;
    }

    ImVec2 min, max;
    igGetItemRectMin(&min);
    igGetItemRectMax(&max);

    auto rect = SDL_Rect(
        cast(int)min.x+32, 
        cast(int)min.y, 
        cast(int)max.x, 
        32
    );

    SDL_SetTextInputRect(&rect);
    return false;
}

/**
    D compatible text input
*/
bool uiImInputText(string id, string label, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {
    return uiImInputText(id, label, uiImAvailableSpace().x, buffer, flags);
}

/**
    D compatible text input
*/
bool uiImInputText(string wId, string label, float width, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {

    // NOTE: null strings would result in segfault, make sure it's at least just empty.
    if (buffer.ptr is null) {
        buffer = "";
    }

    // Push ID
    igPushID(igGetID(wId.ptr, wId.ptr+wId.length));
    scope(exit) igPopID();

    // Set callback
    TextCallbackUserData cb;
    cb.str = &buffer;

    // Set desired width
    igPushItemWidth(width);
    scope(exit) igPopItemWidth();
    
    // Render label
    scope(success) {
        igSameLine(0, igGetStyle().ItemSpacing.x);
        igTextEx(label.ptr, label.ptr+label.length);
    }

    if (igInputText(
        "###INPUT",
        cast(char*)buffer.ptr, 
        buffer.length+1,
        flags | ImGuiInputTextFlags.CallbackResize,
        cast(ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data) {
            TextCallbackUserData* udata = cast(TextCallbackUserData*)data.UserData;

            // Allow resizing strings on GC heap
            if (data.EventFlag == ImGuiInputTextFlags.CallbackResize) {
            
                // Resize and pass buffer ptr in
                (*udata.str).length = data.BufTextLen+1;

                // slice out the null terminator
                data.Buf = cast(char*)(*udata.str).ptr;
                data.Buf[data.BufTextLen] = '\0';
                (*udata.str) = (*udata.str)[0..$-1];
            }
            return 0;
        },
        &cb
    )) {
        return true;
    }

    ImVec2 min, max;
    igGetItemRectMin(&min);
    igGetItemRectMax(&max);

    auto rect = SDL_Rect(
        cast(int)min.x+32, 
        cast(int)min.y, 
        cast(int)max.x, 
        32
    );

    SDL_SetTextInputRect(&rect);
    return false;
}

/**
    A button
*/
bool uiImCheckbox(const(char)* text, ref bool val) {
    return igCheckbox(text, &val);
}

/**
    A button
*/
bool uiImButton(const(char)* text, vec2 size = vec2(0)) {
    return igButton(text, ImVec2(size.x, size.y));
}

/**
    A min/max range selector
*/
void uiImRange(ref float cmin, ref float cmax, float min, float max) {
    igDragFloatRange2("", &cmin, &cmax, 1.0f, min, max);
}

/**
    A min/max range selector
*/
void uiImRange(ref int cmin, ref int cmax, int min, int max) {
    igDragIntRange2("", &cmin, &cmax, 1.0f, min, max);
}

/**
    A widget that allows you to drag between a min and max value
*/
void uiImDrag(ref float val, float min, float max) {
    igDragFloat("", &val, 1.0f, min, max);
}

/**
    A widget that allows you to drag between a min and max value
*/
void uiImDrag(ref int val, int min, int max) {
    igDragInt("", &val, 1.0f, min, max);
}

/**
    A widget that allows you to drag between a min and max value
*/
void uiImDrag2(ref float[] val, float min, float max) {
    igDragFloat2("", cast(float[2]*)val.ptr, 1.0f, min, max);
}

/**
    A widget that allows you to drag between a min and max value
*/
void uiImDrag3(ref float[] val, float min, float max) {
    igDragFloat3("", cast(float[3]*)val.ptr, 1.0f, min, max);
}

/**
    A widget that allows you to drag between a min and max value
*/
void uiImDrag4(ref float[] val, float min, float max) {
    igDragFloat4("", cast(float[4]*)val.ptr, 1.0f, min, max);
}

/**
    Begins a combo box
*/
bool uiImBeginComboBox(string id, const(char)* previewName) {
    igPushID(id.ptr, id.ptr+id.length);
    bool ret = igBeginCombo("###COMBO", previewName);
    if (!ret) igPopID();
    return ret;
}

/**
    Ends a combo box
*/
void uiImEndComboBox() {
    igEndCombo();
    igPopID(); // Pop extra ID pushed by uiImBeginComboBox
}

/**
    A selectable
*/
bool uiImSelectable(const(char)* name, bool selected = false) {
    return igSelectable(name, selected);
}

/**
    Color editor
*/
bool uiImColor4(const(char)* label, float[4]* colors) {
    return igColorEdit4(label, colors);
}

/**
    Color editor
*/
bool uiImColorButton4(const(char)* label, float[4]* colors) {
    return igColorEdit4(label, colors, ImGuiColorEditFlags.NoInputs | ImGuiColorEditFlags.AlphaBar);
}

/**
    Color picker
*/
bool uiImColorPicker4(const(char)* label, float[4]* colors) {
    return igColorPicker4(label, colors);
}

/**
    Color swatch
*/
bool uiImColorSwatch4(const(char)* description, vec4 color) {
    return igColorButton(description, ImVec4(color.r, color.g, color.b, color.a));
}