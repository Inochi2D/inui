/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.image;
import bindbc.imgui;
import bindbc.opengl;
import inmath.linalg;

void uiImImage(GLuint id, vec2 size, rect textureCutout = rect(0, 0, 1, 1), vec4 tintcolor = vec4(1), vec4 bordercolor = vec4(0)) {
    igImage(
        cast(ImTextureID)id, 
        ImVec2(size.x, size.y),
        ImVec2(textureCutout.left, textureCutout.top),
        ImVec2(textureCutout.right, textureCutout.bottom),
        ImVec4(tintcolor.x, tintcolor.y, tintcolor.z, tintcolor.w),
        ImVec4(bordercolor.x, bordercolor.y, bordercolor.z, bordercolor.w)
    );
}