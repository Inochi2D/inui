module inui.widgets.popup;
import bindbc.imgui;

/**
    Begins rendering popup

    Call uiImEndPopup at the end of your popup IF uiImBeginPopup returns true.
*/
bool uiImBeginPopup(string id) {
    return igBeginPopupEx(igGetID(id.ptr, id.ptr+id.length), ImGuiWindowFlags.None);
}

/**
    Ends a popup

    NOTE: Only call in an uiImBeginPopup block
*/
void uiImEndPopup() {
    igEndPopup();
}

/**
    Opens a named popup
*/
void uiImOpenPopup(string id) {
    igOpenPopup(igGetID(id.ptr, id.ptr+id.length));
}