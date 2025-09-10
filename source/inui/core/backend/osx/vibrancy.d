/**
    OSX Vibrancy

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.vibrancy;
version(OSX):

import inui.core.backend.osx.cocoa;
import inui.core.window;

import inmath.linalg;
import foundation;
import objc;

__gshared Class _sdlViewClass;
void uiCocoaSetupVibrancy(NativeWindow window) @nogc {
    NSWindow whndl = cast(NSWindow)window.nativeHandle();
    whndl.toolbarStyle = NSWindowToolbarStyle.UnifiedCompact;
    whndl.toolbar = NSToolbar.alloc.init;
    whndl.hasShadow = true;

    auto sdlview = whndl.contentView;

    auto crect = whndl.contentRectForFrameRect(whndl.frame);

    NSView rootview = NSView.alloc.initWithFrame(crect);
    rootview.backgroundColor = NSColor.clearColor;
    sdlview.backgroundColor = NSColor.clearColor;

    NSVisualEffectView effectView = NSVisualEffectView.alloc.initWithFrame(rootview.frame);
    effectView.material = NSVisualEffectMaterial.WindowBackground;
    effectView.blendingMode = NSVisualEffectBlendingMode.BehindWindow;
    effectView.state = NSVisualEffectState.Active;
    effectView.isEmphasized = false;
    effectView.alphaValue = 1;

    whndl.contentView = rootview;
    rootview.addSubview(effectView);
    effectView.frame = rootview.frame;
    rootview.addSubview(sdlview);
    sdlview.frame = rootview.frame;
    
    rootview.autoresizesSubviews = true;
    rootview.addLayoutGuide(whndl.contentLayoutGuide);

    effectView.autoresizingMask = NSAutoresizingMaskOptions.All;
    effectView.heightAnchor.constraintEqualToAnchor(rootview.heightAnchor).isActive = true;
    effectView.topAnchor.constraintGreaterThanOrEqualToAnchor(rootview.topAnchor).isActive = true;
    _sdlViewClass = Class.lookup("SDL3View");
}

recti uiCocoaGetSafeArea(NativeWindow window) @nogc {
    if (!window)
        return recti(0, 0, 0, 0);

    NSWindow whndl = cast(NSWindow)window.nativeHandle();
    if (!whndl)
        return recti(0, 0, 0, 0);

    auto safeArea = whndl.contentLayoutRect;
    return recti(cast(int)safeArea.x, cast(int)safeArea.y, cast(int)safeArea.width, cast(int)safeArea.height);
}

void uiCocoaUpdateWindow(NativeWindow window) @nogc {
    if (!window)
        return;

    NSWindow whndl = cast(NSWindow)window.nativeHandle();
    if (!whndl)
        return;
    
    auto rootview = whndl.contentView;
    NSView sdlView = rootview.findSDLView();

    sdlView.layer.isOpaque = false;
    sdlView.layer.backgroundColor = CGColorGetConstantColor(kCGColorClear);
    sdlView.subviews[0].layer.isOpaque = false;
}

bool uiCocoaSetVibrancy(NativeWindow window, SystemVibrancy vibrancy) @nogc {
    if (!window)
        return false;

    NSWindow whndl = cast(NSWindow)window.nativeHandle();
    if (!whndl)
        return false;
        
    auto rootview = whndl.contentView;
    NSVisualEffectView effectView = rootview.findVisualEffectView();
    NSView sdlView = rootview.findSDLView();

    bool wantsVibrancy = vibrancy != SystemVibrancy.none;
    whndl.styleMask = whndl.styleMask | NSWindowStyleMask.FullSizeContentView;
    whndl.isOpaque = !wantsVibrancy;
    whndl.titlebarAppearsTransparent = true;
    if (effectView && sdlView) {
        
        final switch(vibrancy) {
            case SystemVibrancy.none:
                effectView.state = NSVisualEffectState.Inactive;
                break;
            
            case SystemVibrancy.normal:
                effectView.material = NSVisualEffectMaterial.UnderWindowBackground;
                effectView.blendingMode = NSVisualEffectBlendingMode.BehindWindow;
                effectView.state = NSVisualEffectState.Active;
                break;
            
            case SystemVibrancy.vivid:
                effectView.material = NSVisualEffectMaterial.HUDWindow;
                effectView.blendingMode = NSVisualEffectBlendingMode.BehindWindow;
                effectView.state = NSVisualEffectState.Active;
                effectView.isEmphasized = true;
                break;
        }
    }
    return true;
}

private
NSAppearance selectAppearanceFor(NativeWindow window, bool wantsVibrancy) @nogc {
    return window.systemTheme == SystemTheme.dark ? 
        NSAppearance.create(wantsVibrancy ? NSAppearanceNameVibrantDark  : NSAppearanceNameDarkAqua) :
        NSAppearance.create(wantsVibrancy ? NSAppearanceNameVibrantLight : NSAppearanceNameAqua);
}

private
NSVisualEffectView findVisualEffectView(NSView start) @nogc {
    if (cast(NSVisualEffectView)start)
        return cast(NSVisualEffectView)start;

    if (auto contents = start.subviews) {
        foreach(i; 0..contents.length) {
            if (auto view = cast(NSVisualEffectView)contents[i])
                return view.findVisualEffectView();
        }
    }

    return null;
}

private
NSView findSDLView(NSView start) @nogc {
    if (start.isClassOf(_sdlViewClass))
        return start;

    if (auto contents = start.subviews) {
        foreach(i; 0..contents.length) {
            if (contents[i].isClassOf(_sdlViewClass))
                return contents[i];
        }
    }

    return null;
}
