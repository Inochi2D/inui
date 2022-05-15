/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core;
import bindbc.sdl;
import bindbc.imgui;

public import inui.core.window;
public import inui.core.app;
public import inui.core.path;
public import inui.core.settings;

void inInitUI() {
    
    // Load and init SDL2
    loadSDL();
    SDL_Init(SDL_INIT_EVERYTHING);

    // Load imgui
    loadImGui();

    // Init settings store
    inSettingsLoad();
}

/**
    Returns the current timestep of the app
*/
double inGetTime() {
    return (cast(double)SDL_GetPerformanceCounter() / cast(double)SDL_GetPerformanceFrequency())*0.001;
}