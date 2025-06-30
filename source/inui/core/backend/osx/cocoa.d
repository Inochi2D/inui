/**
    Cocoa Bindings

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.cocoa;
import core.attribute : selector;
import foundation;
version(OSX):

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

alias NSAppearanceName = const(NSString);
extern(C) extern __gshared NSAppearanceName NSAppearanceNameAqua;
extern(C) extern __gshared NSAppearanceName NSAppearanceNameDarkAqua;
extern(C) extern __gshared NSAppearanceName NSAppearanceNameVibrantLight;
extern(C) extern __gshared NSAppearanceName NSAppearanceNameVibrantDark;

extern(Objective-C)
extern class NSResponder : NSObject { }

/**
    Rectangle.
*/
struct CGRect {
    double x;
    double y;
    double width;
    double height;
}

/**
    Point
*/
struct CGPoint {
    double x;
    double y;
}

extern(Objective-C)
extern class NSColor : NSObject {
@nogc:

    /**
        Window background color
    */
    static @property NSColor windowBackgroundColor();

    /**
        Window background color
    */
    static @property NSColor whiteWithAlpha(float white, float alpha) @selector("colorWithWhite:alpha:");

    /**
        Returns the given color with the given alpha.
    */
    NSColor withAlpha(double alpha) @selector("colorWithAlphaComponent:");
}

extern(Objective-C)
extern class NSAppearance : NSObject {
@nogc:

    /**
        Creates an appearance from its name.
    */
    static NSAppearance create(NSAppearanceName name) @selector("appearanceNamed:");

    /**
        Gets the current drawing appearance.
    */
    static @property NSAppearance currentDrawingAppearance();
    
    /**
        Whether the appearance allows vibrancy.
    */
    static @property bool allowsVibrancy();
    
    /**
        The name of the appearance.
    */
    static @property NSAppearanceName name();

    /**
        Selects the best appearance from a list.
    */
    NSAppearanceName bestMatchFromAppearancesWithNames(NSArray!NSString names) @selector("bestMatchFromAppearancesWithNames:");
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

extern(Objective-C)
extern class NSToolbar : NSResponder {
@nogc:
    
    /**
        Allocates a new NSVisualEffectView instance.
    */
    override static NSToolbar alloc();
    
    /**
        Initializes the NSVisualEffectView instance.
    */
    override NSToolbar init();
    
    /**
        Whether to show a baseline seperator.
    */
    @property bool showsBaselineSeparator();
    @property void showsBaselineSeparator(bool value);
}

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
        The backing layer.
    */
    @property CALayer layer();
    
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
}

/**
    NSStackView interface.
*/
extern(Objective-C)
extern class NSStackView : NSView {

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
    NSLayoutConstraint interface.
*/
extern(Objective-C)
extern class NSLayoutConstraint : NSObject {
@nogc:

    /**
        Whether the visual effect view is emphasized.
    */
    @property bool isActive();
    @property void isActive(bool value);
}

/**
    NSLayoutAnchor interface.
*/
extern(Objective-C)
extern class NSLayoutAnchor : NSObject {
@nogc:

    /**
        Gets a constraint that is the same as a given anchor.
    */
    NSLayoutConstraint constraintEqualToAnchor(NSLayoutAnchor anchor);

    /**
        Gets a constraint that is the same as a given anchor.
    */
    NSLayoutConstraint constraintGreaterThanOrEqualToAnchor(NSLayoutAnchor anchor);
}

/**
    NSLayoutAnchor interface.
*/
extern(Objective-C)
extern class NSLayoutXAxisAnchor : NSLayoutAnchor {
@nogc:

}

/**
    NSLayoutAnchor interface.
*/
extern(Objective-C)
extern class NSLayoutYAxisAnchor : NSLayoutAnchor {
@nogc:

}

/**
    NSLayoutGuide interface.
*/
extern(Objective-C)
extern class NSLayoutGuide : NSObject {
@nogc:
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
}

/**
    CALayer interface.
*/
extern(Objective-C)
extern class CALayer : NSObject {
@nogc:

    /**
        The radius to use when drawing rounded corners for the layer’s 
        background.
    */
    @property double cornerRadius();
    @property void cornerRadius(double value);
}

