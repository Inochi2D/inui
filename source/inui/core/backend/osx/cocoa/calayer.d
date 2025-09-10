module inui.core.backend.osx.cocoa.calayer;

version(OSX):
import core.attribute : selector;
public import coregraphics.cgcolor;
import corefoundation.cfstring;
import foundation;
import objc;

/// Clear color
extern(C) extern __gshared CFStringRef kCGColorClear;

/**
    Appearance settings
*/
extern(Objective-C)
extern class CALayer : NSObject {
@nogc:
    
    /**
        Opacity of the layer.
    */
    @property float opacity();
    @property void opacity(float value);
    
    /**
        Whether the layer is opaque
    */
    @property bool isOpaque();
    @property void isOpaque(bool value);
    
    /**
        Opacity of the layer.
    */
    @property CGColorRef backgroundColor();
    @property void backgroundColor(CGColorRef value);
}