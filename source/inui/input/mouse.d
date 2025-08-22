module inui.input.mouse;
import i2d.imgui;
import inmath;

/**
    Mouse buttons
*/
enum MouseButton : ImGuiMouseButton {
    left = ImGuiMouseButton.Left,
    middle = ImGuiMouseButton.Middle,
    right = ImGuiMouseButton.Right
}

/**
    Mouse cursor styles.
*/
enum MouseCursor : ImGuiMouseCursor {
    arrow = ImGuiMouseCursor.Arrow,
    textInput = ImGuiMouseCursor.TextInput,
    resizeAll = ImGuiMouseCursor.ResizeAll,
    resizeNS = ImGuiMouseCursor.ResizeNS,
    resizeEW = ImGuiMouseCursor.ResizeEW, 
    resizeNESW = ImGuiMouseCursor.ResizeNESW,
    resizeNWSE = ImGuiMouseCursor.ResizeNWSE,
    hand = ImGuiMouseCursor.Hand,
    wait = ImGuiMouseCursor.Wait,
    progress = ImGuiMouseCursor.Progress,
    notAllowed = ImGuiMouseCursor.NotAllowed,
}

class MouseState {
private:
    bool[3] lastBtnState;
    bool[3] btnState;
    bool[3] lastDragState;
    bool[3] dragState;
    vec2[3] dragDelta;

public:

    /**
        Gets whether the given mouse button was clicked.
    */
    bool isMouseClicked(MouseButton btn) => igIsMouseClicked(btn);

    /**
        Gets whether the given mouse button was 
        double-clicked.
    */
    bool isMouseDoubleClicked(MouseButton btn) => igIsMouseDoubleClicked(btn);

    /**
        Gets whether the given mouse button was 
        held.
    */
    bool isMouseDown(MouseButton btn) => btnState[btn];

    /**
        Gets whether the given mouse button was 
        held during the last frame.
    */
    bool wasMouseDown(MouseButton btn) => lastBtnState[btn];

    /**
        Gets whether the given mouse button was 
        used for dragging this frame.
    */
    bool isDragging(MouseButton btn) => dragState[btn];

    /**
        Gets whether the given mouse button was 
        used for dragging during the last frame.
    */
    bool wasDragging(MouseButton btn) => lastDragState[btn];

    /**
        Gets the drag delta for the given mouse button
    */
    vec2 dragDeltaFor(MouseButton btn) => dragDelta[btn];

    /**
        Sets the active cursor for the window.
    */
    void setCursor(MouseCursor cursor) {
        igSetMouseCursor(cursor);
    }

    /**
        Updates the internal state of the mouse
        handling.
    */
    void update() {
        lastDragState[0..$] = dragState[0..$];
        lastBtnState[0..$] = btnState[0..$];

        static foreach(btn; MouseButton.min..MouseButton.max) {
            btnState[btn] = igIsMouseDown(btn);
            dragState[btn] = igIsMouseDragging(btn);
            igGetMouseDragDelta(cast(ImVec2*)&dragDelta[btn], btn);
        }
    }
}