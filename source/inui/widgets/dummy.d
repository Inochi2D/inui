/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.dummy;
import bindbc.imgui;
import std.math : abs;
import inmath.linalg;

/**
    More advanced dummy widget
*/
void uiImDummy(vec2 size) {
    vec2 avail = uiImAvailableSpace();
    if (size.x <= 0) size.x = avail.x - abs(size.x);
    if (size.y <= 0) size.y = avail.y - abs(size.y);
    igDummy(*(cast(ImVec2*)&size));
}

/**
    A same-line spacer
*/
void uiImSpacer(vec2 size) {
    igSameLine(0, 0);
    uiImDummy(size);
}

/**
    Keeps content on one line with the specified offset.
*/
void uiImSameLine(float startOffset=0, float spacing=-1) {
    igSameLine(startOffset, spacing);
}

/**
    Gets available space
*/
vec2 uiImAvailableSpace() {
    vec2 avail;
    igGetContentRegionAvail(cast(ImVec2*)&avail);
    return avail;
}

/**
    Measures a string in pixels
*/
vec2 uiImMeasureString(string text) {
    vec2 strLen;
    igCalcTextSize(cast(ImVec2*)&strLen, text.ptr, text.ptr+text.length);
    return vec2(strLen.x, strLen.y);
}

