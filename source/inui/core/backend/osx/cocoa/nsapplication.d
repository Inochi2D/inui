/**
    NSApplication

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.cocoa.nsapplication;
import inui.core.backend.osx.cocoa.nsappearance;
import inui.core.backend.osx.cocoa.nscolor;
import inui.core.backend.osx.cocoa.nsview;
import inui.core.backend.osx.cocoa.math;

version(OSX):
import core.attribute : selector;
import foundation;

extern(C) extern __gshared NSApplication NSApp;

/**
    NSApplication interface.
*/
extern(Objective-C)
extern class NSApplication : NSResponder {
@nogc:

    /**
        Shared application instance.
    */
    static @property NSApplication sharedApplication();

    /**
        The appearance to apply.
    */
    @property NSAppearance appearance();
    @property void appearance(NSAppearance value);

    /**
        The effective appearance of the window.
    */
    @property NSAppearance effectiveAppearance();
}