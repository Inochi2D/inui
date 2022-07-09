/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.window;

public import inui.core.window.appwin;

/**
    The base of a Window
*/
abstract class InWindow {
protected:
    void onOpened() { }
    void onClosed() { }
    void onResized(int width, int height) { }
    bool shouldProcess() { return false; }

    /**
        Early update (before UI draws)
    */
    abstract void onEarlyUpdate();

    /**
        Late update (before UI draws)
    */
    abstract void onUpdate();
    
public:

    /**
        Forces the window to be in focus
    */
    abstract void focus();
    
    /**
        Closes the Window permanently
    */
    abstract void close();

    /**
        Gets whether the window is alive
    */
    abstract bool isAlive();

    /**
        Window Width
    */
    abstract int width();

    /**
        Window Height
    */
    abstract int height();
}





//
// WINDOW LIST
//
private {

    // NOTE: This is stored in thread-local-storage.
    InWindow[] subwindows;
}

package(inui) {
    
    /**
        Gets the windowlist
    */
    ref InWindow[] inWindowListGet() {
        return subwindows;
    }

    /**
        Add window from internal window list
    */
    void inWindowListAdd(InWindow window) {
        subwindows ~= window;
    }

    /**
        Remove window from internal window list
    */
    void inWindowListRemove(InWindow window) {
        import std.algorithm.searching : countUntil;
        import std.algorithm.mutation : remove;

        // Early return
        if (subwindows.length == 0) return;

        // Remove index if found
        ptrdiff_t idx = subwindows.countUntil(window);
        if (idx >= 0) subwindows = subwindows.remove(idx);
    }
}