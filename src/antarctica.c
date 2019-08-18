// TODO license

#include "antarctica.h"

#include <lua.h>
#include <lauxlib.h>
#include <SDL.h>
#include <SDL_image.h>
#include <SDL_mixer.h>

#include "engine_bridge.h"
#include "image_bridge.h"
#include "object_bridge.h"
#include "sound_bridge.h"
#include "tilemap_bridge.h"

static int was_init = 0;

int l_antarctica_init(lua_State* L) {
    // Load/init SDL
    if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        fprintf(stderr, "failed to start SDL: %s\n", SDL_GetError());
        return 0;
    }

    // Load/init SDL image library
    int img_init_flags = IMG_INIT_PNG | IMG_INIT_JPG;
    if(IMG_Init(img_init_flags) != img_init_flags) {
        fprintf(stderr, "failed to init SDL image library: %s\n", SDL_GetError());
        return 0;
    }

    // Load/init SDL mixer
    int mix_init_flags = 0;
    if(Mix_Init(mix_init_flags) != mix_init_flags) {
        fprintf(stderr, "failed to init SDL mixer library: %s\n", Mix_GetError());
        return 0;
    }

    was_init = 1;
    return 0;
}

int l_antarctica_quit(lua_State* L) {
    Mix_Quit();
    IMG_Quit();
    SDL_Quit();
    return 0;
}

static const luaL_Reg antarcticalib[] = {
    {"init", l_antarctica_init},
    {"quit", l_antarctica_quit},
    {NULL, NULL}
};

int luaopen_antarctica(lua_State * L) {
    if (!was_init) {
      l_antarctica_init(L);
    }

    // Create module table
    luaL_newlib(L, antarcticalib);

    // Load submodules
    load_engine_bridge(L);
    lua_setfield(L, -2, "engine");

    // image
    load_image_bridge(L); 
    lua_setfield(L, -2, "image");

    // tilemap
    load_tilemap_bridge(L);
    lua_setfield(L, -2, "tilemap");

    // object
    load_object_bridge(L);
    lua_setfield(L, -2, "object");

    // sound
    load_sound_bridge(L);
    lua_setfield(L, -2, "sound");
    return 1;
}

