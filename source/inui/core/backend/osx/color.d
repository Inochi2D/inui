/**
    OSX Accent Color

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.color;

version(OSX):

import inui.core.backend.osx.cocoa;
import inui.core.window;
import inmath.linalg;
import foundation;
import numem;
import objc;

/**
    Gets the accent color for cocoa.
*/
vec4 uiCocoaGetColor(NativeWindow window, ColorStyle style) @nogc {
    if (!window)
        return vec4.init;

    NSWindow whndl = cast(NSWindow)window.nativeHandle();
    if (!whndl)
        return vec4.init;
    
    NSColor color = assumeNoGC((NSWindow whndl, ColorStyle style) {
        NSAppearance.currentAppearance = NSApp.effectiveAppearance;
        final switch(style) {
            case ColorStyle.none:
                return NSColor.controlColor;
            
            case ColorStyle.pressed:
                return NSColor.controlColor.withSystemEffect(NSColorSystemEffect.Pressed);
            
            case ColorStyle.hovered:
                return NSColor.controlColor.withSystemEffect(NSColorSystemEffect.Rollover);

            case ColorStyle.selected:
                return NSColor.controlAccentColor;

            case ColorStyle.accent:
                return NSColor.controlAccentColor;
            
            case ColorStyle.accentPressed:
                return NSColor.controlAccentColor.withSystemEffect(NSColorSystemEffect.Pressed);
            
            case ColorStyle.accentHovered:
                return NSColor.controlAccentColor.withSystemEffect(NSColorSystemEffect.Rollover);
            
            case ColorStyle.disabled:
                return NSColor.controlColor.withSystemEffect(NSColorSystemEffect.Disabled);
            
            case ColorStyle.background:
                return NSColor.controlColor.withSystemEffect(NSColorSystemEffect.Pressed);
            
            case ColorStyle.backgroundHovered:
                return NSColor.controlColor.withSystemEffect(NSColorSystemEffect.Pressed);
            
            case ColorStyle.link:
                return NSColor.linkColor;
            
            case ColorStyle.text:
                return NSColor.controlTextColor;
            
            case ColorStyle.textDisabled:
                return NSColor.disabledControlTextColor;
            
            case ColorStyle.textSelected:
                return NSColor.selectedTextBackgroundColor;
            
            case ColorStyle.tab:
                return NSColor.controlColor.withSystemEffect(NSColorSystemEffect.Pressed);
            
            case ColorStyle.tabActive:
                return NSColor.controlColor.withSystemEffect(NSColorSystemEffect.None);
            
            case ColorStyle.titlebar:
                return NSColor.windowBackgroundColor;
            
            case ColorStyle.titlebarActive:
                return NSColor.windowBackgroundColor;
        }
    }, whndl, style);
    return color ? color.components : vec4.init;
}