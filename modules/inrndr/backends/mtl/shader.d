/**
    Metal Shader

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module mtl.shader;
import mtl.context;

import inmath;
import numem;
import nulib;
import foundation;
import objc;

public import inrndr.shader;
public import metal.library;

class MetalShader : Shader {
private:
@nogc:
    nstring source_;
    MTLLibrary library_;

    MTLFunction fragment_;
    MTLFunction vertex_;

public:

    /**
        Source code of the shader.
    */
    override @property string source() => source_[];

    /**
        Vertex function
    */
    @property MTLFunction vertex() => vertex_;

    /**
        Fragment function
    */
    @property MTLFunction fragment() => fragment_;

    /// Constructor
    this(MTLDevice device, string source) {
        this.source_ = source;
        
        // This is just used initially.
        NSString srcString = NSString.create(source_.ptr);
        scope(exit) srcString.release();

        NSError err;
        this.library_ = device.newLibrary(srcString, null, err);
        if (library_ is null)
            throw nogc_new!NuException(err.toString());

        this.vertex_ = library_.newFunctionWithName("vertex_main".ns());
        this.fragment_ = library_.newFunctionWithName("fragment_main".ns());
    }
}
