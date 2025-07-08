/**
    Controls

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.widgets.control;
import inui.widgets.widget;
import inui.core.utils;
import inmath.linalg;
import i2d.imgui;

struct DrawContext {
private:
@nogc:
    ImDrawList* self;
    ImU32 currentColor;
    float thickness = 1.0;

public:

    /**
        Whether the path in the context is closed.
    */
    @property bool isPathClosed() {
        return self._Path.size > 0 ? self._Path[0] == self._Path[self._Path.size-1] : false;
    }

    /**
        The current clipping rectangle.
    */
    @property rect clipRect() {
        ImVec2 min, max;
        ImDrawList_GetClipRectMin(&min, self);
        ImDrawList_GetClipRectMax(&max, self);
        return rect(min.x, min.y, max.x-min.x, max.y-min.y);
    }

    /**
        Pushes a clipping rectangle onto the drawing context.

        Params:
            rect = The clipping rectangle to apply
            intersect = Whether to intersect the rect with the existing rectangle.
    */
    pragma(inline, true)
    void pushClip(recti rect, bool intersect = false) {
        ImDrawList_PushClipRect(self, ImVec2(rect.left, rect.top), ImVec2(rect.bottom, rect.right), intersect);
    }

    /**
        Pops a clipping rectangle from the drawing context.
    */
    pragma(inline, true)
    void popClip() {
        ImDrawList_PopClipRect(self);
    }

    /**
        Clears the current path.
    */
    pragma(inline, true)
    void clearPath() {
        ImDrawList_PathClear(self);
    }

    /**
        Closes the current path.
    */
    pragma(inline, true)
    void closePath() {
        if (self._Path.size == 0)
            return;
        
        ImDrawList_PathLineToMergeDuplicate(self, self._Path[0]);
    }

    /**
        Pops a clipping rectangle from the drawing context.
    */
    pragma(inline, true)
    void lineTo(vec2 target) {
        ImDrawList_PathLineToMergeDuplicate(self, ImVec2(target.x, target.y));
    }

    /**
        Pops a clipping rectangle from the drawing context.
    */
    pragma(inline, true)
    void quadTo(vec2 ctrl, vec2 target) {
        ImDrawList_PathBezierQuadraticCurveTo(self, ImVec2(ctrl.x, ctrl.y), ImVec2(target.x, target.y));
    }

    /**
        Pops a clipping rectangle from the drawing context.
    */
    pragma(inline, true)
    void cubicTo(vec2 ctrl1, vec2 ctrl2, vec2 target) {
        ImDrawList_PathBezierCubicCurveTo(self, ImVec2(ctrl1.x, ctrl1.y), ImVec2(ctrl2.x, ctrl2.y), ImVec2(target.x, target.y));
    }

    /**
        Strokes the path.
    */
    pragma(inline, true)
    void stroke() {
        if (self._Path.size == 0)
            return;

        if (!isPathClosed)
            closePath();
        
        ImDrawList_PathStroke(self, currentColor, ImDrawFlags.None, thickness);
    }

    /**
        Strokes the path.
    */
    pragma(inline, true)
    void fill() {
        if (self._Path.size == 0)
            return;

        if (!isPathClosed)
            closePath();
        
        ImDrawList_PathFillConcave(self, currentColor);
    }
}

/**
    Mouse buttons.
*/
enum MouseButton {
    left,
    middle,
    right
}

/**
    Alignment for controls.
*/
enum Alignment {

    /**
        Left alignment.
    */
    left,

    /**
        Center alignment
    */
    center,

    /**
        Right hand size alignment.
    */
    right
}

/**
    An interactive control.
*/
abstract
class Control : Widget {
private:
    bool hovered_;
    bool active_;
    bool focused_;
    Alignment alignment_;
    bool allowsOverlap_;
    vec2 sizeRequest_ = vec2(0, 0);
    vec2 actualSize_ = vec2(0, 0);

protected:

    /**
        The cursor position for the current layout.
    */
    @property vec2 layoutCursor() { vec2 v; igGetCursorScreenPos(cast(ImVec2*)&v); return v; }
    @property void layoutCursor(vec2 value) { igSetCursorScreenPos(value.toImGui!ImVec2); }

    /**
        The layout region.
    */
    @property rect layoutRegion() {
        vec2 sz; igGetContentRegionAvail(cast(ImVec2*)&sz);
        vec2 cursor = layoutCursor();
        return rect(cursor.x, cursor.y, sz.x, sz.y);
    }

    /**
        Called once a frame to update the control.

        If you override this function ensure you call this
        implementation.
    */
    override void onUpdate(float delta) {
        this.onDrawEarly(DrawContext(igGetBackgroundDrawList()), delta);

            if (allowsOverlap) igSetNextItemAllowOverlap();

            auto lrect = layoutRegion;
            auto lstart = layoutCursor;
            final switch(alignment_) {
                case Alignment.left:
                    this.onDraw(DrawContext(igGetWindowDrawList()), delta);
                    break;
                
                case Alignment.center:
                    layoutCursor = lstart + vec2((lrect.width/2)-(actualSize_.x/2), 0);
                    this.onDraw(DrawContext(igGetWindowDrawList()), delta);
                    layoutCursor = vec2(lstart.x, lstart.y + actualSize_.y);
                    break;
                
                case Alignment.right:
                    layoutCursor = lstart + vec2(lrect.width-actualSize_.x, 0);
                    this.onDraw(DrawContext(igGetWindowDrawList()), delta);
                    layoutCursor = vec2(lstart.x, lstart.y + actualSize_.y);
                    break;
            }

            igGetItemRectSize(cast(ImVec2*)&actualSize_);
            hovered_ = igIsItemHovered();
            active_ = igIsItemActive();
            focused_ = igIsItemFocused();

            // Handle mouse clicks.
            if (igIsItemClicked(ImGuiMouseButton.Left))
                this.onClicked(MouseButton.left);
            if (igIsItemClicked(ImGuiMouseButton.Middle))
                this.onClicked(MouseButton.middle);
            if (igIsItemClicked(ImGuiMouseButton.Right))
                this.onClicked(MouseButton.right);
            
            if (igIsItemEdited())
                this.onEdited();

            if (igIsItemActivated())
                this.onActivate();

            if (igIsItemDeactivated())
                this.onDeactivate(igIsItemDeactivatedAfterEdit());
        
        this.onDrawLate(DrawContext(igGetForegroundDrawList()), delta);
    }

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override void onRefresh() { }

    /**
        Called when the control wants to draw onto the context.

        This is called before the main draw step and will be drawn before
        the widget.

        Params:
            ctx = The drawing context.
            delta = Time since last frame.
    */
    void onDrawEarly(DrawContext ctx, float delta) { }

    /**
        Called when the control wants to draw onto the context.

        Params:
            ctx = The drawing context.
            delta = Time since last frame.
    */
    void onDraw(DrawContext ctx, float delta) { }

    /**
        Called when the control wants to draw onto the context.

        This is called after the main draw step.

        Params:
            ctx = The drawing context.
            delta = Time since last frame.
    */
    void onDrawLate(DrawContext ctx, float delta) { }

    /**
        Called when the control is clicked.
    */
    void onClicked(MouseButton button) { }

    /**
        Called when the control is edited.
    */
    void onEdited() { }

    /**
        Called when the control is activated.
    */
    void onActivate() { }

    /**
        Called when the control is deactivated.
    */
    void onDeactivate(bool wasEdited) { }

    /**
        Constructs a new control.

        Params:
            name        = The name of the control.
    */
    this(string name) {
        super(name, "", true);
    }

public:

    /**
        The requested size of the control.
    */
    @property vec2 sizeRequest() => sizeRequest_;
    @property void sizeRequest(vec2 value) {this.sizeRequest_ = value; }

    /**
        Whether the control allows being overlapped.
    */
    @property bool allowsOverlap() => allowsOverlap_;
    @property void allowsOverlap(bool value) {this.allowsOverlap_ = value; }

    /**
        Alignment of the control.
    */
    @property Alignment alignment() => alignment_;
    @property void alignment(Alignment value) {this.alignment_ = value; }

    /**
        Whether the control is being hovered over.
    */
    @property bool isHovered() => hovered_;

    /**
        Whether the control is active.
    */
    @property bool isActive() => active_;

    /**
        Whether the control is in focus.
    */
    @property bool isFocused() => focused_;
}