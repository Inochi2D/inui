module inui.widgets.progress;
import bindbc.imgui;
import inmath;

void uiImProgress(float progress, vec2 size = vec2(-float.min_normal, 0), const(char)* text=null) {
    igProgressBar(progress, ImVec2(size.x, size.y), text);
}