/**
    NSLayout

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.cocoa.nslayout;

version(OSX):
import core.attribute : selector;
import foundation;

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

