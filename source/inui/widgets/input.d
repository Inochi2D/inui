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

private {
    struct Str {
        string str;
    }
}

/**
    D compatible text input
*/
bool uiImInputText(const(char)* wId, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {
    return uiImInputText(wId, uiImAvailableSpace().x, buffer, flags);
}

/**
    D compatible text input
*/
bool uiImInputText(const(char)* wId, float width, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {
    auto id = igGetID(wId);
    auto storage = igGetStateStorage();

    // We put a new string container on the heap and make sure the GC doesn't yeet it.
    if (ImGuiStorage_GetVoidPtr(storage, id) is null) {
        Str* cursedString = new Str(buffer~"\0");
        GC.addRoot(cursedString);
        ImGuiStorage_SetVoidPtr(storage, id, cursedString);
    }

    // We get it
    Str* str = cast(Str*)ImGuiStorage_GetVoidPtr(storage, id);

    igPushItemWidth(width);
    if (igInputText(
        wId,
        cast(char*)str.str.ptr, 
        str.str.length,
        flags | 
            ImGuiInputTextFlags.CallbackResize,
        cast(ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data) {

            // Allow resizing strings on GC heap
            if (data.EventFlag == ImGuiInputTextFlags.CallbackResize) {
                Str* str = (cast(Str*)data.UserData);
                str.str ~= "\0";
                str.str.length = data.BufTextLen;
            }
            return 1;
        },
        str
    )) {

        // Apply string, without null terminator
        buffer = str.str;
        GC.removeRoot(ImGuiStorage_GetVoidPtr(storage, id));
        ImGuiStorage_SetVoidPtr(storage, id, null);
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
bool uiImButton(const(char)* text, vec2 size = vec2(0)) {
    return igButton(text, ImVec2(size.x, size.y));
}