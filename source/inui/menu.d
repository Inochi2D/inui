module inui.menu;
import numem;
import nulib;

private
extern(C) Menu __inui_menu_create(string title) @nogc;

/**
    A menu
*/
abstract
class Menu : NuRefCounted {
protected:
@nogc:
    
    /**
        Called when a menu item was indexed.
    */
    abstract MenuItem onIndex(size_t index);
    
    /**
        Called when a menu item is to be appended.
    */
    abstract void onAppend(MenuItem toAppend);

public:

    /**
        The title of the menu.
    */
    abstract @property string name();
    abstract @property void name(string value);

    /**
        The amount of elements in the menu.
    */
    abstract @property size_t length();

    /**
        Appends the given menu item to the menu
    */
    void opOpAssign(string op = "~")(MenuItem value) {
        this.onAppend(value);
    }

    /**
        Finds the menu item at the given index.
    */
    final
    ref auto opIndex(size_t index) {
        return this.onIndex(index);
    }

    /**
        Creates a menu.
    */
    static Menu create(string title) {
        return __inui_menu_create(title);
    }
}

private
extern(C) MenuItem __inui_menuitem_create(string text, menuItemAction action, string shortcut) @nogc;

/**
    A menu item
*/
abstract
class MenuItem : NuRefCounted {
public:
@nogc:

    /**
        The menu item's submenu.
    */
    @property Menu submenu();
    @property void submenu(Menu menu);

    /**
        The name of the menu item.
    */
    abstract @property string name();
    abstract @property void name(string value);

    /**
        Whether the menu item is visible
    */
    abstract @property bool visible();
    abstract @property void visible(bool value);

    /**
        Creates a new menu item
    */
    static MenuItem create(string text, menuItemAction action, string shortcut = null) {
        return __inui_menuitem_create(text, action, shortcut);
    }
}

/**
    The action that the menu item should perform.
*/
alias menuItemAction = void delegate();
