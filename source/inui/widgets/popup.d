module inui.widgets.popup;
import bindbc.imgui;

/**
    Begins rendering popup

    Call uiImEndPopup at the end of your popup IF uiImBeginPopup returns true.
*/
bool uiImBeginPopup(string id) {
    return igBeginPopupEx(
        igGetID(id.ptr, id.ptr+id.length), 
        ImGuiWindowFlags.AlwaysAutoResize | 
        ImGuiWindowFlags.NoTitleBar | 
        ImGuiWindowFlags.NoSavedSettings
    );
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

/**
    Opens a named popup when an item is right clicked
*/
void uiImRightClickPopup(string id) {
    if (igIsItemClicked(ImGuiMouseButton.Right)) {
        uiImOpenPopup(id);
    }
}