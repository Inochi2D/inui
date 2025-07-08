/**
    Small utility functions.

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.utils;
import inmath.linalg;
import inmath.util;
import i2d.imgui;

/**
    Converts between inmath and imgui types.
*/
pragma(inline, true)
auto ref inout(U) toImGui(U, T)(auto ref inout(T) value) @nogc nothrow pure {
    static if (isVector!T && T.dimension == 2 && is(U == ImVec2)) {
        static if (is(T == float)) {
            return *(cast(ImVec2*)&value);
        } else {
            return U(value.x, value.y);
        }
    } else static if (isVector!T && T.dimension == 4 && is(U == ImVec4)) {
        static if (is(T == float)) {
            return *(cast(ImVec4*)&value);
        } else {
            return U(value.x, value.y, value.z, value.w);
        }
    } else static if (isRect!T && is(U == ImRect)) {
        return U(ImVec2(value.left, value.right), ImVec2(value.right, value.bottom));
    } else static if (isRect!T && is(U == ImVec4)) {
        return U(value.left, value.right, value.right, value.bottom);
    } else static assert(0, "Not supported.");
}

/**
    Converts between imgui and inmath types.
*/
pragma(inline, true)
auto ref inout(U) fromImGui(U, T)(auto ref inout(T) value) @nogc nothrow pure {
    static if (isVector!U && U.dimension == 2 && is(T == ImVec2)) {
        static if (is(T == float)) {
            return *(cast(U*)&value);
        } else {
            return U(value.x, value.y);
        }
    } else static if (isVector!U && U.dimension == 4 && is(T == ImVec4)) {
        static if (is(T == float)) {
            return *(cast(U*)&value);
        } else {
            return U(value.x, value.y, value.z, value.w);
        }
    } else static if (isRect!U && is(T == ImRect)) {
        return U(value.min.x, value.min.y, value.max.x-value.min.x, value.max.y-value.min.y);
    } else static if (isRect!U && is(T == ImVec4)) {
        return U(value.x, value.y, value.z-value.x, value.w-value.y);
    } else static assert(0, "Not supported.");
}