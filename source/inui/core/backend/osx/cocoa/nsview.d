/**
    NSView

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.cocoa.nsview;
import inui.core.backend.osx.cocoa.nscolor;
import inui.core.backend.osx.cocoa.nsappearance;
import inui.core.backend.osx.cocoa.nslayout;
import inui.core.backend.osx.cocoa.math;

version(OSX):
import core.attribute : selector;
import foundation;

/**
    Auto Resize Mask Option bitflags.
*/
enum NSAutoresizingMaskOptions : int {
    NotSizable			=  0,
    MinXMargin			=  1,
    WidthSizable		=  2,
    MaxXMargin			=  4,
    MinYMargin			=  8,
    HeightSizable		= 16,
    MaxYMargin			= 32,
    All                 = 64-1
}

extern(Objective-C)
extern class NSResponder : NSObject { }

/**
    NSView interface.
*/
extern(Objective-C)
extern class NSView : NSResponder {
@nogc:

    /**
        Allocates a new NSView instance.
    */
    override static NSView alloc();
    
    /**
        Initializes a NSView instance.
    */
    NSView initWithFrame(CGRect frame);

    /**
        The superview
    */
    @property NSView superview();

    /**
        The frame of the view.
    */
    @property CGRect frame();
    @property void frame(CGRect value);

    /**
        The bounds of the view.
    */
    @property CGRect bounds();
    @property void bounds(CGRect value);

    /**
        The superview
    */
    @property NSArray!NSView subviews();
    
    /**
        Whether the view allows vibrancy.
    */
    @property bool allowsVibrancy();
    
    /**
        Whether the view wants to be redrawn.
    */
    @property bool needsDisplay();
    @property void needsDisplay(bool value);
    
    /**
        Whether the view wants layering.
    */
    @property bool wantsLayer();
    @property void wantsLayer(bool value);

    /**
        The alpha value.
    */
    @property double alphaValue();
    @property void alphaValue(double value);

    /**
        Background color
    */
    @property NSColor backgroundColor();
    @property void backgroundColor(NSColor value);

    /**
        The bounds of the view.
    */
    @property CGRect bounds();
    @property void bounds(CGRect value);

    /**
        The appearance to apply.
    */
    @property NSAppearance appearance();
    @property void appearance(NSAppearance value);

    /**
        The current constraints of the view.
    */
    @property NSArray!NSLayoutConstraint constraints();

    /**
        Whether the view requires constraint based layouting.
    */
    @property bool requiresConstraintBasedLayout();
    @property void requiresConstraintBasedLayout(bool value);

    /**
        Whether the view resizes its subviews.
    */
    @property bool autoresizesSubviews();
    @property void autoresizesSubviews(bool value);

    /**
        Whether the view needs layouting.
    */
    @property bool needsLayout();
    @property void needsLayout(bool value);

    /**
        Whether the view needs to update its constraints.
    */
    @property bool needsUpdateConstraints();
    @property void needsUpdateConstraints(bool value);

    /**
        The view's resizing mask.
    */
    @property NSAutoresizingMaskOptions autoresizingMask();
    @property void autoresizingMask(NSAutoresizingMaskOptions value);

    @property NSLayoutGuide layoutMarginsGuide();

    @property NSLayoutAnchor leftAnchor();
    @property NSLayoutAnchor rightAnchor();
    @property NSLayoutAnchor topAnchor();
    @property NSLayoutAnchor bottomAnchor();

    @property NSLayoutAnchor widthAnchor();
    @property NSLayoutAnchor heightAnchor();

    @property NSLayoutAnchor leadingAnchor();
    @property NSLayoutAnchor trailingAnchor();
    
    @property NSLayoutAnchor centerXAnchor();
    @property NSLayoutAnchor centerYAnchor();
    
    /**
        Adds a layout guide to the view.
    */
    void addLayoutGuide(NSObject guide) @selector("addLayoutGuide:");

    /**
        Adds subview to the view.
    */
    void addSubview(NSView subview) @selector("addSubview:");

    /**
        Removes constraints.
    */
    void removeConstraints(NSArray!NSLayoutConstraint constraints);

    /**
        Lays out the view.
    */
    void layout();

    /**
        Updates the view’s content by modifying its underlying layer.
    */
    void updateLayer();
}

enum NSVisualEffectMaterial : int {
    Titlebar = 3,
    Selection = 4,
    Menu = 5,
    Popover = 6,
    Sidebar = 7,
    HeaderView = 10,
    Sheet = 11,
    WindowBackground = 12,
    HUDWindow = 13,
    FullScreenUI = 15,
    ToolTip = 17,
    ContentBackground = 18,
    UnderWindowBackground = 21,
    UnderPageBackground = 22,
}

enum NSVisualEffectBlendingMode : int {
    BehindWindow,
    WithinWindow,
}

enum NSVisualEffectState : int {
    FollowsWindowActiveState,
    Active,
    Inactive,
}

/**
    NSVisualEffectView interface.
*/
extern(Objective-C)
extern class NSVisualEffectView : NSView {
@nogc:
    
    /**
        Allocates a new NSVisualEffectView instance.
    */
    override static NSVisualEffectView alloc();
    
    /**
        Initializes the NSVisualEffectView instance.
    */
    override NSVisualEffectView init();
    
    /**
        Initializes a NSVisualEffectView instance.
    */
    override NSVisualEffectView initWithFrame(CGRect frame);

    /**
        The material of the visual effect view.
    */
    @property NSVisualEffectMaterial material();
    @property void material(NSVisualEffectMaterial value);
    
    /**
        The state of the visual effect view.
    */
    @property NSVisualEffectState state();
    @property void state(NSVisualEffectState value);

    /**
        The blending mode of the visual effect view.
    */
    @property NSVisualEffectBlendingMode blendingMode();
    @property void blendingMode(NSVisualEffectBlendingMode value);

    /**
        Whether the visual effect view is emphasized.
    */
    @property bool isEmphasized();
    @property void isEmphasized(bool value);
}

/**
    NSGlassEffectView interface.
*/
extern(Objective-C)
extern class NSGlassEffectView : NSView {
@nogc:
    
    /**
        Allocates a new NSGlassEffectView instance.
    */
    override static NSGlassEffectView alloc();
    
    /**
        Initializes the NSGlassEffectView instance.
    */
    override NSGlassEffectView init();
    
    /**
        Initializes a NSGlassEffectView instance.
    */
    override NSGlassEffectView initWithFrame(CGRect frame);

    /**
        The view to be embedded in glass.
    */
    @property NSView contentView();
    @property void contentView(NSView value);

    /**
        The amount of curvature for all corners of the glass.
    */
    @property double cornerRadius();
    @property void cornerRadius(double value);

    /**
        The color to tint the glass effect view with.
    */
    @property NSColor tintColor();
    @property void tintColor(NSColor value);
}

/**
    NSBackgroundExtensionView interface.
*/
extern(Objective-C)
extern class NSBackgroundExtensionView : NSView {
@nogc:
    
    /**
        Allocates a new NSBackgroundExtensionView instance.
    */
    override static NSBackgroundExtensionView alloc();
    
    /**
        Initializes the NSBackgroundExtensionView instance.
    */
    override NSBackgroundExtensionView init();
    
    /**
        Initializes a NSBackgroundExtensionView instance.
    */
    override NSBackgroundExtensionView initWithFrame(CGRect frame);

    /**
        Whether content is automatically placed within the view.
    */
    @property bool automaticallyPlacesContentView();
    @property void automaticallyPlacesContentView(bool value);

    /**
        The view to be embedded in glass.
    */
    @property NSView contentView();
    @property void contentView(NSView value);
}
