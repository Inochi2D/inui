/**
    Element in the CSS DOM

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.style.element;

/**
    A CSS DOM Element.
*/
class StyleElement {
private:
    string tag_;
    StyleElement parent_;
    StyleElement[] children_;
    string[string] attrs_;
    
    struct StyleParentIter {
        StyleElement self;

        @property bool empty() const => self is null;
        @property StyleElement front() => self;
        @property void popFront() { self = self.parent_; }
    }
    
    struct StyleElementIter {
        StyleElement self;
        uint idx = 0;

        @property bool empty() const => !self || idx >= self.children_.length;
        @property StyleElement front() => self.children_[idx];
        @property void popFront() { idx++; }
    }

    ptrdiff_t findChild(StyleElement element) {
        foreach(i, ref child; children_) {
            if (element is child)
                return i;
        }
        return -1;
    }

    void removeAt(size_t idx) {
        import std.algorithm.mutation : remove;
        children_ = children_.remove(idx);
    }

public:

    /**
        The parent element
    */
    @property StyleElement parent() => parent_;
    @property void parent(StyleElement value) {

        if (this.parent_) {
            auto idx = this.parent_.findChild(value);
            if (idx >= 0) {
                this.parent_.removeAt(idx);
            }
        }
        this.parent_ = value;
        this.parent_.children_ ~= this;
    }

    /**
        The tag of the element.
    */
    @property ref string tag() => tag_;

    /**
        The attributes of the element.
    */
    @property ref string[string] attributes() => attrs_;

    /**
        The child elements attributes.
    */
    @property ref StyleElement[] children() => children_;

    /**
        An iterator over the ancestors.
    */
	@property auto ancestors() => StyleParentIter(this);

    /**
        An iterator over the adjacents.
    */
	@property auto adjacents() => StyleElementIter(parent_);

    /**
        Gets attribute within element,
    */
	string* attr(const(char)[] name) => name in attrs_;

    /**
        Callback for psuedo attributes.
    */
    bool delegate(string name, string arg) onPsuedo;

    /**
        Function called for psuedo-attributes.
    */
	bool pseudo(const(char)[] name, const(char)[] arg) const {
		return onPsuedo ? onPsuedo(cast(string)name, cast(string)arg) : false;
	}

    /**
        Debug helper toString function
    */
    debug
    override
    string toString() {
        import std.format : format;
        import std.array : split, join;

        string result;
        if (parent)
            result ~= parent.toString() ~ " > ";

        result ~= tag;
        if (attributes.length > 0) {
            result ~= "[";
            string[] attribs;
            foreach(key, attrib; attributes) {
                attribs ~= "%s=%s".format(key, attrib);
            }
            result ~= attribs.join(", ");
            result ~= "]";
        }
        return result;
    }
}