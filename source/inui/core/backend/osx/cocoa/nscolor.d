/**
    NSColor

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.cocoa.nscolor;

version(OSX):
import core.attribute : selector;
import foundation;
import objc;
import inmath.linalg;

/**
    Color System Effect
*/
enum NSColorSystemEffect : NSInteger {
    None,
    Pressed,
    DeepPressed,
    Disabled,
    Rollover,
}

/**
    Color class wrapping CoreGraphics colors.
*/
extern(Objective-C)
extern class NSColorSpace : NSObject {
@nogc nothrow:

    /**
        A calibrated or device-dependent RGB color space.
    */
    static @property NSColorSpace deviceRGBColorSpace();

    /**
        A device-independent RGB color space.
    */
    static @property NSColorSpace genericRGBColorSpace();
}

/**
    Color class wrapping CoreGraphics colors.
*/
extern(Objective-C)
extern class NSColor : NSObject {
@nogc nothrow:

    /**
        Window background color
    */
    static @property NSColor windowBackgroundColor();

    /**
        The accent color of controls decided by the user.
    */
    static @property NSColor controlAccentColor();

    /**
        The color to use for the flat surfaces of a control.
    */
    static @property NSColor controlColor();

    /**
        The color to use for the face of a selected control.
    */
    static @property NSColor selectedControlColor();

    /**
        The color to use for the background of selected text.
    */
    static @property NSColor selectedTextBackgroundColor();

    /**
        The color to use for text.
    */
    static @property NSColor textColor();

    /**
        The color to use for links.
    */
    static @property NSColor linkColor();

    /**
        The color to use for text on controls.
    */
    static @property NSColor controlTextColor();

    /**
        The color to use for text on disabled controls.
    */
    static @property NSColor disabledControlTextColor();

    /**
        A color object whose grayscale and alpha values are both 0.0.
    */
    static @property NSColor clearColor();

    /**
        Window background color
    */
    static @property NSColor whiteWithAlpha(float white, float alpha) @selector("colorWithWhite:alpha:");

    /**
        The number of components in the color.
    */
    @property NSInteger numberOfComponents();

    /**
        Gets the components in the color
    */
    extern(D) final @property vec4 components() {
        NSColor converted = this.withColorSpace(NSColorSpace.deviceRGBColorSpace);
        double[4] colors = [0, 0, 0, 1];

        converted.getComponents(colors.ptr);
        return vec4(colors[0], colors[1], colors[2], colors[3]);
    }

    /**
        Returns the given color with the given alpha.
    */
    NSColor withAlpha(double alpha) @selector("colorWithAlphaComponent:");

    /**
        Gets the color with a system effect.
    */
    NSColor withSystemEffect(NSColorSystemEffect effect) @selector("colorWithSystemEffect:");

    /**
        Creates a new color object representing the color of the current color object in the specified color space.
    */
    NSColor withColorSpace(NSColorSpace colorSpace) @selector("colorUsingColorSpace:");

    /**
        Gets the colors in the NSColor
    */
    void getComponents(double* colors) @selector("getComponents:");
}
