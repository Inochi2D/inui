/**
    Styling engine

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.style;
import inmath.linalg;
import std.array;
import css;

class StyleSheet {
private:
    StyleRule[] rules;

public:

    /**
        Creates a new style sheet from a set of style rules.
    */
    this(StyleRule[] rules) {
        this.rules = rules;
    }

    /**
        Parses a style sheet.

        Params:
            css = The style sheet.
        
        Returns:
            A stylesheet.
    */
    static StyleSheet parse(string css) {
        CSSReader reader; parseCSS(css, reader);
        return new StyleSheet(reader.rules);
    }

    /**
        Tries to find a style rule matching the given selector.

        Params:
            selector = The selector to query
        
        Returns:
            A rule matching the given selector.
    */
    StyleRule findRule(StyleElement element) {
        StyleRule computed;
        foreach(ref rule; rules) {
            if (rule.selector.matches(element)) {
                foreach(key, property; rule.properties) {
                    computed.properties[key] = property;
                }
            }
        }
        return computed;
    }

    /**
        The style rules as a string.
    */
    override
    string toString() const {
        import std.conv : text;
        return rules.text;
    }
}

/**
    A styled element.
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
}

struct StyleRule {

    /**
        The selector for the rule.
    */
    Selector selector;
    
    /**
        The properties for the rule.
    */
    StyleProperty[string] properties;

    /**
        Whether the rule has a rule for the given name.
    */
    bool has(string name) => (name in properties) !is null;

    /**
        Background color
    */
    vec4 backgroundColor() {
        return has("background-color") ? properties["background-color"].color : vec4.init;
    }

    /**
        Foreground color
    */
    vec4 color() {
        return has("color") ? properties["color"].color : vec4.init;
    }
}

/**
    A property 
*/
struct StyleProperty {

    /**
        Key of the property.
    */
    string key;
    
    /**
        Values of the property
    */
    string[] values;
    
    /**
        Values of the property as a single string.
    */
    @property string valueStr() => values.join(" ");

    /**
        The style property as a color
    */
    @property vec4 color() {
        import colors : color, RGBAf;
        RGBAf c = color(valueStr).toRGBAf();
        return *(cast(vec4*)&c);
    }
}

private
struct CSSReader {
private:
    StyleRule[] rules;

    string selectorString;
    StyleRule crule;
    StyleProperty cprop;

public:

    void onSelector(const(char)[] data) {
        crule = StyleRule(Selector.parse(cast(string)data));
    }

    void onSelectorEnd() {
        selectorString = null;
    }

    void onBlockEnd() {
        rules ~= crule;
    }

    void onPropertyName(const(char)[] data) {
        cprop = StyleProperty.init;
        cprop.key = cast(string)data;
    }

    void onPropertyValue(const(char)[] data) {
        cprop.values = cast(string[])data.split(" ");
    }

    void onPropertyValueEnd() {
        crule.properties[cprop.key] = cprop;
    }

    void onComment(const(char)[] data) { }
}