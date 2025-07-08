/**
    Styling Rules

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.style.rule;
import inui.widgets.control;
import inui.style.property;
import inmath.linalg;
import css : Selector;

/**
    A CSS Style Rule
*/
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
        Variable list
    */
    StyleProperty[string] variables;

    /**
        Whether the rule has a rule for the given name.
    */
    bool has(string name) => (name in properties) !is null;

    /**
        Gets a variable
    */
    StyleProperty var(string name) {
        return name in variables ? variables[name] : StyleProperty.init;
    }

    /**
        Background color
    */
    @property vec4 backgroundColor() {
        return 
            has("background-color") ? 
            properties["background-color"].color(0, variables) : 
            vec4.init;
    }

    /**
        Foreground color
    */
    @property vec4 color() {
        return 
            has("color") ? 
            properties["color"].color(0, variables) : 
            vec4.init;
    }

    /**
        Alignment for widgets.
    */
    Alignment alignment() {
        return 
            has("align") ? 
            alignmentFromString(properties["align"].token(0, variables)) : 
            Alignment.inherit;
    }
}