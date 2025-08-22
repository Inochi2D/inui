/**
    Widget Base Classes

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.widget;
import inui.core.utils;
import inui.window;
import inui.style;
import inui.app;

import inmath.linalg;
import nulib.string;
import i2d.imgui;
import std.random : uniform;
import std.format : format;

/**
    IDs for different UI element types for color styling.
*/
alias StyleElementId = ImGuiCol;

/**
    Base class of all widget-like types that can respond
    to input.
*/
abstract
class Responder {
protected:

    /**
        Called once a frame to update the responder.
    */
    abstract void onUpdate(float delta);

    /**
        Called when the responder needs to refresh all of
        its information.
    */
    abstract void onRefresh();
}

/**
    Base class for widgets.
*/
abstract
class Widget : Responder {
private:

    // Root window
    Window root_;
    Widget parent_;

    // ImGui
    uint discriminator;
    string tag_;
    string id_;
    string name_;

    nstring imName_;
    void regenImName() {

        if (tag_) selem_.tag = tag_;
        if (id_) selem_.attributes["id"] = id_;
        if (name_) selem_.attributes["name"] = name_;

        if (discriminator == 0) {
            this.imName_ = "%s##%s".format(name_, tag_);
            return;
        }

        this.imName_ = "%s##%s%u".format(name_, tag_, discriminator);
    }

    // CSS
    StyleElement selem_;
    StyleRule computed_;
    int pushedColors_;
    int pushedVars_;


protected:

    final
    void reparentTo(Widget newParent) {
        this.onReparented(this.parent_, newParent);
        
        this.selem_.parent = newParent.selem_;
        this.parent_ = newParent;
    }

    /**
        Computed style sheet.
    */
    @property StyleRule computedStyle() => computed_;

    /**
        Style element for the widget.
    */
    final @property StyleElement styleElement() => selem_;
    
    /**
        The tag of the widget.
    */
    final @property void tag(string value) {
        this.tag_ = value;
        this.regenImName();
    }
    
    /**
        The ID of the widget.
    */
    final @property void id(string value) {
        this.id_ = value;
        this.regenImName();
    }

    /**
        The name of the widget.
    */
    final @property void name(string value) {
        this.name_ = value;
        this.regenImName();
    }

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override
    void onRefresh() {
        debug(css_refresh) {
            import std.stdio : writefln;
            writefln("Recomputed style for %s...", this.styleElement);
        }
        
        // Recomputes style
        computed_ = Application.thisApp.stylesheet.findRule(selem_);
    }

    /**
        Called when a widget is reparented in the hirearchy.

        Params:
            from =  The previous parent.
            to =    The new parent.
    */
    void onReparented(Widget from, Widget to) { }

    /**
        Helper which pushes a style color to the stack automatically.
    */
    void pushStyleColor(StyleElementId col, vec4 color) {
        if (!color.isFinite)
            return;
        
        igPushStyleColor(col, color.toImGui!ImVec4);
        pushedColors_++;
    }

package(inui):

    /**
        Internal function to set the root window of a widget.
    */
    void setWindow(Window window) @system {
        this.root_ = window;
    }

public:

    /**
        The style class for this widget.
    */
    final @property string styleClass() { 
        return "class" in selem_.attributes ? selem_.attributes["class"] : "";
    }
    final @property void styleClass(string value) { 
        selem_.attributes["class"] = value;
        this.refresh();
    }

    /**
        Window that this widget resides within.
    */
    final @property Window window() {
        return parent ? parent_.window : root_;
    }

    /**
        The widget above this one, $(D null) if the widget is top-level.
    */
    final @property Widget parent() { return parent_; }

    /**
        The id of the widget.
    */
    final @property string id() { return id_[]; }

    /**
        The tag of the widget.
    */
    final @property string tag() { return tag_[]; }

    /**
        The name of the widget.
    */
    final @property string name() { return name_[]; }

    /**
        The imgui name of the widget.
    */
    final @property string imName() { return imName_[]; }

    /**
        Destructor
    */
    ~this() {
        this.imName_.clear();
    }

    /**
        Constructor
    */
    this(string tag, string name, bool randomize = true) {
        this.discriminator = randomize ? uniform(1, uint.max) : 0;

        this.tag_ = tag;
        this.name_ = name;
        this.selem_ = new StyleElement();
        this.regenImName();
    }

    /**
        Called once a frame.
    */
    final
    void update(float delta) {
        this.onUpdate(delta);
        if (pushedColors_ > 0) {
            igPopStyleColor(pushedColors_);
            pushedColors_ = 0;
        }
    }

    /**
        Adds a widget to the widget, if supported.
    */
    Widget add(Widget widget) { return this; }
    
    /**
        Removes a widget from this widget, if supported.
    */
    Widget remove(Widget widget) { return this; }

    /**
        Tells the responder to refresh all of its information.
    */
    final
    void refresh() {
        this.onRefresh();
    }
}

/**
    A widget which contains other widgets.
*/
class Container : Widget {
private:
    Widget[] children_;

protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        foreach(child; children_) {
            child.update(delta);
        }
    }

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override
    void onRefresh() {
        foreach(child; children_) {
            child.refresh();
        }
    }

    /**
        Finds the location of a widget within the container.
    */
    final
    ptrdiff_t findWidget(Widget widget) {
        foreach(i, child; children_) {
            if (child == widget)
                return i;
        }
        return -1;
    }

public:

    /**
        A slice of the child widgets residing within this one.
    */
    final
    @property Widget[] children() {
        return children_[0..$];
    }
    
    /**
        Adds a widget to the container.
    */
    override
    Widget add(Widget widget) {
        if (findWidget(widget) == -1)
            this.children_ ~= widget;
        
        // Set the parent styling element.
        widget.reparentTo(this);
        return this;
    }
    
    /**
        Removes a widget to the container.
    */
    override
    Widget remove(Widget widget) {
        import std.algorithm.mutation : remove;

        ptrdiff_t idx = findWidget(widget);
        if (idx != -1) {
            children_ = children_.remove(idx);
            widget.reparentTo(null);
        }
        return this;
    }

    /**
        Constructor
    */
    this(string tag, string name, bool randomize = true) {
        super(tag, name, randomize);
    }

    /**
        Constructor
    */
    this(string name, bool randomize = true) {
        super("container", name, randomize);
    }
}

/**
    Adds a widget to the given container.
*/
T addWidget(T)(T to, Widget widget) if (is(T : Widget)) {
    return cast(T)to.add(widget);
}