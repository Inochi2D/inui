/**
    Text Input Widget

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.textbox;
import inui.widgets.widget;
import nulib.string;
import i2d.imgui;

/**
    A textbox with an internally managed null terminated string buffer.
*/
class TextBox : Widget {
private:
    nstring placeholder;
    nstring buffer;

    static
    extern(C) int __text_callback(ImGuiInputTextCallbackData* data) {
        TextBox self = (cast(TextBox)data.UserData);
        switch(data.EventFlag) {
            
            case ImGuiInputTextFlags.CallbackResize:
                self.buffer.resize(data.BufSize-1);
                data.Buf = cast(char*)self.buffer.ptr;
                return 0;
            
            case ImGuiInputTextFlags.CallbackCharFilter:
                if (self.textFilter)
                    return self.textFilter(data.EventChar);
                return 0;

            default:
                return 0;
        }
    }

protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        char* buf = cast(char*)buffer.ptr;

        auto flags = ImGuiInputTextFlags.CallbackResize | ImGuiInputTextFlags.EnterReturnsTrue;
        if (igInputTextWithHint(imName.ptr, placeholder.ptr, buf, buffer.realLength, flags, &__text_callback, cast(void*)this)) {
            if (submit) {
                this.submit(buffer[0..$]);
            }
        }
    }

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override
    void onRefresh() { }

public:

    /**
        Optional text filter function.
        
        Returns:
            $(D true) to discard the character, $(D false) to keep
            the possibly modified character.
    */
    bool function(ref ImWchar codepoint) textFilter;

    /**
        Called when the text is submitted.
    */
    void delegate(string text) submit;

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
    this(string placeholder, string text) {
        super("TextBox", "", true);
        this.placeholder = placeholder;
        this.buffer = text;
    }

    /**
        Constructs a new text box.

        Params:
            placeholder = The text which should be shown if the textbox is empty.
    */
    this(string placeholder) {
        super("TextBox", "", true);
        this.placeholder = placeholder;
        this.buffer = "\0";
    }

    /**
        Sets the submit callback for the text box.
    */
    TextBox setOnSubmit(void delegate(string text) submit) {
        this.submit = submit;
        return this;
    }

    /**
        Sets the text filter callback for the text box.
    */
    TextBox setFilter(bool function(ref ImWchar codepoint) textFilter) {
        this.textFilter = textFilter;
        return this;
    }
}