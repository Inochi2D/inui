/**
    CSS Parser

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.style.parser;
import inui.style.property;
import inui.style.rule;
import css;

/**
    Parses CSS
*/
StyleRule[] parseCSS(string source) {
    CSSReader reader;
    css.parseCSS(source, reader);
    return reader.rules;
}

private
struct CSSReader {
private:
    StyleRule[] rules;

    StyleRule crule;
    StyleProperty cprop;

    string parseNext(ref string value) {
        if (value.length == 0)
            return null;

        size_t j = value.length;
        int depth = 0;
        foreach(i, c; value) {
            if (c == '(' || c == '[') depth++;
            if (c == ')' || c == ']') depth--;
            
            if (c == ' ' && depth == 0) {
                j = i;
                break;
            }
        }

        string rval = value[0..j].dup;
        value = rval.length == value.length ? null : value[j+1..$];
        return rval;
    }

public:

    void onSelector(const(char)[] data) {
        crule = StyleRule(Selector.parse(cast(string)data));
    }

    void onBlockEnd() {
        rules ~= crule;
    }

    void onPropertyName(const(char)[] data) {
        cprop = StyleProperty.init;
        cprop.key = cast(string)data;
    }

    void onPropertyValue(const(char)[] data) {
        string value = cast(string)data;
        while (string next = parseNext(value)) {
            cprop.values ~= StyleValue.parse(next);
        }
    }

    void onPropertyValueEnd() {
        crule.properties[cprop.key] = cprop;
    }

    void onSelectorEnd() { }
    void onComment(const(char)[] data) { }
}