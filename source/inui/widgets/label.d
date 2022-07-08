module inui.widgets.label;
import bindbc.imgui;
import bindbc.opengl;
import inmath.linalg;

void uiImLabel(string text) {
    igTextEx(text.ptr, text.ptr+text.length);
}