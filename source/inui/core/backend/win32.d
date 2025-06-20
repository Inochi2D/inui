/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.win32;
version(Windows):

import sdl.loadso;
import core.sys.windows.windows;
import core.sys.windows.winuser;
import inui.core.window;

// Windows 8.1+ DPI awareness context enum
enum DPIAwarenessContext : ptrdiff_t { 
    DPI_AWARENESS_CONTEXT_UNAWARE = -1,
    DPI_AWARENESS_CONTEXT_SYSTEM_AWARE = -2,
    DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE = -3,
    DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4
}

// Windows 8.1+ DPI awareness enum
enum ProcessDPIAwareness { 
    DPI_AWARENESS_INVALID           = -1,
    DPI_AWARENESS_UNAWARE           = 0,
    DPI_AWARENESS_SYSTEM_AWARE      = 1,
    DPI_AWARENESS_PER_MONITOR_AWARE = 2
}

// DWM Window Attributes
enum DwmWindowAttribute : uint {
    DWMWA_NCRENDERING_ENABLED,
    DWMWA_NCRENDERING_POLICY,
    DWMWA_TRANSITIONS_FORCEDISABLED,
    DWMWA_ALLOW_NCPAINT,
    DWMWA_CAPTION_BUTTON_BOUNDS,
    DWMWA_NONCLIENT_RTL_LAYOUT,
    DWMWA_FORCE_ICONIC_REPRESENTATION,
    DWMWA_FLIP3D_POLICY,
    DWMWA_EXTENDED_FRAME_BOUNDS,
    DWMWA_HAS_ICONIC_BITMAP,
    DWMWA_DISALLOW_PEEK,
    DWMWA_EXCLUDED_FROM_PEEK,
    DWMWA_CLOAK,
    DWMWA_CLOAKED,
    DWMWA_FREEZE_REPRESENTATION,
    DWMWA_PASSIVE_UPDATE_MODE,
    DWMWA_USE_HOSTBACKDROPBRUSH,
    DWMWA_USE_IMMERSIVE_DARK_MODE = 20,
    DWMWA_WINDOW_CORNER_PREFERENCE = 33,
    DWMWA_BORDER_COLOR,
    DWMWA_CAPTION_COLOR,
    DWMWA_TEXT_COLOR,
    DWMWA_VISIBLE_FRAME_BORDER_THICKNESS,
    DWMWA_SYSTEMBACKDROP_TYPE,
    DWMWA_LAST
}

enum DwmSystemBackdropType {
  DWMSBT_AUTO,
  DWMSBT_NONE,
  DWMSBT_MAINWINDOW,
  DWMSBT_TRANSIENTWINDOW,
  DWMSBT_TABBEDWINDOW
}

struct DwmMargins {
    int left;
    int right;
    int top;
    int bottom;
}

struct DwmBlurBehind {
    uint flags;
    bool enable;
    HRGN region;
    bool transitionOnMaximized;
}

void uiWin32Shutdown() @nogc {

    // Unload the DLLs
    if (userDLL) SDL_UnloadObject(userDLL);
    if (shcoreDLL) SDL_UnloadObject(shcoreDLL);
    if (dwmapiDLL) SDL_UnloadObject(dwmapiDLL);

}

void uiWin32Init() @nogc {
    userDLL = SDL_LoadObject("USER32.DLL");
    shcoreDLL = SDL_LoadObject("SHCORE.DLL");
    dwmapiDLL = SDL_LoadObject("dwmapi.dll");

    if (shcoreDLL) {
        dpiAwareFunc81 = cast(typeof(dpiAwareFunc81)) SDL_LoadFunction(shcoreDLL, "SetProcessDpiAwareness");
    }

    if (userDLL) {
        dpiAwareFunc8 = cast(typeof(dpiAwareFunc8)) SDL_LoadFunction(userDLL, "SetProcessDPIAware");
        dpiAwareFuncCtx10 = cast(typeof(dpiAwareFuncCtx10)) SDL_LoadFunction(userDLL, "SetProcessDpiAwarenessContext");
        enableNonClientDpiScalingFunc = cast(typeof(enableNonClientDpiScalingFunc)) SDL_LoadFunction(userDLL, "EnableNonClientDpiScaling");
    }

    if (dwmapiDLL) {
        dwmExtendFrameIntoClientAreaFunc = 
            cast(typeof(dwmExtendFrameIntoClientAreaFunc))SDL_LoadFunction(dwmapiDLL, "DwmExtendFrameIntoClientArea");
        
        dwmSetWindowAttributeFunc =
            cast(typeof(dwmSetWindowAttributeFunc))SDL_LoadFunction(dwmapiDLL, "DwmSetWindowAttribute");
        
        dwmEnableBlurBehindWindowFunc =
            cast(typeof(dwmEnableBlurBehindWindowFunc))SDL_LoadFunction(dwmapiDLL, "DwmEnableBlurBehindWindow");
    }

    // This is process-wide.
    uiSetWin32DPIAwareness();
}

void uiSetWin32DPIAwareness() @nogc {

    if (dpiAwareFuncCtx10) {
        if (!dpiAwareFuncCtx10(DPIAwarenessContext.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)) {
            cast(void)dpiAwareFuncCtx10(DPIAwarenessContext.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE);
        }
    } else if (dpiAwareFunc81) {
        cast(void)dpiAwareFunc81(ProcessDPIAwareness.DPI_AWARENESS_PER_MONITOR_AWARE);
    } else if (dpiAwareFunc8) {
        cast(void)dpiAwareFunc8();
    }      
}

void uiWin32SetupDPIFor(NativeWindow window) @nogc {

    // Try to make non-client-area scaled.
    if (enableNonClientDpiScalingFunc)
        cast(void)enableNonClientDpiScalingFunc(window.nativeHandle);
}

bool uiWin32SetVibrancy(NativeWindow window, SystemVibrancy vibrancy) @nogc {
    
    // Enable or disable blur-behind
    if (dwmEnableBlurBehindWindowFunc) {
        DwmBlurBehind blurBehind;
        blurBehind.enable = vibrancy != SystemVibrancy.none;
        dwmEnableBlurBehindWindowFunc(window.nativeHandle, &blurBehind);
    }

    // Extend frame into entire view, or disable it.
    if (dwmExtendFrameIntoClientAreaFunc) {
        DwmMargins margins = vibrancy > SystemVibrancy.none ? 
            DwmMargins(-1, -1, -1, -1) :
            DwmMargins(0, 0, 0, 0);
        cast(void)dwmExtendFrameIntoClientAreaFunc(window.nativeHandle, &margins);
    }

    // Try to enable acrylic on Windows 11+, if requested.
    if (dwmSetWindowAttributeFunc) {
        DwmSystemBackdropType backdrop;
        final switch(vibrancy) {
            case SystemVibrancy.none:
                backdrop = DwmSystemBackdropType.DWMSBT_NONE;
                break;
        
            case SystemVibrancy.normal:
                backdrop = DwmSystemBackdropType.DWMSBT_MAINWINDOW;
                break;
        
            case SystemVibrancy.vivid:
                backdrop =DwmSystemBackdropType.DWMSBT_TABBEDWINDOW;
                break;
        }
        dwmSetWindowAttributeFunc(window.nativeHandle, DwmWindowAttribute.DWMWA_SYSTEMBACKDROP_TYPE, &backdrop, backdrop.sizeof);
    }

    return true;
}

private __gshared {
    SDL_SharedObject* userDLL;
    SDL_SharedObject* shcoreDLL;
    SDL_SharedObject* dwmapiDLL;

    extern(Windows) @nogc bool function() dpiAwareFunc8;
    extern(Windows) @nogc HRESULT function(ProcessDPIAwareness) dpiAwareFunc81;
    extern(Windows) @nogc bool function(DPIAwarenessContext) dpiAwareFuncCtx10;
    extern(Windows) @nogc bool function(HWND) enableNonClientDpiScalingFunc;
    extern(Windows) @nogc HRESULT function(HWND, const(DwmMargins)*) dwmExtendFrameIntoClientAreaFunc;
    extern(Windows) @nogc HRESULT function(HWND, DwmWindowAttribute, void*, uint) dwmSetWindowAttributeFunc;
    extern(Windows) @nogc HRESULT function(HWND, const(DwmBlurBehind)*) dwmEnableBlurBehindWindowFunc;
}