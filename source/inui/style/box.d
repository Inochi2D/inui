
/**
    Box Model

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.style.box;
import inmath.linalg;

/**
    Container for box model variables.
*/
struct BoxModel {
@nogc:

    /**
        The base "auto" size of the box
    */
    vec2 contentSize = vec2.zero;

    /**
        Requested size of the box.
    */
    vec2 requestedSize = vec2.zero;

    /**
        The computed size of the box.
    */
    vec2 computedSize = vec2.zero;

    /**
        Margins of the box
    */
    vec4 margins = vec4.zero;

    /**
        Total margins of the box.
    */
    @property vec2 totalMargins() => vec2((margins.x + margins.z), (margins.y + margins.w));

    /**
        Padding of the box
    */
    vec4 padding = vec4.zero;

    /**
        Total padding of the box.
    */
    @property vec2 totalPadding() => vec2((padding.x + padding.z), (padding.y + padding.w));

    /**
        Total size offset
    */
    @property vec2 totalOffset() => totalMargins + totalPadding;

    /**
        Radius or the border
    */
    vec4 borderRadius = vec4.zero;

    /**
        Alignment of the content
    */
    Alignment alignContent;

    /**
        Alignment of text
    */
    Alignment alignSelf;
}

/**
    Alignment for controls.
*/
enum Alignment {

    /**
        Inherit alignment.
    */
    inherit,

    /**
        Left alignment.
    */
    left,

    /**
        Center alignment
    */
    center,

    /**
        Right hand size alignment.
    */
    right
}

Alignment alignmentFromString(string alignment) {
    switch(alignment) {
        case "left":
            return Alignment.left;
        
        case "center":
            return Alignment.center;
        
        case "right":
            return Alignment.right;
        
        default:
            return Alignment.inherit;
    }
}
