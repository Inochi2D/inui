/**
    Inui Window

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.window;
import inui.widgets;
import inmath;
import nulib;
import numem;
import sdl;
import sdl.rect;

/**
    A window
*/
class NativeWindow : NuObject {
private:
@nogc:
    __gshared weak_vector!NativeWindow windows_;

    SDL_Window* handle;
    GLContext glctx;
    bool closeRequested = false;

    T getProperty(T)(string key, T defaultValue = T.init) {
        import sdl.properties;

        SDL_PropertiesID propId = SDL_GetWindowProperties(handle);
        if (propId == 0)
            return defaultValue;
        
        nstring zkey = key;
        static if (is(T : string)) {
            const(char)* value = SDL_GetStringProperty(propId, zkey.ptr, defaultValue.ptr);
            return value ? value[0..nu_strlen(value)] : null;
        } else static if (is(T == bool)) {
            return SDL_GetBooleanProperty(propId, zkey.ptr, defaultValue);
        } else static if (__traits(isFloating, T)) {
            return cast(T)SDL_GetFloatProperty(propId, zkey.ptr, cast(float)defaultValue);
        } else static if (__traits(isIntegral, T)) {
            return cast(T)SDL_GetNumberProperty(propId, zkey.ptr, defaultValue);
        } else static if (is(T == U*, U)) {
            return cast(T)SDL_GetPointerProperty(propId, zkey.ptr, cast(void*)defaultValue);
        } else static assert(0, T.stringof~" is not supported.");
    }

    enum ulong BASE_FLAGS = SDL_WindowFlags.SDL_WINDOW_OPENGL | SDL_WindowFlags.SDL_WINDOW_HIDDEN;

public:

    /**
        The window's widget.
    */
    Widget widget;

    /**
        The ID of the window
    */
    @property uint id() { return SDL_GetWindowID(handle); }

    /**
        Whether the NativeWindow was requested to close
    */
    @property bool isCloseRequested() { return closeRequested; }

    /**
        The parent of the window.
    */
    @property NativeWindow parent() { return NativeWindow.fromHandle(SDL_GetWindowParent(handle)); }
    @property auto parent(NativeWindow value) {
        cast(void)SDL_SetWindowParent(handle, value.handle);
        return this;
    }

    /**
        The title of the window
    */
    @property nstring title() { return nstring(SDL_GetWindowTitle(handle)); }
    @property auto title(string title) {
        nstring tmp = title;
        cast(void)SDL_SetWindowTitle(handle, tmp.ptr);
        return this;
    }

    /**
        The scaling factor of content on the current active display.
    */
    @property float scale() { return SDL_GetWindowDisplayScale(handle); }

    /**
        The pixel density of the window.
    */
    @property float pixelDensity() { return SDL_GetWindowPixelDensity(handle); }

    /**
        Opacity of the window
    */
    @property float opacity() { return SDL_GetWindowOpacity(handle); }

    /**
        The raw ICC Profile data of the window.
    */
    @property void[] iccProfile() {
        size_t iccSize;
        void* iccProfile = SDL_GetWindowICCProfile(handle, &iccSize);
        return iccProfile[0..iccSize];
    }

    /**
        Whether the NativeWindow is capable of rendering HDR content.
    */
    @property bool hasHighDynamicRange() { return this.getProperty!bool(SDL_PROP_WINDOW_HDR_ENABLED_BOOLEAN, false); }

    /**
        The additional amount of dynamic range that can be displayed
        compared to the $(D sdrWhiteLevel)
    */
    @property float hdrHeadroom() { return this.getProperty!float(SDL_PROP_WINDOW_HDR_HEADROOM_FLOAT, 1.0); }

    /**
        The value of the SDR whitepoint in sRGB.
    */
    @property float sdrWhiteLevel() { return this.getProperty!float(SDL_PROP_WINDOW_SDR_WHITE_LEVEL_FLOAT, 1.0); }

    /**
        The native NativeWindow handle
    */
    @property void* nativeHandle() {
        version(Windows) return this.getProperty!(void*)(SDL_PROP_WINDOW_WIN32_HWND_POINTER, null);
        else version(OSX) return this.getProperty!(void*)(SDL_PROP_WINDOW_COCOA_WINDOW_POINTER, null);
        else version(iOS) return this.getProperty!(void*)(SDL_PROP_WINDOW_UIKIT_WINDOW_POINTER, null);
        else version(Posix) {
            if (auto wlsurface = this.getProperty!(void*)(SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER, null))
                return wlsurface;
            return cast(void*)this.getProperty!size_t(SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
        } else static assert(0, "Platform not supported.");
    }

    /**
        Whether the NativeWindow is fullscreen or windowed.
    */
    @property bool fullscreen() { return SDL_GetWindowFullscreenMode(handle) !is null; }
    @property auto fullscreen(bool value) { cast(void)SDL_SetWindowFullscreen(handle, value); return this; }

    /**
        Whether the NativeWindow may be resized.
    */
    @property bool resizable() { return cast(bool)(SDL_GetWindowFlags(handle) & SDL_WindowFlags.SDL_WINDOW_RESIZABLE); }
    @property auto resizable(bool value) { cast(void)SDL_SetWindowResizable(handle, value); return this; }

    /**
        Whether the NativeWindow is visible.
    */
    @property bool isVisible() { return !(SDL_GetWindowFlags(handle) & SDL_WindowFlags.SDL_WINDOW_HIDDEN); }

    /**
        Whether the NativeWindow is modal.
    */
    @property bool isModal() { return cast(bool)(SDL_GetWindowFlags(handle) & SDL_WindowFlags.SDL_WINDOW_MODAL); }
    @property auto isModal(bool value) { cast(void)SDL_SetWindowModal(handle, value); return this; }

    /**
        The maximum size of the NativeWindow in points.
    */
    @property vec2i minimumSize() { return SDL_GetWindowMinimumSizeExt(handle); }
    @property auto minimumSize(vec2i value) { SDL_SetWindowMinimumSizeExt(handle, value); return this;}

    /**
        The maximum size of the NativeWindow in points.
    */
    @property vec2i maximumSize() { return SDL_GetWindowMaximumSizeExt(handle); }
    @property auto maximumSize(vec2i value) { SDL_SetWindowMaximumSizeExt(handle, value); return this; }
    
    /**
        The size of the NativeWindow in points.
    */
    @property vec2i ptSize() { return SDL_GetWindowSizeExt(handle); }
    @property auto ptSize(vec2i value) { SDL_SetWindowSizeExt(handle, value); return this; }

    /**
        The size of the NativeWindow in pixels.
    */
    @property vec2i pxSize() { return SDL_GetWindowSizeInPixelsExt(handle); }
    @property auto pxSize(vec2i value) { SDL_SetWindowSizeInPixelsExt(handle, value); return this; }

    /**
        The position of the NativeWindow in points.

        May be unavailable on some platforms.
    */
    @property vec2i position() { return SDL_GetWindowPositionExt(handle); }

    /**
        The OpenGL Context associated with the window.
    */
    @property GLContext gl() { return glctx; }

    /**
        The area of the NativeWindow that's safe for interactive content.
    */
    @property recti safeArea() {
        SDL_Rect r;
        cast(void)SDL_GetWindowSafeArea(handle, &r);
        return recti(r.x, r.y, r.w, r.h);
    }

    /**
        The active system theme.
    */
    static
    @property SystemTheme systemTheme() { return cast(SystemTheme)SDL_GetSystemTheme(); }

    /**
        List of all open windows.
    */
    static
    @property NativeWindow[] windows() { return windows_[0..$]; }

    /**
        Destructor
    */
    ~this() {
        windows_.remove(this);
        SDL_DestroyWindow(handle);
    }

    /**
        Constructs a NativeWindow from an existing SDL Window.

        Params:
            handle = The SDL NativeWindow handle
    */
    this(SDL_Window* handle) {
        assert(handle, "Failed creating NativeWindow handle");
        this.handle = handle;
        this.glctx = GLContext.fromWindow(this);
    }

    /**
        Constructs a new window

        Params:
            title = Title of the window
            size = Size of the window
            flags = Additional flags to be passed to the window.
    */
    this(string title, vec2i size, ulong flags = 0) {
        nstring zTitle = title;
        this(SDL_CreateWindow(zTitle.ptr, size.x, size.y, cast(SDL_WindowFlags)(flags | BASE_FLAGS)));
    }

    /**
        Creates a new utility window, which does not appear in the taskbar or NativeWindow list.

        Params:
            title = Title of the window
            size = Size of the window
            flags = Additional flags to be passed to the window.

        Returns:
            A new utility window.
    */
    static
    NativeWindow createUtilityWindow(string title, vec2i size, ulong flags) {
        return nogc_new!NativeWindow(title, size, cast(ulong)SDL_WindowFlags.SDL_WINDOW_UTILITY);
    }

    /**
        Gets a NativeWindow from its ID.
    */
    static
    NativeWindow fromID(uint id) {
        auto handle = SDL_GetWindowFromID(id);
        if (handle) {
            foreach(ref NativeWindow window; windows_) {
                if (window.handle == handle)
                    return window;
            }
            return nogc_new!NativeWindow(handle);
        }
        return null;
    }

    /**
        Gets a NativeWindow from its handle.
    */
    static
    NativeWindow fromHandle(SDL_Window* handle) {
        if (handle) {
            foreach(ref NativeWindow window; windows_) {
                if (window.handle == handle)
                    return window;
            }
            return nogc_new!NativeWindow(handle);
        }
        return null;
    }

    /**
        Shows the window.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool show() {
        return SDL_ShowWindow(handle);
    }

    /**
        Hides the window.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool hide() {
        return SDL_HideWindow(handle);
    }

    /**
        Requests that the NativeWindow be raised to the font, and for
        input focus to be delegated to it.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool raise() {
        return SDL_RaiseWindow(handle);
    }

    /**
        Flashes the window.

        Params:
            untilFocused = Whether the NativeWindow should be flashed until it is focused.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool flash(bool untilFocused = false) nothrow {
        return SDL_FlashWindow(handle, 
            untilFocused ? SDL_FlashOperation.SDL_FLASH_UNTIL_FOCUSED : SDL_FlashOperation.SDL_FLASH_BRIEFLY
        );
    }

    /**
        Waits for all of the requested NativeWindow changes to take effect.
        
        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool sync() {
        return SDL_SyncWindow(handle);
    }

    /**
        Swaps the double-buffered window.
        
        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool swap() {
        return SDL_GL_SwapWindow(handle);
    }

    /**
        Requests that the NativeWindow be closed.
    */
    void close() {
        closeRequested = true;
    }
}

/**
    A popup window.
*/
class PopupNativeWindow : NativeWindow {
public:
@nogc:

    /**
        Constructs a popup window.
    */
    this(SDL_Window* handle) {
        super(handle);
    }

    /**
        Creates a new tooltip popup window.
    */
    static PopupNativeWindow createTooltip(NativeWindow parent, vec2i offset, vec2i size, ulong flags) {
        return nogc_new!PopupNativeWindow(SDL_CreatePopupWindow(
            parent ? parent.handle : null,
            offset.x, offset.y,
            size.x, size.y,
            cast(SDL_WindowFlags)(SDL_WindowFlags.SDL_WINDOW_TOOLTIP | BASE_FLAGS | flags)
        ));
    }

    /**
        Creates a new tooltip popup window.
    */
    static PopupNativeWindow createPopup(NativeWindow parent, vec2i offset, vec2i size, ulong flags) {
        return nogc_new!PopupNativeWindow(SDL_CreatePopupWindow(
            parent ? parent.handle : null,
            offset.x, offset.y,
            size.x, size.y,
            cast(SDL_WindowFlags)(SDL_WindowFlags.SDL_WINDOW_POPUP_MENU | BASE_FLAGS | flags)
        ));
    }
}

/**
    A system theme
*/
enum SystemTheme : SDL_SystemTheme {
    
    /**
        Unknown system theme
    */
    unknown = SDL_SystemTheme.SDL_SYSTEM_THEME_UNKNOWN,
    
    /**
        Light colored system theme
    */
    light = SDL_SystemTheme.SDL_SYSTEM_THEME_LIGHT,
    
    /**
        Dark colored system theme
    */
    dark = SDL_SystemTheme.SDL_SYSTEM_THEME_DARK
}

/**
    An OpenGL Context
*/
final
class GLContext : NuObject {
private:
@nogc:
    __gshared weak_vector!GLContext __glContexts;

    // Thread-Local
    static GLContext __currentGLCtx;

    NativeWindow window;
    SDL_GLContext ctx;

public:

    /**
        Whether this context is the current context.
    */
    @property bool isCurrent() { return __currentGLCtx is this; }

    /**
        Whether Vertical Sync is enabled.
    */
    @property bool vsync() {
        this.makeCurrent();
        int swapInterval;
        return SDL_GL_GetSwapInterval(&swapInterval) && swapInterval != 0;
    }
    @property void vsync(bool value) {
        this.makeCurrent();
        if (value && !SDL_GL_SetSwapInterval(-1)) {
            cast(void)SDL_GL_SetSwapInterval(1);
            return;
        }
        cast(void)SDL_GL_SetSwapInterval(0);
    }

    /**
        Destructor
    */
    ~this() {
        __glContexts.remove(this);
        SDL_GL_DestroyContext(ctx);
    }

    /**
        Constructor
    */
    this(NativeWindow window, SDL_GLContext ctx) {
        this.window = window;
        this.ctx = ctx;
        __glContexts ~= this;
    }

    /**
        Gets a GL context from its window
    */
    static
    GLContext fromWindow(NativeWindow window) {
        if (!window)
            return null;
            
        foreach(ref GLContext ctx; __glContexts) {
            if (ctx.window is window)
                return ctx;
        }

        // If that NativeWindow has a GL context, but isn't in our list,
        // add it.
        if (SDL_GetWindowFlags(window.handle) & SDL_WindowFlags.SDL_WINDOW_OPENGL) {
            return nogc_new!GLContext(window, SDL_GL_CreateContext(window.handle));
        }
        return null;
    }

    /**
        Gets whether the given extension is supported.

        Params:
            extension = The OpenGL extension to query.
        
        Returns:
            $(D true) if this context supports the requested extension.
            $(D false) otherwise.
    */
    bool extensionSupported(string extension) {
        if (!isCurrent)
            this.makeCurrent();
        
        nstring tmp = extension;
        return SDL_GL_ExtensionSupported(tmp.ptr);
    }

    /**
        Makes the context current.
        
        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool makeCurrent() {
        if (__currentGLCtx !is this) {
            __currentGLCtx = this;
            return SDL_GL_MakeCurrent(window.handle, ctx);
        }
        return true;
    }
}

//
//          EXTENDED API
//

private
vec2i SDL_GetWindowMaximumSizeExt(SDL_Window* window) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    vec2i size;
    cast(void)SDL_GetWindowMaximumSize(window, &size.vector[0], &size.vector[1]);
    return size;
}

private
void SDL_SetWindowMaximumSizeExt(SDL_Window* window, vec2i value) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    cast(void)SDL_SetWindowMaximumSize(window, value.x, value.y);
}

private
vec2i SDL_GetWindowMinimumSizeExt(SDL_Window* window) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    vec2i size;
    cast(void)SDL_GetWindowMinimumSize(window, &size.vector[0], &size.vector[1]);
    return size;
}

private
void SDL_SetWindowMinimumSizeExt(SDL_Window* window, vec2i value) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    cast(void)SDL_SetWindowMinimumSize(window, value.x, value.y);
}

private
vec2i SDL_GetWindowSizeExt(SDL_Window* window) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    vec2i size;
    cast(void)SDL_GetWindowSize(window, &size.vector[0], &size.vector[1]);
    return size;
}

private
void SDL_SetWindowSizeExt(SDL_Window* window, vec2i value) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    cast(void)SDL_SetWindowSize(window, value.x, value.y);
}

private
vec2i SDL_GetWindowSizeInPixelsExt(SDL_Window* window) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    vec2i size;
    cast(void)SDL_GetWindowSizeInPixels(window, &size.vector[0], &size.vector[1]);
    return size;
}

private
void SDL_SetWindowSizeInPixelsExt(SDL_Window* window, vec2i value) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    float sFactor = SDL_GetWindowDisplayScale(window);
    cast(void)SDL_SetWindowSize(window, cast(int)(value.x*sFactor), cast(int)(value.y*sFactor));
}

private
vec2i SDL_GetWindowPositionExt(SDL_Window* window) @nogc nothrow { // @suppress(dscanner.style.phobos_naming_convention)
    vec2i pos;
    cast(void)SDL_GetWindowPosition(window, &pos.vector[0], &pos.vector[1]);
    return pos;
}