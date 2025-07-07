/**
    Widget Base Classes

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.widget;
import nulib.string;
import std.format : format;
import std.random : uniform;

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

public:

    /**
        Called once a frame.
    */
    final
    void update(float delta) {
        this.onUpdate(delta);
    }

    /**
        Tells the responder to refresh all of its information.
    */
    final
    void refresh() { this.onRefresh(); }
}

/**
    Base class for widgets.
*/
abstract
class Widget : Responder {
private:
    uint discriminator;
    string name_;
    string id_;

    nstring imName_;
    void regenImName() {
        if (discriminator == 0) {
            this.imName_ = "%s##%s".format(name_, id_);
            return;
        }

        this.imName_ = "%s##%s%u".format(name_, id_, discriminator);
    }

protected:
    
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

public:

    /**
        The ID of the widget.
    */
    final @property string id() { return id_[]; }

    /**
        The name of the widget.
    */
    final @property string name() { return name_[]; }

    /**
        The name of the widget.
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
    this(string id, bool randomize = true) {
        this.discriminator = randomize ? uniform(1, uint.max) : 0;

        this.name_ = id;
        this.id_ = id;
        this.regenImName();
    }

    /**
        Constructor
    */
    this(string id, string name, bool randomize = true) {
        this.discriminator = randomize ? uniform(1, uint.max) : 0;

        this.name_ = name;
        this.id_ = id;
        this.regenImName();
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
    auto add(Widget widget) {
        if (findWidget(widget) == -1)
            this.children_ ~= widget;
        
        return this;
    }
    
    /**
        Removes a widget to the container.
    */
    void remove(Widget widget) {
        import std.algorithm.mutation : remove;

        ptrdiff_t idx = findWidget(widget);
        if (idx != -1)
            children_ = children_.remove(idx);
    }

    /**
        Constructor
    */
    this(string name, bool randomize = true) {
        super(name, randomize);
    }
}

/**
    Adds a widget to the given container.
*/
T addWidget(T)(T to, Widget widget) if (is(T : Container)) {
    return cast(T)to.add(widget);
}