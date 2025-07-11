/**
    Text Input Widget

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.textbox;
import inui.widgets.control;
import nulib.string;
import i2d.imgui;
import inmath.linalg;

/**
    A textbox with an internally managed null terminated string buffer.
*/
class TextBox : Control {
private:

    enum BASE_FLAGS = ImGuiInputTextFlags.CallbackResize | ImGuiInputTextFlags.EnterReturnsTrue;
    ImGuiInputTextFlags flags_ = BASE_FLAGS;

    nstring placeholder;
    nstring buffer;

    static extern(C) int __text_callback(ImGuiInputTextCallbackData* data) {
        TextBox self = (cast(TextBox)data.UserData);
        switch(data.EventFlag) {
            
            case ImGuiInputTextFlags.CallbackResize:
                self.buffer.resize(data.BufSize-1);
                data.Buf = cast(char*)self.buffer.ptr;
                return 0;
            
            case ImGuiInputTextFlags.CallbackCharFilter:
                if (self.onTextFilter)
                    return self.onTextFilter(data.EventChar);
                return 0;

            default:
                return 0;
        }
    }

    // CSS Colors
    vec4 bgcolor_;
    vec4 color_;

protected:

    /**
        The active flags of the text box.
    */
    ImGuiInputTextFlags flags() => flags_;
    void flags(uint value) {
        flags_ = cast(ImGuiInputTextFlags)(BASE_FLAGS | value);
    }

    /**
        Called once a frame to update the widget.
    */
    override
    void onDraw(DrawContext ctx, float delta) {
        this.pushStyleColor(ImGuiCol.FrameBg, bgcolor_);
        this.pushStyleColor(ImGuiCol.FrameBgHovered, bgcolor_);
        this.pushStyleColor(ImGuiCol.FrameBgActive, bgcolor_);
        this.pushStyleColor(ImGuiCol.Text, color_);

        char* buf = cast(char*)buffer.ptr;
        igSetNextItemWidth(requestedSize.x <= 0 ? -float.min_normal : requestedSize.x);
        if (igInputTextWithHint(imName.ptr, placeholder.ptr, buf, buffer.realLength, flags_, &__text_callback, cast(void*)this)) {
            if (onSubmit)
                this.onSubmit(this);
        }
    }

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override
    void onRefresh() {
        super.onRefresh();
    }

    /**
        Constructs a new text box.

        Params:
            tag         = The tag of the widget.
            placeholder = The text which should be shown if the textbox is empty.
            text        = The text that the textbox should start out with.
    */
    this(string tag, string placeholder, string text) {
        super("", tag);
        this.placeholder = placeholder;
        this.buffer = text.length > 0 ? text : "\0";
    }

public:

    /**
        The content of the text box.
    */
    @property string text() => buffer[0..$];
    @property void text(string text) {
        buffer = text;
    }

    /**
        Optional text filter function.
        
        Returns:
            $(D true) to discard the character, $(D false) to keep
            the possibly modified character.
    */
    bool function(ref ImWchar codepoint) onTextFilter;

    /**
        Called when the text is submitted.
    */
    void delegate(TextBox self) onSubmit;

    /*
        Destructor
    */
    ~this() {
        buffer.clear();
        placeholder.clear();
    }

    /**
        Constructs a new text box.

        Params:
            placeholder = The text which should be shown if the textbox is empty.
            text        = The text that the textbox should start out with.
    */
    this(string placeholder, string text = null) {
        this("textbox", placeholder, text);
    }

    /**
        Sets the submit callback for the text box.
    */
    TextBox setOnSubmit(void delegate(TextBox self) submit) {
        this.onSubmit = submit;
        return this;
    }

    /**
        Sets the text filter callback for the text box.
    */
    TextBox setFilter(bool function(ref ImWchar codepoint) textFilter) {
        this.onTextFilter = textFilter;
        return this;
    }
}


/**
    A text box that hides the written characters and disallows copying.
*/
class SecretTextBox : TextBox {
public:

    /**
        Constructs a new secret text box.

        Params:
            placeholder = The text which should be shown if the textbox is empty.
            text        = The text that the textbox should start out with.
    */
    this(string placeholder, string text = null) {
        super("textbox", placeholder, text);
        this.flags = ImGuiInputTextFlags.Password;
    }
}

