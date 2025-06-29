/**
    Inui Buffer Interface

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.buffer;
import inui.core.render.gl;
import bindbc.opengl;
import inmath.util;
import inmath;
import nulib.text.uni;

/**
    Types of buffers.
*/
enum BufferType : int {
    vertex = GL_ARRAY_BUFFER,
    index = GL_ELEMENT_ARRAY_BUFFER
}

/**
    Strongly typed buffer
*/
class BufferT(T) : Buffer {
public:
@nogc:

    /**
        Stride of buffer elements.
    */
    override
    @property size_t stride() { return T.sizeof; }

    /**
        Length of buffer elements.
    */
    override
    @property size_t length() { return super.length / T.sizeof; }

    /**
        Constructor
    */
    this(GLContext context, BufferType type) {
        super(context, type);
    }

    /**
        Uploads data to the buffer.
    */
    void upload(T[] data) {
        super.upload(cast(void[])data);
    }
    
    /**
        Binds this buffer to the given location
    */
    override
    uint bind(uint location) {
        if (bType == BufferType.index) {
            glBindBuffer(bType, id);
            return 0;
        }

        glBindBuffer(bType, id);
        static if (__traits(isIntegral, T)) {
            glEnableVertexAttribArray(location);
            glVertexAttribPointer(location, mType.dimensions, toGLStorageType!T, T.sizeof, null);
            return 1;
        } else static if (__traits(isFloating, T)) {
            glEnableVertexAttribArray(location);
            glVertexAttribPointer(location, mType.dimensions, toGLStorageType!T, T.sizeof, null);
            return 1;
        } else static if (is(T == struct)) {
            static foreach(i, member; __traits(getMembers, T)) {
                {
                    alias mType = typeof(__traits(getMember, T, member));
                    static if (isVector!mType) {
                        glEnableVertexAttribArray(location+i);
                        glVertexAttribPointer(location+i, mType.dimensions, toGLStorageType!mType, stride, cast(void*)(0+mType.offsetof));
                    }
                }
            }
            return __traits(getMembers, T).length;
        } else static assert(0, T.stringof~"Not supported.");
    }
}

/**
    Weakly typed buffer
*/
class Buffer : GLObject {
private:
@nogc:
    // Per-thread active buffer
    static void* active;

    BufferType bType;
    size_t bLen;

    GLuint create(BufferType type) {
        this.bType = type;

        GLuint _id;
        glGenBuffers(1, &_id);
        return _id;
    }

public:

    /**
        Stride of buffer elements.
    */
    @property size_t stride() { return 1; }

    /**
        Length of buffer elements.
    */
    @property size_t length() { return bLen; }

    /**
        Destructor
    */
    ~this() {
        GLuint _id = id;
        glDeleteBuffers(1, &_id);
    }

    /**
        Constructor
    */
    this(GLContext context, BufferType type) {
        context.makeCurrent();
        super(context, this.create(type));
    }

    /**
        Uploads data to the buffer.
    */
    void upload(void[] data) {
        this.bLen = data.length;
        
        glBindBuffer(bType, id);
        glBufferData(id, data.length, data.ptr, GL_DYNAMIC_DRAW);
    }

    /**
        Binds this buffer to the given location
    
        Params:
            location = The base location to bind the buffer

        Returns:
            How many binding slots were assigned.
    */
    uint bind(uint location) {
        glBindBuffer(bType, id);
        return 0;
    }
}

private
template toGLStorageType(T) {
    static if (isVector!T) {
             static if (is(T.vt == float )) enum toGLStorageType = GL_FLOAT;
        else static if (is(T.vt == byte  )) enum toGLStorageType = GL_BYTE;
        else static if (is(T.vt == ubyte )) enum toGLStorageType = GL_UNSIGNED_BYTE;
        else static if (is(T.vt == short )) enum toGLStorageType = GL_SHORT;
        else static if (is(T.vt == ushort)) enum toGLStorageType = GL_UNSIGNED_SHORT;
        else static if (is(T.vt == int   )) enum toGLStorageType = GL_INT;
        else static if (is(T.vt == uint  )) enum toGLStorageType = GL_UNSIGNED_INT;
        else static assert(0, T.stringof~"Not supported.");
    } else static if (__traits(isIntegral, T)) {
             static if (is(T == byte  )) enum toGLStorageType = GL_BYTE;
        else static if (is(T == ubyte )) enum toGLStorageType = GL_UNSIGNED_BYTE;
        else static if (is(T == short )) enum toGLStorageType = GL_SHORT;
        else static if (is(T == ushort)) enum toGLStorageType = GL_UNSIGNED_SHORT;
        else static if (is(T == int   )) enum toGLStorageType = GL_INT;
        else static if (is(T == uint  )) enum toGLStorageType = GL_UNSIGNED_INT;
        else static assert(0, T.stringof~"Not supported.");
    } else static if (__traits(isFloating, T)) {
        static if (is(T == float )) enum toGLStorageType = GL_FLOAT;
        else static assert(0, T.stringof~"Not supported.");
    } else static assert(0, T.stringof~"Not supported.");
}