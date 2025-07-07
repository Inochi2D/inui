/**
    NSMenu

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx.cocoa.nsmenu;

version(OSX):
import core.attribute : selector;
import foundation;
import objc;

/**
    The control state value.
*/
enum NSControlStateValue : NSInteger {
    Mixed = -1,
    Off = 0,
    On = 1,
}

/**
    A menu.
*/
extern(Objective-C)
extern class NSMenu : NSObject {

    /**
        Whether the menu bar is visible.
    */
    static @property bool menuBarVisible();
    static @property void menuBarVisible(bool value);

    /**
        The height of the menu bar.
    */
    @property double menuBarHeight();

    /**
        Initializes menu with title.
    */
    NSMenu initWithTitle(NSString title);
}

/**
    A menu item
*/
extern(Objective-C)
extern class NSMenuItem : NSObject {

    /**
        Initializes menu item with title.
    */
    NSMenu initWithTitle(NSString title, SEL action, NSString keyEquivalent);

    /**
        Creates a new section header.
    */
    static NSMenuItem createSectionHeader(NSString title) @selector("sectionHeaderWithTitle:");

    /**
        Creates a new seperator item.
    */
    static NSMenuItem createSeperator() @selector("separatorItem");

    /**
        The title of the menu item
    */
    @property NSString title();
    @property void title(NSString value);

    /**
        The tooltip of the menu item.
    */
    @property NSString toolTip();
    @property void toolTip(NSString value);

    /**
        Whether the menu item is enabled.
    */
    @property bool enabled();
    @property void enabled(bool value);

    /**
        Whether the menu item is hidden.
    */
    @property bool hidden();
    @property void hidden(bool value);

    /**
        Whether the menu item is a section header.
    */
    @property bool isSectionHeader();

    /**
        Whether the menu item is a seperator.
    */
    @property bool isSeperatorItem();

    /**
        Whether the menu item has a submenu.
    */
    @property bool hasSubmenu();

    /**
        The menu which contains this item.
    */
    @property NSMenu menu();
    @property void menu(NSMenu value);

    /**
        The submenu of this menu.
    */
    @property NSMenu submenu();
    @property void submenu(NSMenu value);

    /**
        The state of the menu item.
    */
    @property NSControlStateValue state();
    @property void state(NSControlStateValue value);
     
    /**
        Whether the menu item is hidden.
    */
    @property bool isHiddenOrHasHiddenAncestor();
}

