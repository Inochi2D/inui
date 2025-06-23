/**
    Inui Shader Interface

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.shader;
import inui.core.render.gl;
import bindbc.opengl;
import nulib;

/**
    A shader
*/
class Shader : GLObject {
private:
@nogc:
    GLuint compileShader(GLenum type, string source) {
        const(char)* str = source.ptr;
        GLint len = cast(int)source.length;

        GLuint handle = glCreateShader(type);
        glShaderSource(handle, 1, &str, &len);
        glCompileShader(handle);

        // Get compilation status
        GLint status = 0, logLength = 0;
        glGetShaderiv(handle, GL_COMPILE_STATUS, &status);
        glGetShaderiv(handle, GL_INFO_LOG_LENGTH, &logLength);
        if (cast(GLboolean) status == GL_FALSE) {
            nstring buffer = nstring(logLength);
            if (logLength > 1) {
                import nulib.c.stdio : printf;
                glGetShaderInfoLog(handle, logLength, null, cast(GLchar*) buffer.ptr);
                printf("Failed compiling GLSL Shader!\n\nReason:\n%s", buffer.ptr);
            }
        }

        return handle;
    }

    GLuint createProgram(string vertex, string fragment) {
        GLuint vert = compileShader(GL_VERTEX_SHADER, vertex);
        GLuint frag = compileShader(GL_FRAGMENT_SHADER, fragment);

        GLuint handle = glCreateProgram();
        glAttachShader(handle, vert);
        glAttachShader(handle, frag);
        glLinkProgram(handle);

        // Get linkage status
        GLint status = 0, logLength = 0;
        glGetShaderiv(handle, GL_LINK_STATUS, &status);
        glGetShaderiv(handle, GL_INFO_LOG_LENGTH, &logLength);
        if (cast(GLboolean) status == GL_FALSE) {
            nstring buffer = nstring(logLength);
            if (logLength > 1) {
                import nulib.c.stdio : printf;
                glGetShaderInfoLog(handle, logLength, null, cast(GLchar*) buffer.ptr);
                printf("Failed linking GLSL Shaders!\n\nReason:\n%s", buffer.ptr);   
            }
        }
        
        // Not needed after linking is completed.
        glDeleteShader(vert);
        glDeleteShader(frag);

        return handle;
    }

public:

    /**
        Destructor
    */
    ~this() {
        glDeleteProgram(id);
    }

    /**
        Constructor
    */
    this(GLContext context, string vertex, string fragment) {
        context.makeCurrent();
        super(context, this.createProgram(vertex, fragment));
    }

    /**
        Gets the location of a uniform.

        Params:
            name = Name of the uniform

        Returns:
            A positive binding number on success,
            $(D -1) otherwise. 
    */
    GLint getUniformLocation(string name) {
        this.makeCurrent();
        nstring tmp = name;
        return glGetUniformLocation(id, tmp.ptr);
    }

    /**
        Gets the location of an attribute.

        Params:
            name = Name of the attribute

        Returns:
            A positive binding number on success,
            $(D -1) otherwise. 
    */
    GLint getAttribLocation(string name) {
        nstring tmp = name;
        return glGetAttribLocation(id, tmp.ptr);
    }

    /**
        Sets the program as the one to be used.
    */
    void use() {
        this.makeCurrent();
        glUseProgram(id);
    }
}