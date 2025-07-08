/**
    Styling Rules

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.style.rule;
import inui.style.property;
import inui.style.box;
import inmath.linalg;
import css : Selector;

import nulib.math : isFinite, abs;

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
    @property Alignment alignSelf() {
        return 
            has("align-self") ? 
            alignmentFromString(properties["align-self"].token(0, variables)) : 
            Alignment.inherit;
    }

    /**
        Alignment for widgets.
    */
    @property Alignment alignContent() {
        return 
            has("align-content") ? 
            alignmentFromString(properties["align-content"].token(0, variables)) : 
            Alignment.inherit;
    }

    /**
        Width
    */
    float width(float max, float autoSize) {
        if (!has("width") || properties["width"].values.length == 0)
            return 0;

        if (properties["width"].values[0].token == "auto")
            return autoSize;
        
        return properties["width"].values[0].computed(max, 96).abs();
    }

    /**
        Height
    */
    float height(float max, float autoSize) {
        if (!has("height") || properties["height"].values.length == 0)
            return 0;

        if (properties["height"].values[0].token == "auto")
            return autoSize;
        
        return properties["height"].values[0].computed(max, 96).abs();
    }

    /**
        Rectangle queries
    */
    vec4 rect(string name, vec2 size, vec2 max) {
        vec4 corners_ = vec4(size.x, size.y, size.x, size.y);
        if (!has(name) || properties[name].values.length == 0)
            return corners_;
        
        switch(properties[name].values.length) {
            case 1:
                corners_.x = properties[name].values[0].computed(max.x, 96, size.x);
                corners_.y = properties[name].values[0].computed(max.y, 96, size.y);
                corners_.z = properties[name].values[0].computed(max.x, 96, size.x);
                corners_.w = properties[name].values[0].computed(max.y, 96, size.y);
                break;
                
            case 2:
                corners_.x = properties[name].values[0].computed(max.x, 96, size.x);
                corners_.y = properties[name].values[1].computed(max.y, 96, size.y);
                corners_.z = properties[name].values[0].computed(max.x, 96, size.x);
                corners_.w = properties[name].values[1].computed(max.y, 96, size.y);
                break;

            case 3:
                corners_.x = properties[name].values[0].computed(max.x, 96, size.x);
                corners_.y = properties[name].values[1].computed(max.y, 96, size.y);
                corners_.z = properties[name].values[2].computed(max.x, 96, size.x);
                corners_.w = properties[name].values[1].computed(max.y, 96, size.y);
                break;

            default:
                corners_.x = properties[name].values[0].computed(max.x, 96, size.x);
                corners_.y = properties[name].values[1].computed(max.y, 96, size.y);
                corners_.z = properties[name].values[2].computed(max.x, 96, size.x);
                corners_.w = properties[name].values[3].computed(max.y, 96, size.y);
                break;
        }

        return corners_;
    }

    /**
        Corner queries
    */
    vec4 corners(string name, vec4 corners_, vec4 max) {
        if (!has(name) || properties[name].values.length == 0)
            return corners_;

        switch(properties[name].values.length) {
            case 1:
                corners_.x = properties[name].values[0].computed(max.x, 96, corners_.x);
                corners_.y = properties[name].values[0].computed(max.y, 96, corners_.y);
                corners_.z = properties[name].values[0].computed(max.z, 96, corners_.z);
                corners_.w = properties[name].values[0].computed(max.w, 96, corners_.w);
                break;
                
            case 2:
                corners_.x = properties[name].values[0].computed(max.x, 96, corners_.x);
                corners_.y = properties[name].values[1].computed(max.y, 96, corners_.y);
                corners_.z = properties[name].values[0].computed(max.z, 96, corners_.z);
                corners_.w = properties[name].values[1].computed(max.w, 96, corners_.w);
                break;

            case 3:
                corners_.x = properties[name].values[0].computed(max.x, 96, corners_.x);
                corners_.y = properties[name].values[1].computed(max.y, 96, corners_.y);
                corners_.z = properties[name].values[2].computed(max.z, 96, corners_.z);
                corners_.w = properties[name].values[1].computed(max.w, 96, corners_.w);
                break;

            case 4:
                corners_.x = properties[name].values[0].computed(max.x, 96, corners_.x);
                corners_.y = properties[name].values[1].computed(max.y, 96, corners_.y);
                corners_.z = properties[name].values[2].computed(max.z, 96, corners_.z);
                corners_.w = properties[name].values[3].computed(max.w, 96, corners_.w);
                break;
            
            default:
                break;
        }

        return corners_;
    }
}
