module inui.core.backend.osx.cocoa.nsappearance;

version(OSX):
import core.attribute : selector;
import foundation;
import objc;

alias NSAppearanceName = const(NSString);
extern(C) extern __gshared NSAppearanceName NSAppearanceNameAqua;
extern(C) extern __gshared NSAppearanceName NSAppearanceNameDarkAqua;
extern(C) extern __gshared NSAppearanceName NSAppearanceNameVibrantLight;
extern(C) extern __gshared NSAppearanceName NSAppearanceNameVibrantDark;

/**
    Appearance settings
*/
extern(Objective-C)
extern class NSAppearance : NSObject {
@nogc:

    /**
        Creates an appearance from its name.
    */
    static NSAppearance create(NSAppearanceName name) @selector("appearanceNamed:");

    /**
        The current drawing appearance.
    */
    static @property NSAppearance currentDrawingAppearance();

    /**
        The current appearance.
    */
    static @property NSAppearance currentAppearance();
    static @property void currentAppearance(NSAppearance value);
    
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

    /**
        Sets the appearance to be the active drawing appearance and perform the specified block.
    */
    void performAsCurrentDrawingAppearance(Block!(void)* block) @selector("performAsCurrentDrawingAppearance:");
}