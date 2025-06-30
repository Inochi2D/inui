/**
    DWM Interface

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.win32.dwm;

version(Windows):

import sdl.loadso;
import core.sys.windows.windows;
import core.sys.windows.winuser;

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
    if (dwmapiDLL) SDL_UnloadObject(dwmapiDLL);

}

void uiWin32Init() @nogc {
    dwmapiDLL = SDL_LoadObject("dwmapi.dll");

    if (dwmapiDLL) {
        dwmExtendFrameIntoClientArea = 
            cast(typeof(dwmExtendFrameIntoClientArea))SDL_LoadFunction(dwmapiDLL, "DwmExtendFrameIntoClientArea");
        
        dwmSetWindowAttribute =
            cast(typeof(dwmSetWindowAttribute))SDL_LoadFunction(dwmapiDLL, "DwmSetWindowAttribute");
        
        dwmEnableBlurBehindWindow =
            cast(typeof(dwmEnableBlurBehindWindow))SDL_LoadFunction(dwmapiDLL, "DwmEnableBlurBehindWindow");
    }
}

__gshared {
    private SDL_SharedObject* dwmapiDLL;

    extern(Windows) @nogc nothrow HRESULT function(HWND, const(DwmMargins)*) dwmExtendFrameIntoClientArea;
    extern(Windows) @nogc nothrow HRESULT function(HWND, DwmWindowAttribute, void*, uint) dwmSetWindowAttribute;
    extern(Windows) @nogc nothrow HRESULT function(HWND, const(DwmBlurBehind)*) dwmEnableBlurBehindWindow;
}