module inui.widgets.im.image;
import bindbc.imgui;
import bindbc.opengl;
import inmath.linalg;

void uiImImage(GLuint id, vec2 size, rect textureCutout = rect(0, 0, 1, 1), vec4 tintcolor = vec4.init, vec4 bordercolor = vec4.init) {
    igImage(
        cast(ImTextureID)id, 
        ImVec2(size.x, size.y),
        ImVec2(textureCutout.left, textureCutout.top),
        ImVec2(textureCutout.right, textureCutout.bottom),
    );
}