#include <SDL.h>
#include <SDL_image.h>
#include <SDL_mixer.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>

#include "lantarcticalib.h"

// Location of Lua classes
#ifndef ANTARCTICADIR
#define ANTARCTICADIR "./lua"
#endif

#ifndef CONFIGPATH
#define CONFIGPATH "config.lua"
#endif

// https://stackoverflow.com/questions/12256455/print-stacktrace-from-c-code-with-embedded-lua
static int traceback(lua_State* L) {
  lua_getglobal(L, "debug");
  lua_getfield(L, -1, "traceback");
  lua_pushvalue(L, 1);
  lua_pushinteger(L, 2);
  lua_call(L, 2, 1);
  fprintf(stderr, "lua error: %s\n", lua_tostring(L, -1));
  return 1;
}

int main(int argc, char** argv) {
  // Load/init SDL
  if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
    fprintf(stderr, "failed to start SDL: %s\n", SDL_GetError());
    return 0;
  }

  // Load/init SDL image library
  int img_init_flags = IMG_INIT_PNG | IMG_INIT_JPG;
  if (IMG_Init(img_init_flags) != img_init_flags) {
    fprintf(stderr, "failed to init SDL image library: %s\n", SDL_GetError());
    return 0;
  }

  // Load/init SDL mixer
  int mix_init_flags = 0;
  if (Mix_Init(mix_init_flags) != mix_init_flags) {
    fprintf(stderr, "failed to init SDL mixer library: %s\n", Mix_GetError());
    return 0;
  }

  // Create a new Lua state
  lua_State* L = luaL_newstate();
  luaL_openlibs(L);  // open Lua standard libraries
  luaL_requiref(L, "antarctica", luaopen_antarctica, 1);  // load our library

  char* antarctica_dir = ANTARCTICADIR;
  char* configpath = CONFIGPATH;

  // Run the config script if it exists
  if (luaL_dofile(L, configpath)) {
    if (lua_isstring(L, -1)) {
      fprintf(stderr, "lua: %s\n", lua_tostring(L, -1));
      fprintf(stderr, "warning: couldn't get configuration from %s\n",
              configpath);
    } else if (lua_type(L, -1) == LUA_TTABLE) {
      // Get options
      if (lua_getfield(L, -1, "antarctica_dir")) {
        antarctica_dir = (char*)lua_tostring(L, -1);
      }
      lua_pop(L, 1);
    }
  }

  // Ensure antarctica_dir is on Lua's module search path
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "path");
  const char* cur_path = lua_tostring(L, -1);  // get value of "package.path"
  lua_pop(L, 1);

  lua_pushfstring(L, "%s;%s/?.lua", cur_path, antarctica_dir);
  lua_setfield(L, -2, "path");  // set "package.path"

  lua_pop(L, 1);  // pop "package"

  // Create global table "arg" to make command line arguments available to
  // scripts
  lua_createtable(L, argc, 0);
  for (int i = 0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_seti(L, -2, i);
  }
  lua_setglobal(L, "arg");

  // Run scripts
  argv++;
  // if(luaL_dofile(L, *argv)) {
  // if(luaL_loadfile(L, *argv) || lua_call(L, 0, LUA_MULTRET)) {
  lua_pushcfunction(L, traceback);
  if (luaL_loadfile(L, *argv))
    fprintf(stderr, "failed to run %s\n", *argv);
  else
    lua_pcall(L, 0, 0, lua_gettop(L) - 1);

  // Free Lua state, close SDL
  lua_close(L);
  Mix_Quit();
  IMG_Quit();
  SDL_Quit();
  return 0;
}
