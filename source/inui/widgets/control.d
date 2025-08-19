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

public import inui.style;

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
    An interactive control.
*/
abstract
class Control : Widget {
private:
    bool prevHovered_;
    bool hovered_;
    bool active_;
    bool focused_;

    vec2 lastSize = vec2(0, 0);
    bool allowsOverlap_;
    bool onPsuedo(string name, string arg) {
        switch(name) {
            case "hover":
                return hovered_;

            case "active":
                return active_;

            case "focused":
                return focused_;
            
            default:
                return false;
        }
    }

protected:

    // CSS
    BoxModel cssbox;

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
            auto prect = rect(
                lrect.x         + cssbox.padding.x,
                lrect.y         + cssbox.padding.y,
                lrect.width     - cssbox.padding.z,
                lrect.height    - cssbox.padding.w,
            );

            auto totalMargins = cssbox.totalMargins;
            auto totalPadding = cssbox.totalPadding;
            auto totalOffset = totalMargins + totalPadding;
            cssbox.requestedSize = vec2(
                computedStyle.width(lrect.width - totalOffset.x, cssbox.contentSize.x),
                computedStyle.height(lrect.height - totalOffset.y, cssbox.contentSize.y)
            );

            if (cssbox.requestedSize != lastSize) {
                this.onSizeChanged(lastSize, cssbox.requestedSize);
                lastSize = cssbox.requestedSize;
            }

            auto computedArea = rect(
                lrect.x,
                lrect.y,
                cssbox.computedSize.x + totalOffset.x,
                cssbox.computedSize.y + totalOffset.y,
            );

            // Ensure layout.
            igDummy(ImVec2(
                computedArea.width,
                computedArea.bottom
            ));

            final switch(cssbox.alignSelf) {
                case Alignment.inherit:
                    layoutCursor = vec2(prect.x, prect.y);
                    break;
                
                case Alignment.left:
                    layoutCursor = vec2(prect.x, prect.y);
                    break;
                
                case Alignment.center:
                    layoutCursor = vec2(prect.center.x-computedArea.center.x, prect.top);
                    break;
                
                case Alignment.right:
                    layoutCursor = vec2(prect.right-computedArea.width, prect.top);
                    break;
            }

            igSetNextItemWidth(cssbox.requestedSize.x);
            this.onDraw(DrawContext(igGetWindowDrawList()), delta);
            igGetItemRectSize(cast(ImVec2*)&cssbox.computedSize);
            
            // Next line.
            layoutCursor = vec2(
                computedArea.left, 
                computedArea.bottom
            );

            prevHovered_ = hovered_;
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
            
            if (igIsItemEdited()) {
                this.onEdited();
                this.refresh(); 
            }

            if (igIsItemActivated()) {
                this.onActivate();
                this.refresh(); 
            }

            if (prevHovered_ != hovered_) {
                if (hovered_) this.onHoverEnter();
                else this.onHoverLeave();
                this.refresh();
            }

            if (igIsItemDeactivated()) {
                this.onDeactivate(igIsItemDeactivatedAfterEdit());
                this.refresh();
            }
        
        this.onDrawLate(DrawContext(igGetForegroundDrawList()), delta);
    }

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override
    void onRefresh() {
        super.onRefresh();
        vec2 halfSize = cssbox.computedSize/2.0;

        cssbox.alignContent = computedStyle.alignContent;
        cssbox.alignSelf = computedStyle.alignSelf;
        cssbox.padding = computedStyle.rect(
            "padding", 
            vec2(0, 0), 
            vec2(0, 0)
        );

        cssbox.margins = computedStyle.rect(
            "margins", 
            vec2(0, 0), 
            vec2(0, 0)
        );
        cssbox.borderRadius = computedStyle.corners("border-radius", vec4(0, 0, 0, 0), halfSize.xyxy);
    }

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
        Called when the control has begun to be hovered.
    */
    void onHoverEnter() { }

    /**
        Called when the control is no longer hovered.
    */
    void onHoverLeave() { }

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
        Called when the control's size is changed
    */
    void onSizeChanged(vec2 oldSize, vec2 newSize) { }

    /**
        Constructs a new control.

        Params:
            name        = The name of the control.
            tag         = Optional tag to use.
    */
    this(string name, string tag = null) {
        super(tag ? tag : name, name, true);
        this.styleElement.onPsuedo = &this.onPsuedo;
    }

public:

    /**
        The requested size of the control.
    */
    @property vec2 requestedSize() => cssbox.requestedSize;

    /**
        Whether the control allows being overlapped.
    */
    @property bool allowsOverlap() => allowsOverlap_;
    @property void allowsOverlap(bool value) {this.allowsOverlap_ = value; }

    /**
        Alignment of the control.
    */
    @property Alignment alignment() => cssbox.alignSelf;

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