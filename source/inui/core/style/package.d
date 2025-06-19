/**
    Visual Styles

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.style;
import nulib.math : PI;
import std.variant;
import std.sumtype;
import i2d.imgui;

/**
    A visual style for the application
*/
struct VisualStyle {
public:

    /**
        The name of the visual style.
    */
    string name;

    /**
        A list of variants for the style.
    */
    StyleVariant[] variants;
}

/**
    A variant for a visual style.
*/
struct StyleVariant {

    /**
        The parent visual style.
    */
    VisualStyle parent;

    /**
        Name of the variant.
    */
    string name;

    /**
        Style variables for look and feel.
    */
    StyleVar[string] metrics;

    /**
        Color variables.
    */
    StyleVar[string] colors;

    /**
        Gets the full name of the style.
    */
    @property string fullName() {
        import std.string : format;
        return "%s (%s)\0".format(parent.name, name);
    }

    /**
        Gets a color from the style variant.
    */
    ImVec4 getColor(string name, ImVec4 defaultValue = ImVec4(0, 0, 0, 0)) {
        return colors.tryGet!ImVec4(name, defaultValue);
    }

    /**
        Gets a base style from the style variant.
    */
    ImGuiStyle toImStyle() {
        ImGuiStyle style;
        style.Alpha                         = metrics.tryGet!float("alpha",                                       DEFAULT.Alpha);
        style.DisabledAlpha                 = metrics.tryGet!float("disabled_alpha",                              DEFAULT.DisabledAlpha);
        style.WindowPadding                 = metrics.tryGet!ImVec2("window_padding",                             DEFAULT.WindowPadding);
        style.WindowRounding                = metrics.tryGet!float("window_rounding",                             DEFAULT.WindowRounding);
        style.WindowBorderSize              = metrics.tryGet!float("window_border_size",                          DEFAULT.WindowBorderSize);
        style.WindowMinSize                 = metrics.tryGet!ImVec2("window_min_size",                            DEFAULT.WindowMinSize);
        style.WindowTitleAlign              = metrics.tryGet!ImVec2("window_title_align",                         DEFAULT.WindowTitleAlign);
        style.WindowMenuButtonPosition      = metrics.tryGet!string("window_menu_button_position",                fromImGuiDir(DEFAULT.WindowMenuButtonPosition)).toImGuiDir();
        style.ChildRounding                 = metrics.tryGet!float("child_rounding",                              DEFAULT.ChildRounding);
        style.ChildBorderSize               = metrics.tryGet!float("child_border_size",                           DEFAULT.ChildBorderSize);
        style.PopupRounding                 = metrics.tryGet!float("popup_rounding",                              DEFAULT.PopupRounding);
        style.PopupBorderSize               = metrics.tryGet!float("popup_border_size",                           DEFAULT.PopupBorderSize);
        style.FramePadding                  = metrics.tryGet!ImVec2("frame_padding",                              DEFAULT.FramePadding);
        style.FrameRounding                 = metrics.tryGet!float("frame_rounding",                              DEFAULT.FrameRounding);
        style.FrameBorderSize               = metrics.tryGet!float("frame_border_size",                           DEFAULT.FrameBorderSize);
        style.ItemSpacing                   = metrics.tryGet!ImVec2("item_spacing",                               DEFAULT.ItemSpacing);
        style.ItemInnerSpacing              = metrics.tryGet!ImVec2("item_inner_spacing",                         DEFAULT.ItemInnerSpacing);
        style.CellPadding                   = metrics.tryGet!ImVec2("cell_padding",                               DEFAULT.CellPadding);
        style.TouchExtraPadding             = metrics.tryGet!ImVec2("touch_extra_padding",                        DEFAULT.TouchExtraPadding);
        style.IndentSpacing                 = metrics.tryGet!float("indent_spacing",                              DEFAULT.IndentSpacing);
        style.ColumnsMinSpacing             = metrics.tryGet!float("columns_min_spacing",                         DEFAULT.ColumnsMinSpacing);
        style.ScrollbarSize                 = metrics.tryGet!float("scrollbar_size",                              DEFAULT.ScrollbarSize);
        style.ScrollbarRounding             = metrics.tryGet!float("scrollbar_rounding",                          DEFAULT.ScrollbarRounding);
        style.GrabMinSize                   = metrics.tryGet!float("grab_min_size",                               DEFAULT.GrabMinSize);
        style.GrabRounding                  = metrics.tryGet!float("grab_rounding",                               DEFAULT.GrabRounding);
        style.LogSliderDeadzone             = metrics.tryGet!float("log_slider_deadzone",                         DEFAULT.LogSliderDeadzone);
        style.TabRounding                   = metrics.tryGet!float("tab_rounding",                                DEFAULT.TabRounding);
        style.TabBorderSize                 = metrics.tryGet!float("tab_border_size",                             DEFAULT.TabBorderSize);
        style.TabMinWidthForCloseButton     = metrics.tryGet!float("tab_min_width_for_close_button",              DEFAULT.TabMinWidthForCloseButton);
        style.TabBarBorderSize              = metrics.tryGet!float("tab_bar_border_size",                         DEFAULT.TabBarBorderSize);
        style.TabBarOverlineSize            = metrics.tryGet!float("tab_bar_overline_size",                       DEFAULT.TabBarOverlineSize);
        style.TableAngledHeadersAngle       = metrics.tryGet!float("table_angled_headers_angle",                  DEFAULT.TableAngledHeadersAngle);
        style.TableAngledHeadersTextAlign   = metrics.tryGet!ImVec2("table_angled_headers_text_align",            DEFAULT.TableAngledHeadersTextAlign);
        style.ColorButtonPosition           = metrics.tryGet!string("color_button_position",                      fromImGuiDir(DEFAULT.ColorButtonPosition)).toImGuiDir();
        style.ButtonTextAlign               = metrics.tryGet!ImVec2("button_text_align",                          DEFAULT.ButtonTextAlign);
        style.SelectableTextAlign           = metrics.tryGet!ImVec2("selectable_text_align",                      DEFAULT.SelectableTextAlign);
        style.SeparatorTextBorderSize       = metrics.tryGet!float("separator_text_border_size",                  DEFAULT.SeparatorTextBorderSize);
        style.SeparatorTextAlign            = metrics.tryGet!ImVec2("separator_text_align",                       DEFAULT.SeparatorTextAlign);
        style.SeparatorTextPadding          = metrics.tryGet!ImVec2("separator_text_padding",                     DEFAULT.SeparatorTextPadding);
        style.DisplayWindowPadding          = metrics.tryGet!ImVec2("display_window_padding",                     DEFAULT.DisplayWindowPadding);
        style.DisplaySafeAreaPadding        = metrics.tryGet!ImVec2("display_safe_area_padding",                  DEFAULT.DisplaySafeAreaPadding);
        style.DockingSeparatorSize          = metrics.tryGet!float("docking_separator_size",                      DEFAULT.DockingSeparatorSize);
        style.MouseCursorScale              = metrics.tryGet!float("mouse_cursor_scale",                          DEFAULT.MouseCursorScale);
        style.AntiAliasedLines              = metrics.tryGet!bool("anti_aliased_lines",                           DEFAULT.AntiAliasedLines);
        style.AntiAliasedLinesUseTex        = metrics.tryGet!bool("anti_aliased_lines_use_tex",                   DEFAULT.AntiAliasedLinesUseTex);
        style.AntiAliasedFill               = metrics.tryGet!bool("anti_aliased_fill",                            DEFAULT.AntiAliasedFill);
        style.CurveTessellationTol          = metrics.tryGet!float("curve_tessellation_tol",                      DEFAULT.CurveTessellationTol);
        style.CircleTessellationMaxError    = metrics.tryGet!float("circle_tessellation_max_error",               DEFAULT.CircleTessellationMaxError);
        style.HoverStationaryDelay          = metrics.tryGet!float("hover_stationary_delay",                      DEFAULT.HoverStationaryDelay);
        style.HoverDelayShort               = metrics.tryGet!float("hover_delay_short",                           DEFAULT.HoverDelayShort);
        style.HoverDelayNormal              = metrics.tryGet!float("hover_delay_normal",                          DEFAULT.HoverDelayNormal);
        style.HoverFlagsForTooltipMouse     = DEFAULT.HoverFlagsForTooltipMouse;
        style.HoverFlagsForTooltipNav       = DEFAULT.HoverFlagsForTooltipNav;
        
        foreach(string key, ref StyleVar styleColor; colors) {
            
            // Cast to unit in case somehow we get a negative value.
            uint color = cast(uint)key.toImGuiCol();
            if (color < ImGuiCol.COUNT) {
                style.Colors[color] == styleColor.tryGet!ImVec4(ImVec4(0, 0, 0, 0));
            }
        }
        return style;
    }
}

/**
    A style variable.
*/
alias StyleVar = Algebraic!(ImVec4, ImVec2, string, float, int, bool);

/**
    Tries to get a value from the style var dict.
*/
T tryGet(T)(StyleVar[string] vars, string key, T defaultValue = T.init) {
    return key in vars ? vars[key].tryGet!T(defaultValue) : defaultValue;
}

/**
    Tries to get a value from the style var instance.
*/
T tryGet(T)(StyleVar var, T defaultValue = T.init)
if (StyleVar.allowed!T) {
    return var.convertsTo!T ? var.get!T() : defaultValue;
}

/**
    Default colors derived from the original Inochi Creator Dark Theme.
*/
__gshared ImGuiStyle DEFAULT = ImGuiStyle(
    Alpha:                          1.0f,
    DisabledAlpha:                  0.60f,
    WindowPadding:                  ImVec2(8, 8),
    WindowRounding:                 4.0f,
    WindowBorderSize:               1.0f,
    WindowMinSize:                  ImVec2(32, 32),
    WindowTitleAlign:               ImVec2(0.0, 0.5),
    WindowMenuButtonPosition:       ImGuiDir.None,
    ChildRounding:                  0.0f,
    ChildBorderSize:                1.0f,
    PopupRounding:                  6.0f,
    PopupBorderSize:                1.0f,
    FramePadding:                   ImVec2(4, 4),
    FrameRounding:                  3.0f,
    FrameBorderSize:                1.0f,
    ItemSpacing:                    ImVec2(8, 3),
    ItemInnerSpacing:               ImVec2(4, 4),
    CellPadding:                    ImVec2(4, 2),
    TouchExtraPadding:              ImVec2(0, 0),
    IndentSpacing:                  10.0f,
    ColumnsMinSpacing:              6.0f,
    ScrollbarSize:                  14.0f,
    ScrollbarRounding:              18.0f,
    GrabMinSize:                    13.0f,
    GrabRounding:                   3.0f,
    LogSliderDeadzone:              6.0f,
    TabRounding:                    6.0f,
    TabBorderSize:                  1.0f,
    TabMinWidthForCloseButton:      -1.0f,
    TabBarBorderSize:               1.0f,
    TabBarOverlineSize:             1.0f,
    TableAngledHeadersAngle:        35.0f * (PI / 180.0f),
    TableAngledHeadersTextAlign:    ImVec2(0.5f, 0.0f),
    ColorButtonPosition:            ImGuiDir.Right,
    ButtonTextAlign:                ImVec2(0.5f, 0.5f),
    SelectableTextAlign:            ImVec2(0.0f, 0.0f),
    SeparatorTextBorderSize:        3.0f,
    SeparatorTextAlign:             ImVec2(0.0f, 0.5f),
    SeparatorTextPadding:           ImVec2(20.0f, 3.0f),
    DisplayWindowPadding:           ImVec2(19, 19),
    DisplaySafeAreaPadding:         ImVec2(3, 3),
    DockingSeparatorSize:           1.0f,
    MouseCursorScale:               1.0f,
    AntiAliasedLines:               true,
    AntiAliasedLinesUseTex:         true,
    AntiAliasedFill:                true,
    CurveTessellationTol:           1.25f,
    CircleTessellationMaxError:     0.30f,
    HoverStationaryDelay:           0.15f,
    HoverDelayShort:                0.15f,
    HoverDelayNormal:               0.40f,
    HoverFlagsForTooltipMouse:      ImGuiHoveredFlags.Stationary | ImGuiHoveredFlags.DelayShort | ImGuiHoveredFlags.AllowWhenDisabled,        
    HoverFlagsForTooltipNav:        ImGuiHoveredFlags.NoSharedDelay | ImGuiHoveredFlags.DelayNormal | ImGuiHoveredFlags.AllowWhenDisabled,        
    Colors: [
        ImVec4(1.00f, 1.00f, 1.00f, 1.00f), // Text
        ImVec4(0.50f, 0.50f, 0.50f, 1.00f), // TextDisabled
        ImVec4(0.17f, 0.17f, 0.17f, 1.00f), // WindowBg
        ImVec4(0.00f, 0.00f, 0.00f, 0.00f), // ChildBg
        ImVec4(0.08f, 0.08f, 0.08f, 0.94f), // PopupBg
        ImVec4(0.00f, 0.00f, 0.00f, 0.16f), // Border
        ImVec4(0.00f, 0.00f, 0.00f, 0.16f), // BorderShadow
        ImVec4(0.12f, 0.12f, 0.12f, 1.00f), // FrameBg
        ImVec4(0.15f, 0.15f, 0.15f, 0.40f), // FrameBgHovered
        ImVec4(0.22f, 0.22f, 0.22f, 0.67f), // FrameBgActive
        ImVec4(0.04f, 0.04f, 0.04f, 1.00f), // TitleBg
        ImVec4(0.00f, 0.00f, 0.00f, 1.00f), // TitleBgActive
        ImVec4(0.00f, 0.00f, 0.00f, 0.51f), // TitleBgCollapsed
        ImVec4(0.05f, 0.05f, 0.05f, 1.00f), // MenuBarBg
        ImVec4(0.02f, 0.02f, 0.02f, 0.53f), // ScrollbarBg
        ImVec4(0.31f, 0.31f, 0.31f, 1.00f), // ScrollbarGrab
        ImVec4(0.41f, 0.41f, 0.41f, 1.00f), // ScrollbarGrabHovered
        ImVec4(0.51f, 0.51f, 0.51f, 1.00f), // ScrollbarGrabActive
        ImVec4(0.76f, 0.76f, 0.76f, 1.00f), // CheckMark
        ImVec4(0.25f, 0.25f, 0.25f, 1.00f), // SliderGrab
        ImVec4(0.60f, 0.60f, 0.60f, 1.00f), // SliderGrabActive
        ImVec4(0.39f, 0.39f, 0.39f, 0.40f), // Button
        ImVec4(0.44f, 0.44f, 0.44f, 1.00f), // ButtonHovered
        ImVec4(0.50f, 0.50f, 0.50f, 1.00f), // ButtonActive
        ImVec4(0.25f, 0.25f, 0.25f, 1.00f), // Header
        ImVec4(0.28f, 0.28f, 0.28f, 0.80f), // HeaderHovered
        ImVec4(0.44f, 0.44f, 0.44f, 1.00f), // HeaderActive
        ImVec4(0.00f, 0.00f, 0.00f, 1.00f), // Separator
        ImVec4(0.29f, 0.29f, 0.29f, 0.78f), // SeparatorHovered
        ImVec4(0.47f, 0.47f, 0.47f, 1.00f), // SeparatorActive
        ImVec4(0.35f, 0.35f, 0.35f, 0.00f), // ResizeGrip
        ImVec4(0.40f, 0.40f, 0.40f, 0.00f), // ResizeGripHovered
        ImVec4(0.55f, 0.55f, 0.56f, 0.00f), // ResizeGripActive
        ImVec4(0.34f, 0.34f, 0.34f, 0.80f), // TabHovered
        ImVec4(0.00f, 0.00f, 0.00f, 1.00f), // Tab
        ImVec4(0.25f, 0.25f, 0.25f, 1.00f), // TabSelected
        ImVec4(0.26f, 0.59f, 0.98f, 1.00f), // TabSelectedOverline
        ImVec4(0.14f, 0.14f, 0.14f, 0.97f), // TabDimmed
        ImVec4(0.17f, 0.17f, 0.17f, 1.00f), // TabDimmedSelected
        ImVec4(0.50f, 0.50f, 0.50f, 0.00f), // TabDimmedSelectedOverline
        ImVec4(0.62f, 0.68f, 0.75f, 0.70f), // DockingPreview
        ImVec4(0.20f, 0.20f, 0.20f, 1.00f), // DockingEmptyBg
        ImVec4(0.61f, 0.61f, 0.61f, 1.00f), // PlotLines
        ImVec4(1.00f, 0.43f, 0.35f, 1.00f), // PlotLinesHovered
        ImVec4(0.90f, 0.70f, 0.00f, 1.00f), // PlotHistogram
        ImVec4(1.00f, 0.60f, 0.00f, 1.00f), // PlotHistogramHovered
        ImVec4(0.19f, 0.19f, 0.20f, 1.00f), // TableHeaderBg
        ImVec4(0.31f, 0.31f, 0.35f, 1.00f), // TableBorderStrong
        ImVec4(0.23f, 0.23f, 0.25f, 1.00f), // TableBorderLight
        ImVec4(0.310f, 0.310f, 0.310f, 0.267f), // TableRowBg
        ImVec4(0.463f, 0.463f, 0.463f, 0.267f), // TableRowBgAlt
        ImVec4(0.26f, 0.59f, 0.98f, 1.00f), // TextLink
        ImVec4(0.26f, 0.59f, 0.98f, 0.35f), // TextSelectedBg
        ImVec4(1.00f, 1.00f, 0.00f, 0.90f), // DragDropTarget
        ImVec4(0.32f, 0.32f, 0.32f, 1.00f), // NavCursor
        ImVec4(1.00f, 1.00f, 1.00f, 0.70f), // NavWindowingHighlight
        ImVec4(0.80f, 0.80f, 0.80f, 0.20f), // NavWindowingDimBg
        ImVec4(0.80f, 0.80f, 0.80f, 0.35f), // ModalWindowDimBg
    ]
);

/**
    Gets a ImGui base color ID from its name.
*/
ImGuiCol toImGuiCol(string name) {
    switch(name) {
        case "text":
            return ImGuiCol.Text;
        case "text_disabled":
            return ImGuiCol.TextDisabled;
        case "window_bg":
            return ImGuiCol.WindowBg;
        case "child_bg":
            return ImGuiCol.ChildBg;
        case "popup_bg":
            return ImGuiCol.PopupBg;
        case "border":
            return ImGuiCol.Border;
        case "border_shadow":
            return ImGuiCol.BorderShadow;
        case "frame_bg":
            return ImGuiCol.FrameBg;
        case "frame_bg_hovered":
            return ImGuiCol.FrameBgHovered;
        case "frame_bg_active":
            return ImGuiCol.FrameBgActive;
        case "title_bg":
            return ImGuiCol.TitleBg;
        case "title_bg_active":
            return ImGuiCol.TitleBgActive;
        case "title_bg_collapsed":
            return ImGuiCol.TitleBgCollapsed;
        case "menu_bar_bg":
            return ImGuiCol.MenuBarBg;
        case "scrollbar_bg":
            return ImGuiCol.ScrollbarBg;
        case "scrollbar_grab":
            return ImGuiCol.ScrollbarGrab;
        case "scrollbar_grab_hovered":
            return ImGuiCol.ScrollbarGrabHovered;
        case "scrollbar_grab_active":
            return ImGuiCol.ScrollbarGrabActive;
        case "check_mark":
            return ImGuiCol.CheckMark;
        case "slider_grab":
            return ImGuiCol.SliderGrab;
        case "slider_grab_active":
            return ImGuiCol.SliderGrabActive;
        case "button":
            return ImGuiCol.Button;
        case "button_hovered":
            return ImGuiCol.ButtonHovered;
        case "button_active":
            return ImGuiCol.ButtonActive;
        case "header":
            return ImGuiCol.Header;
        case "header_hovered":
            return ImGuiCol.HeaderHovered;
        case "header_active":
            return ImGuiCol.HeaderActive;
        case "separator":
            return ImGuiCol.Separator;
        case "separator_hovered":
            return ImGuiCol.SeparatorHovered;
        case "separator_active":
            return ImGuiCol.SeparatorActive;
        case "resize_grip":
            return ImGuiCol.ResizeGrip;
        case "resize_grip_hovered":
            return ImGuiCol.ResizeGripHovered;
        case "resize_grip_active":
            return ImGuiCol.ResizeGripActive;
        case "tab_hovered":
            return ImGuiCol.TabHovered;
        case "tab":
            return ImGuiCol.Tab;
        case "tab_selected":
            return ImGuiCol.TabSelected;
        case "tab_selected_overline":
            return ImGuiCol.TabSelectedOverline;
        case "tab_dimmed":
            return ImGuiCol.TabDimmed;
        case "tab_dimmed_selected":
            return ImGuiCol.TabDimmedSelected;
        case "tab_dimmed_selected_overline":
            return ImGuiCol.TabDimmedSelectedOverline;
        case "docking_preview":
            return ImGuiCol.DockingPreview;
        case "docking_empty_bg":
            return ImGuiCol.DockingEmptyBg;
        case "plot_lines":
            return ImGuiCol.PlotLines;
        case "plot_lines_hovered":
            return ImGuiCol.PlotLinesHovered;
        case "plot_histogram":
            return ImGuiCol.PlotHistogram;
        case "plot_histogram_hovered":
            return ImGuiCol.PlotHistogramHovered;
        case "table_header_bg":
            return ImGuiCol.TableHeaderBg;
        case "table_border_strong":
            return ImGuiCol.TableBorderStrong;
        case "table_border_light":
            return ImGuiCol.TableBorderLight;
        case "table_row_bg":
            return ImGuiCol.TableRowBg;
        case "table_row_bg_alt":
            return ImGuiCol.TableRowBgAlt;
        case "text_link":
            return ImGuiCol.TextLink;
        case "text_selected_bg":
            return ImGuiCol.TextSelectedBg;
        case "drag_drop_target":
            return ImGuiCol.DragDropTarget;
        case "nav_cursor":
            return ImGuiCol.NavCursor;
        case "nav_windowing_highlight":
            return ImGuiCol.NavWindowingHighlight;
        case "nav_windowing_dim_bg":
            return ImGuiCol.NavWindowingDimBg;
        case "modal_window_dim_bg":
            return ImGuiCol.ModalWindowDimBg;
        default:
            return ImGuiCol.COUNT;
    }
}

/**
    Converts string to imgui dir
*/
ImGuiDir toImGuiDir(string dir) {
    switch(dir) {
        case "left":
            return ImGuiDir.Left;
        case "right":
            return ImGuiDir.Right;
        case "up":
            return ImGuiDir.Up;
        case "down":
            return ImGuiDir.Down;
        default:
            return ImGuiDir.None;
    }
}

/**
    Converts imgui dir to string
*/
string fromImGuiDir(ImGuiDir dir) {
    final switch(dir) {
        case ImGuiDir.None:
            return "none";
        case ImGuiDir.Left:
            return "left";
        case ImGuiDir.Right:
            return "right";
        case ImGuiDir.Up:
            return "up";
        case ImGuiDir.Down:
            return "down";
        case ImGuiDir.COUNT:
            return "none";
    }
}