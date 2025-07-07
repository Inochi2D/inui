module inui.core.color;
import inmath.linalg;
import inmath.util;
import i2d.imgui;

/**
    Converts inmath colors to imgui colors.
*/
pragma(inline, true)
ImVec4 toImGuiRGBA(T)(T color) @nogc if (isVector!T && T.dimension == 4) {
    return ImVec4(cast(float)color.x, cast(float)color.y, cast(float)color.z, cast(float)color.w);
}