/**
    Styling Properties and Values

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.style.property;
import inmath.linalg;
import colors : color, Color, RGBAf;

/**
    Maximum recursion depth for variable resolution.
*/
enum STYLE_RESOLVE_DEPTH_MAX = 5;

/**
    A property 
*/
struct StyleProperty {
private:

    // Resolves a color
    vec4 resolveColor(ref StyleProperty[string] variables, uint offset, uint depth) {
        if (depth < STYLE_RESOLVE_DEPTH_MAX && offset < values.length) {
            if (string var = values[0].var) {
                if (var in variables)
                    return variables[var].resolveColor(variables, depth+1, offset);
            } else {
                return values[offset].color;
            }
        }
        return vec4.init;
    }

    // Resolves a color
    string resolveToken(ref StyleProperty[string] variables, uint offset, uint depth) {
        if (depth < STYLE_RESOLVE_DEPTH_MAX && offset < values.length) {
            if (string var = values[0].var) {
                if (var in variables)
                    return variables[var].resolveToken(variables, depth+1, offset);
            } else {
                return values[offset].token;
            }
        }
        return null;
    }

    // Resolves a color
    float resolveNumber(ref StyleProperty[string] variables, uint offset, uint depth) {
        if (depth < STYLE_RESOLVE_DEPTH_MAX && offset < values.length) {
            if (string var = values[0].var) {
                if (var in variables)
                    return variables[var].resolveNumber(variables, depth+1, offset);
            } else {
                return values[offset].number;
            }
        }
        return 0;
    }

    // Resolves a color
    float resolvePx(ref StyleProperty[string] variables, uint offset, uint depth) {
        if (depth < STYLE_RESOLVE_DEPTH_MAX && offset < values.length) {
            if (string var = values[0].var) {
                if (var in variables)
                    return variables[var].resolvePx(variables, depth+1, offset);
            } else {
                return values[offset].px;
            }
        }
        return 0;
    }

    // Resolves a color
    float resolvePt(ref StyleProperty[string] variables, uint offset, uint depth) {
        if (depth < STYLE_RESOLVE_DEPTH_MAX && offset < values.length) {
            if (string var = values[0].var) {
                if (var in variables)
                    return variables[var].resolvePt(variables, depth+1, offset);
            } else {
                return values[offset].pt;
            }
        }
        return 0;
    }

    // Resolves a color
    float resolvePct(ref StyleProperty[string] variables, uint offset, uint depth) {
        if (depth < STYLE_RESOLVE_DEPTH_MAX && offset < values.length) {
            if (string var = values[0].var) {
                if (var in variables)
                    return variables[var].resolvePct(variables, depth+1, offset);
            } else {
                return values[offset].pct;
            }
        }
        return 0;
    }

public:

    /**
        Key of the property.
    */
    string key;
    
    /**
        Values of the property
    */
    StyleValue[] values;

    /**
        Gets the color at the given offset.
    */
    vec4 color(uint offset = 0, StyleProperty[string] variables = null) {
        return this.resolveColor(variables, offset, 0);
    }

    /**
        Token
    */
    string token(uint offset = 0, StyleProperty[string] variables = null) {
        return this.resolveToken(variables, offset, 0);
    }

    /**
        Number
    */
    float number(uint offset = 0, StyleProperty[string] variables = null) {
        return this.resolveNumber(variables, offset, 0);
    }

    /**
        Pixels
    */
    float px(uint offset = 0, StyleProperty[string] variables = null) {
        return this.resolvePx(variables, offset, 0);
    }

    /**
        Points
    */
    float pt(uint offset = 0, StyleProperty[string] variables = null) {
        return this.resolvePt(variables, offset, 0);
    }

    /**
        Percentage
    */
    float pct(uint offset = 0, StyleProperty[string] variables = null) {
        return this.resolvePct(variables, offset, 0);
    }
}

/**
    Types for style values
*/
enum StyleValueType {
    none,
    color,
    number,
    px,
    pt,
    pct,
    variable,
    token,
}

struct StyleValue {
private:
    StyleValueType vtype;
    union {
        vec4 color_;
        float number_;
        float px_;
        float pt_;
        float pct_;
        string variable_;
        string token_;
    }

public:

    /**
        The type of the style value.
    */
    @property StyleValueType type() => vtype;

    /**
        Color
    */
    @property vec4 color() => vtype == StyleValueType.color ? color_ : vec4.init;

    /**
        Number
    */
    @property float number() => vtype == StyleValueType.number ? number_ : 0;

    /**
        Number (in pixels)
    */
    @property float px() => vtype == StyleValueType.px ? px_ : 0;

    /**
        Number (in points)
    */
    @property float pt() => vtype == StyleValueType.pt ? pt_ : 0;

    /**
        Number (in percentage (0..1))
    */
    @property float pct() => vtype == StyleValueType.pct ? pct_ : 0;

    /**
        Variable
    */
    @property string var() => vtype == StyleValueType.variable ? variable_ : null;

    /**
        Token
    */
    @property string token() => vtype == StyleValueType.token ? token_ : null;

    /**
        Whether the style value is a variable.
    */
    @property bool isVariable() => vtype == StyleValueType.variable;

    /**
        Whether the style value is a variable.
    */
    @property bool isToken() => vtype == StyleValueType.token;

    /**
        Parses the given style value
    */
    static StyleValue parse(string value) {
        import std.algorithm.searching : startsWith, endsWith, count;
        import std.uni : isNumber, isAlpha;
        import std.conv : to;
        if (value.length > 0) {

            // Try parsing as CSS color.
            Color cssColor = .color(value);
            if (cssColor != Color.init) {
                RGBAf c = cssColor.toRGBAf();
                return StyleValue(vtype: StyleValueType.color, color_: *(cast(vec4*)&c));
            }

            // var(xyz)
            if (value.length > 5 && value.startsWith("var(") && value.endsWith(")")) {
                return StyleValue(vtype: StyleValueType.variable, variable_: value[4..$-1]);
            }

            // Try parsing as number
            size_t i = 0;
            do {
                if (!isNumber(value[i]) && value[i] != '.')
                    break;
            } while(i++ < value.length);

            if (i > 0) {

                string number = value[0..i];
                try {
                    if (value.endsWith("px")) return StyleValue(vtype: StyleValueType.px, px_: number.to!float);
                    else if (value.endsWith("pt")) return StyleValue(vtype: StyleValueType.pt, pt_: number.to!float);
                    else if (value.endsWith("%")) return StyleValue(vtype: StyleValueType.pct, pct_: number.to!float / 100.0);
                    else return StyleValue(vtype: StyleValueType.number, number_: number.to!float);
                } catch(Exception ex) { }
            }
            
            // Fallback as a token
            return StyleValue(vtype: StyleValueType.token, token_: value);
        }
        return StyleValue.init;
    }

    /**
        Creates a color style value
    */
    static StyleValue createColor(vec4 value) => StyleValue(vtype: StyleValueType.color, color_: value);

    /**
        Creates a px style value
    */
    static StyleValue createPx(float value) => StyleValue(vtype: StyleValueType.px, px_: value);

    /**
        Creates a pt style value
    */
    static StyleValue createPt(float value) => StyleValue(vtype: StyleValueType.pt, pt_: value);

    /**
        Creates a % style value (0..100)
    */
    static StyleValue createPct(float value) => StyleValue(vtype: StyleValueType.pct, pct_: value / 100.0);

    /**
        Creates a number style value
    */
    static StyleValue createNumber(float value) => StyleValue(vtype: StyleValueType.number, number_: value);

    /**
        Creates a variable reference style value
    */
    static StyleValue createVariableRef(string value) => StyleValue(vtype: StyleValueType.variable, variable_: value);

    /**
        Creates a token style value
    */
    static StyleValue createToken(string value) => StyleValue(vtype: StyleValueType.token, token_: value);

    /**
        Calculates the real number value.
    */
    float computed(float max, float dpi, float default_ = 0) {
        switch(vtype) {
            case StyleValueType.number:
            case StyleValueType.px:
                return number_;

            case StyleValueType.pt:
                return number_ * dpi;

            case StyleValueType.pct:
                return max * number_;
            
            default:
                return default_;
        }
    }
}
