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