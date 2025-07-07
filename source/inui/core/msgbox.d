module inui.core.msgbox;
import sdl.messagebox;
import nulib.string;

enum MessageType : SDL_MessageBoxFlags {
    error = SDL_MessageBoxFlags.SDL_MESSAGEBOX_ERROR,
    warning = SDL_MessageBoxFlags.SDL_MESSAGEBOX_WARNING,
    info = SDL_MessageBoxFlags.SDL_MESSAGEBOX_INFORMATION,
}

/**
    Interface for messages boxes.
*/
class MessageBox {

    /**
        Shows an informational message box without requiring Inochi Creator
        to be fully initialized.
    */
    static bool show(MessageType type, string msgtitle, string msgbody) {
        nstring _title = msgtitle;
        nstring _body = msgbody;
        return SDL_ShowSimpleMessageBox(type, _title.ptr, _body.ptr, null);
    }
}