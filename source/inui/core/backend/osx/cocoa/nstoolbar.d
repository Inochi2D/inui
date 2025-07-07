/**
    NSToolbar

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.cocoa.nstoolbar;
import inui.core.backend.osx.cocoa.nsview;
import inui.core.backend.osx.cocoa.math;

version(OSX):
import core.attribute : selector;
import foundation;

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

