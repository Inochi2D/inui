/**
    Vibrancy

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.win32.vibrancy;
import inui.core.backend.win32.dwm;
import inui.core.window;

version(Windows):

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