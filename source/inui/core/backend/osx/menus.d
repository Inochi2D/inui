/**
    macOS Integration

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.menus;
import inui.core.menu;
import numem;
import nulib;

version(OSX):

/**
    A menu for cocoa.
*/
class CocoaMenu : Menu {
private:
@nogc:

public:

}

extern(C) Menu __inui_menu_create(string title) @nogc {
    return null;
}

extern(C) MenuItem __inui_menuitem_create(string text, menuItemAction action, string shortcut) @nogc {
    return null;
}