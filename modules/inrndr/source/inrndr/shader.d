/**
    Inui Shader

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inrndr.shader;
import inrndr.context;
import inmath;
import numem;

/**
    A program which is executed on the graphics processing unit.
*/
abstract
class Shader : NuRefCounted {
public:
@nogc:

    /**
        Source code of the shader.
    */
    abstract @property string source();
}