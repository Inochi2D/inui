/**
    SDL Error Handling.

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.eh;
import nueh = numem.core.exception;
import numem : nogc_new;

/**
    Enforces a condition to be truthy, throws an $(D SDLException) on failure.

    Params:
        in_ =   The value to check
        file =  The file the check was done in.
        line =  The line in the file.

    Returns:
        The object that was given to the function,
        unless an exception was thrown.
*/
T enforceSDL(T)(T in_, string file = __FILE__, size_t line = __LINE__) {
    debug {
        if (!in_)
            throw nogc_new!SDLException(file, line);
        return in_;
    } else return in_;
}

/**
    An exception thrown by SDL.
*/
class SDLException : nueh.NuException {
public:
@nogc:
    this(string file = __FILE__, size_t line = __LINE__) {
        import sdl.error : SDL_GetError;
        import nulib.string : nu_strlen;

        auto err = SDL_GetError();
        super(err[0..nu_strlen(err)], null, file, line);
    }
}