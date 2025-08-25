module gl.buffer;
import gl.context;
import inmath;
import numem;

public import inrndr.buffer;

class GLBuffer : Buffer {
public:
@nogc:

    override @property uint length() => 0;

    override
    void[] map() {
        return null;
    }

    override
    void unmap(ref void[] slice) {

    }
}