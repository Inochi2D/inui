/**
    OpenGL Shader

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module gl.shader;
import gl.context;
import numem;
import nulib;

public import inrndr.shader;

class GLShader : Shader {
private:
@nogc:
    nstring source_;
    GLint program;

public:

    /**
        Source code of the shader.
    */
    override @property string source() => source_[];

}