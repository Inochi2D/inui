/**
    macOS Integration

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.osx;
version(OSX):

public import inui.core.backend.osx.vibrancy;
public import inui.core.backend.osx.menus;
public import inui.core.backend.osx.color;
import sdl.hints;

void uiCocoaPlatformSetup() {
    SDL_SetHint(SDL_HINT_MAC_SCROLL_MOMENTUM, "1");
    SDL_SetHint(SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK, "1");
    SDL_SetHint(SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES, "1");
    SDL_SetHint(SDL_HINT_VIDEO_MAC_FULLSCREEN_MENU_VISIBILITY, "1");
}