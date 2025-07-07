/**
    NSWindow

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.cocoa.nswindow;
import inui.core.backend.osx.cocoa.nsappearance;
import inui.core.backend.osx.cocoa.nstoolbar;
import inui.core.backend.osx.cocoa.nslayout;
import inui.core.backend.osx.cocoa.nsview;
import inui.core.backend.osx.cocoa.nscolor;
import inui.core.backend.osx.cocoa.math;

version(OSX):
import core.attribute : selector;
import foundation;

enum NSWindowToolbarStyle : int {
    Automatic,
    Expanded,
    Preference,
    Unified,
    UnifiedCompact
}

enum NSTitlebarSeparatorStyle : int {
    Automatic,
    None,
    Line,
    Shadow
}

enum NSWindowStyleMask : int {
    Borderless = 0,
    Titled = 1 << 0,
    Closable = 1 << 1,
    Miniaturizable = 1 << 2,
    Resizable	= 1 << 3,
    UnifiedTitleAndToolbar = 1 << 12,
    FullScreen = 1 << 14,
    FullSizeContentView = 1 << 15,
    UtilityWindow = 1 << 4,
    DocModalWindow = 1 << 6,
    NonactivatingPanel = 1 << 7,
    HUDWindow = 1 << 13
}

extern(Objective-C)
extern class NSWindow : NSResponder {
@nogc:

    /**
        Title of the window.
    */
    @property NSString title();
    @property void title(NSString value);

    /**
        Subtitle of the window.
    */
    @property NSString subtitle();
    @property void subtitle(NSString value);

    /**
        The top-level view of the window.
    */
    @property NSView contentView();
    @property void contentView(NSView value);

    /**
        The frame of the window.
    */
    @property CGRect frame();
    @property void frame(CGRect value);

    /**
        Whether the titlebar appears transparent.
    */
    @property bool titlebarAppearsTransparent();
    @property void titlebarAppearsTransparent(bool value);

    /**
        The toolbar style.
    */
    @property NSToolbar toolbar();
    @property void toolbar(NSToolbar value);

    /**
        The toolbar style.
    */
    @property NSWindowToolbarStyle toolbarStyle();
    @property void toolbarStyle(NSWindowToolbarStyle value);

    /**
        The style of the titlebar seperator.
    */
    @property NSTitlebarSeparatorStyle titlebarSeparatorStyle();
    @property void titlebarSeparatorStyle(NSTitlebarSeparatorStyle value);

    /**
        Background color
    */
    @property NSColor backgroundColor();
    @property void backgroundColor(NSColor value);

    /**
        The appearance to apply.
    */
    @property NSAppearance appearance();
    @property void appearance(NSAppearance value);

    /**
        The effective appearance of the window.
    */
    @property NSAppearance effectiveAppearance();

    /**
        Whether the window is opaque.
    */
    @property bool isOpaque();
    @property void isOpaque(bool value);

    /**
        Whether the window has a shadow.
    */
    @property bool hasShadow();
    @property void hasShadow(bool value);

    /**
        The alpha value.
    */
    @property double alphaValue();
    @property void alphaValue(double value);

    /**
        The style mask.
    */
    @property NSWindowStyleMask styleMask();
    @property void styleMask(NSWindowStyleMask value);

    /**
        The content layout rectangle.
    */
    @property CGRect contentLayoutRect();

    /**
        The content layout guide.
    */
    @property NSLayoutGuide contentLayoutGuide();

    /**
        Invalidates the window's shadows.
    */
    void invalidateShadow() @selector("invalidateShadow");

    /**
        Creates a content rect from a frame rect.
    */
    CGRect contentRectForFrameRect(CGRect frame) @selector("contentRectForFrameRect:");
}