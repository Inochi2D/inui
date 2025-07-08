/**
    CSS Stylesheets

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.style.stylesheet;
import inui.style.property;
import inui.style.element;
import inui.style.rule;
import inui.style.parser;


class StyleSheet {
private:
    StyleRule[] rules;

public:

    /**
        Global variables for the style sheet.
    */
    StyleProperty[string] variables;

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
        return new StyleSheet(parseCSS(css));
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
        computed.variables = variables;
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