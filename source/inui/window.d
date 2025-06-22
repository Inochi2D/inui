/**
    Windows

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.window;
import std.algorithm.mutation : remove;
import inui.core.window;
import inui.core.imgui;
import inui.widgets;
import inmath;
import numem;
import sdl;

// Re-exported symbols
public import inui.core.window : SystemTheme, SystemVibrancy;

/**
    A window
*/
class Window {
private:
    NativeWindow backing;
    IGContext context;

    __gshared Window[] __active_windows;
    ptrdiff_t getIndex() {
        foreach(i; 0..__active_windows.length) {
            if (__active_windows[i] is this)
                return i;
        }
        return -1;
    }

public:

    /**
        The root level widget of the window.
    */
    ImWorkspace workspace;

    /**
        All currently active windows.
    */
    static
    @property Window[] windows() { return __active_windows; }

    /**
        This Window's ImGui context.
    */
    @property IGContext imgui() { return context; }

    /**
        The backing native window.
    */
    @property NativeWindow backingWindow() { return backing; }
    
    /**
        Whether the window has a vibrancy effect.
    */
    @property SystemVibrancy vibrancy() { return backing.vibrancy; }
    @property auto vibrancy(SystemVibrancy value) {
        backing.vibrancy = value;
        return this;
    }

    /**
        The title of the window
    */
    @property string title() { return backing.title.dup; }
    @property auto title(string value) { backing.title = value; return this; }

    /**
        Whether the NativeWindow was requested to close
    */
    @property bool isCloseRequested() { return backing.isCloseRequested; }

    /**
        The scaling factor of content on the current active display.
    */
    @property float scale() { return backing.scale; }

    /**
        The pixel density of the window.
    */
    @property float pixelDensity() { return backing.pixelDensity; }

    /**
        Opacity of the window
    */
    @property float opacity() { return backing.opacity; }

    /**
        Whether the Window is fullscreen or windowed.
    */
    @property bool fullscreen() { return backing.fullscreen; }
    @property auto fullscreen(bool value) { backing.fullscreen = value; return this; }

    /**
        Whether the Window may be resized.
    */
    @property bool resizable() { return backing.resizable; }
    @property auto resizable(bool value) { backing.resizable = value; return this; }
    /**
        Whether the NativeWindow is visible.
    */
    @property bool isVisible() { return backing.isVisible; }

    /**
        Whether the NativeWindow is modal.
    */
    @property bool isModal() { return backing.isModal; }
    @property auto isModal(bool value) { backing.isModal = value; return this; }

    /**
        The maximum size of the NativeWindow in points.
    */
    @property vec2i minimumSize() { return backing.minimumSize; }
    @property auto minimumSize(vec2i value) { backing.minimumSize = value; return this;}

    /**
        The maximum size of the NativeWindow in points.
    */
    @property vec2i maximumSize() { return backing.maximumSize; }
    @property auto maximumSize(vec2i value) { backing.maximumSize = value; return this; }
    
    /**
        The size of the NativeWindow in points.
    */
    @property vec2i ptSize() { return backing.ptSize; }
    @property auto ptSize(vec2i value) { backing.ptSize = value; return this; }

    /**
        The size of the NativeWindow in pixels.
    */
    @property vec2i pxSize() { return backing.pxSize; }
    @property auto pxSize(vec2i value) { backing.pxSize = value; return this; }

    /**
        The position of the NativeWindow in points.

        May be unavailable on some platforms.
    */
    @property vec2i position() { return backing.position; }

    /**
        The area of the NativeWindow that's safe for interactive content.
    */
    @property recti safeArea() { return backing.safeArea; }

    /**
        Whether text input is active.
    */
    @property bool isTextInputActive() { return backing.isTextInputActive(); }

    /**
        Whether an on-screen-keyboard is being shown.
    */
    @property bool isOSKShown() { return backing.isOSKShown(); }

    /**
        The active system theme.
    */
    static
    @property SystemTheme systemTheme() { return NativeWindow.systemTheme; }

    /**
        Gets a NativeWindow from its ID.
    */
    static
    Window fromID(uint id) {
        if (NativeWindow handle = NativeWindow.fromID(id)) {
            foreach(ref Window window; __active_windows) {
                if (window.backing is handle)
                    return window;
            }
        }
        return null;
    }

    /**
        Destructor
    */
    ~this() {
        nogc_delete(backing);

        // Delete self from window list.
        ptrdiff_t idx = getIndex();
        if (idx >= 0) {
            __active_windows = __active_windows.remove(idx);
        }
    }

    /**
        Opens a new backing window
    */
    this(string title, int width, int height, ulong flags = 0) {
        this.backing = nogc_new!NativeWindow(title, vec2i(width, height), flags);
        this.context = new IGContext(backing);
        this.workspace = new ImWorkspace(this);
        __active_windows ~= this;
    }

    /**
        Processes an event.
    */
    bool processEvent(const(SDL_Event)* event) {
        return context.processEvent(event);
    }

    /**
        Starts rendering a new frame in the window.
    */
    void update(float deltaTime) {
        context.makeCurrent();

        context.beginFrame(backing, deltaTime);
            workspace.update(deltaTime);
        context.endFrame(backing);
        this.swap();
    }

    /**
        Starts text input for the window.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool startTextInput() { return backing.startTextInput(); }

    /**
        Stops text input for the window.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool stopTextInput() { return backing.stopTextInput(); }

    /**
        Clears the composition for the window.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool clearComposition() { return backing.clearComposition(); }

    /**
        Shows the window.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool show() { return backing.show(); }

    /**
        Hides the window.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool hide() { return backing.hide(); }

    /**
        Requests that the NativeWindow be raised to the font, and for
        input focus to be delegated to it.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool raise() { return backing.raise(); }

    /**
        Flashes the window.

        Params:
            untilFocused = Whether the NativeWindow should be flashed until it is focused.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool flash(bool untilFocused = false) nothrow { return backing.flash(untilFocused); }

    /**
        Waits for all of the requested NativeWindow changes to take effect.
        
        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool sync() { return backing.sync(); }

    /**
        Swaps the double-buffered window.
        
        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool swap() { return backing.swap(); }

    /**
        Requests that the NativeWindow be closed.
    */
    void close() { backing.close(); }
}