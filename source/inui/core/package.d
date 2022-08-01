/*
    Copyright © 2022, Inochi2D Project
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
public import inui.core.utils;
import inmath;

private {
    double lastTime;
    double currTime;
}

void inInitUI() {
    
    // Load and init SDL2
    loadSDL();
    SDL_Init(SDL_INIT_EVERYTHING);

    // Load imgui
    version(BindImGui_Dynamic) loadImGui();

    // Init settings store
    inSettingsLoad();
}

/**
    Updates time, called internally by inui
*/
void inUpdateTime() {
    lastTime = currTime;
    if (SDL_GetTicks64) currTime = cast(double)SDL_GetTicks64()*0.001;
    else currTime = cast(double)SDL_GetTicks()*0.001;
}

/**
    Returns the current timestep of the app
*/
double inGetTime() {
    return currTime;
}

/**
    Gets delta time
*/
double inGetDeltaTime() {
    return abs(lastTime-currTime);
}