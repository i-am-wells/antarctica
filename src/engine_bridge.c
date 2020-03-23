// TODO license

#include "engine_bridge.h"

#include <SDL.h>
#include <lauxlib.h>
#include <lua.h>
#include <luaarg.h>

#include "engine.h"
#include "lua_helpers.h"

int l_engine_deinit(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  engine_deinit(e);

  // now the garbage collector can reclaim e
  return 0;
}

int l_engine_create(lua_State* L) {
  // Get arguments
  luaarg_t args[] = {
      LOPTIONALSTRING("title", "antarctica"),
      LOPTIONALNUMBER("x", SDL_WINDOWPOS_UNDEFINED),
      LOPTIONALNUMBER("y", SDL_WINDOWPOS_UNDEFINED),
      LOPTIONALNUMBER("w", 800),
      LOPTIONALNUMBER("h", 600),
      LOPTIONALNUMBER("windowflags", 0),
      LOPTIONALNUMBER("rendererindex", -1),
      LOPTIONALNUMBER("rendererflags",
                      SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC),
      LOPTIONALNUMBER("targetfps", 60),
      LNULL};
  if (luaarg_check(L, args) == -1) {
    // If the arguments aren't right, return nil
    lua_pushnil(L);
    return 1;
  }

  // Default engine init values
  char* wtitle = LSTRING_VALUE(args[0]);
  int x = LNUMBER_VALUE(args[1]);
  int y = LNUMBER_VALUE(args[2]);
  int w = LNUMBER_VALUE(args[3]);
  int h = LNUMBER_VALUE(args[4]);
  int wflags = LNUMBER_VALUE(args[5]);
  int ridx = LNUMBER_VALUE(args[6]);
  int rflags = LNUMBER_VALUE(args[7]);

  // Create C engine
  engine_t* e = (engine_t*)lua_newuserdata(L, sizeof(engine_t));

  // TODO: call handlers directly from Lua-side Engine table
  // Register event handler table (registry[e] := handler table)
  lua_pushlightuserdata(L, e);
  lua_newtable(L);
  lua_settable(L, LUA_REGISTRYINDEX);

  // If this fails, return (nil, error message)
  if (!engine_init(e, wtitle, x, y, w, h, wflags, ridx, rflags)) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, SDL_GetError());
    return 2;
  }

  // TODO set this explicitly
  e->targetfps = LNUMBER_VALUE(args[8]);

  // Set destructor for garbage-collection
  set_gc_metamethod(L, "engine_t", l_engine_deinit);

  // We are left with only e on the stack; return it
  return 1;
}

int l_engine_get_display_bounds(lua_State* L) {
  SDL_Rect rect;
  if (SDL_GetDisplayBounds(0, &rect) != 0) {
    SDL_Log("SDL_GetDisplayBounds failed: %s", SDL_GetError());
    return 0;
  }

  lua_pushinteger(L, rect.x);
  lua_pushinteger(L, rect.y);
  lua_pushinteger(L, rect.w);
  lua_pushinteger(L, rect.h);
  return 4;
}

int l_engine_sethandler(lua_State* L) {
  engine_t* e = (engine_t*)lua_touserdata(L, 1);
  // int type = lua_tonumber(L, 2);

  // Push the event handler table
  lua_pushlightuserdata(L, e);
  lua_gettable(L, LUA_REGISTRYINDEX);

  // Store the handler
  lua_pushnil(L);
  lua_pushnil(L);
  lua_copy(L, 2, -2);  // key: type
  lua_copy(L, 3, -1);  // value: handler
  lua_settable(L, -3);

  // Pop the event handler table
  lua_pop(L, 1);

  return 0;
}

int l_engine_setredraw(lua_State* L) {
  engine_t* e = (engine_t*)lua_touserdata(L, 1);

  lua_pushlightuserdata(L, e + 1);  // redraw key
  lua_pushnil(L);
  lua_copy(L, 2, -1);  // redraw function
  lua_settable(L, LUA_REGISTRYINDEX);

  return 0;
}

int l_engine_run(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");

  engine_run(e, L);
  return 0;
}

int l_engine_stop(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");

  e->running_depth--;
  return 0;
}

int l_engine_draw_point(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  int x = luaL_checkinteger(L, 2);
  int y = luaL_checkinteger(L, 3);

  engine_draw_point(e, x, y);
  return 0;
}

int l_engine_draw_line(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  int x0 = luaL_checkinteger(L, 2);
  int y0 = luaL_checkinteger(L, 3);
  int x1 = luaL_checkinteger(L, 4);
  int y1 = luaL_checkinteger(L, 5);

  engine_draw_line(e, x0, y0, x1, y1);
  return 0;
}

int l_engine_draw_rect(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  int x0 = luaL_checkinteger(L, 2);
  int y0 = luaL_checkinteger(L, 3);
  int w = luaL_checkinteger(L, 4);
  int h = luaL_checkinteger(L, 5);

  engine_draw_rect(e, x0, y0, w, h);
  return 0;
}

int l_engine_fill_rect(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  int x0 = luaL_checkinteger(L, 2);
  int y0 = luaL_checkinteger(L, 3);
  int w = luaL_checkinteger(L, 4);
  int h = luaL_checkinteger(L, 5);

  engine_fill_rect(e, x0, y0, w, h);
  return 0;
}

int l_engine_clear(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  engine_clear(e);
  return 0;
}

int l_engine_set_draw_color(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  int r = luaL_checkinteger(L, 2);
  int g = luaL_checkinteger(L, 3);
  int b = luaL_checkinteger(L, 4);
  int a = luaL_checkinteger(L, 5);

  engine_set_draw_color(e, r, g, b, a);
  return 0;
}

int l_engine_get_draw_color(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");

  uint8_t r, g, b, a;
  engine_get_draw_color(e, &r, &g, &b, &a);

  lua_pushinteger(L, r);
  lua_pushinteger(L, g);
  lua_pushinteger(L, b);
  lua_pushinteger(L, a);
  return 4;
}

int l_engine_set_logical_size(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  int w = luaL_checkinteger(L, 2);
  int h = luaL_checkinteger(L, 3);

  engine_set_render_logical_size(e, w, h);
  return 0;
}

int l_engine_get_logical_size(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");

  int w, h;
  engine_get_render_logical_size(e, &w, &h);
  lua_pushinteger(L, w);
  lua_pushinteger(L, h);
  return 2;
}

int l_engine_get_size(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");

  int w, h;
  engine_get_render_size(e, &w, &h);
  lua_pushinteger(L, w);
  lua_pushinteger(L, h);
  return 2;
}

int l_engine_get_ms_since_start(lua_State* L) {
  lua_pushinteger(L, SDL_GetTicks());
  return 1;
}

int l_engine_set_scale(lua_State* L) {
  engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
  float scaleX = luaL_checknumber(L, 2);
  float scaleY = luaL_checknumber(L, 3);
  engine_set_scale(e, scaleX, scaleY);
  return 0;
}

int l_engine_start_text_input(lua_State* L) {
  (void)L;
  SDL_StartTextInput();
  return 0;
}

int l_engine_stop_text_input(lua_State* L) {
  (void)L;
  SDL_StopTextInput();
  return 0;
}

void load_engine_bridge(lua_State* L) {
  luaL_Reg enginelib[] = {{"create", l_engine_create},
                          {"destroy", l_engine_deinit},
                          {"setHandler", l_engine_sethandler},
                          {"setRedraw", l_engine_setredraw},
                          {"run", l_engine_run},
                          {"stop", l_engine_stop},
                          {"drawPixel", l_engine_draw_point},
                          {"drawLine", l_engine_draw_line},
                          {"drawRect", l_engine_draw_rect},
                          {"fillRect", l_engine_fill_rect},
                          {"clear", l_engine_clear},
                          {"setColor", l_engine_set_draw_color},
                          {"getColor", l_engine_get_draw_color},
                          {"setLogicalSize", l_engine_set_logical_size},
                          {"getLogicalSize", l_engine_get_logical_size},
                          {"getSize", l_engine_get_size},
                          {"setScale", l_engine_set_scale},
                          {"msSinceStart", l_engine_get_ms_since_start},
                          {"startTextInput", l_engine_start_text_input},
                          {"stopTextInput", l_engine_stop_text_input},

                          {"getDisplayBounds", l_engine_get_display_bounds},
                          {NULL, NULL}};
  luaL_newlib(L, enginelib);

  // window flags
  set_int_field(L, "fullscreen", SDL_WINDOW_FULLSCREEN);
  set_int_field(L, "opengl", SDL_WINDOW_OPENGL);
  set_int_field(L, "shown", SDL_WINDOW_SHOWN);
  set_int_field(L, "hidden", SDL_WINDOW_HIDDEN);
  set_int_field(L, "borderless", SDL_WINDOW_BORDERLESS);
  set_int_field(L, "resizable", SDL_WINDOW_RESIZABLE);
  set_int_field(L, "minimized", SDL_WINDOW_MINIMIZED);
  set_int_field(L, "maximized", SDL_WINDOW_MAXIMIZED);
  set_int_field(L, "inputgrabbed", SDL_WINDOW_INPUT_GRABBED);
  set_int_field(L, "inputfocus", SDL_WINDOW_INPUT_FOCUS);
  set_int_field(L, "mousefocus", SDL_WINDOW_MOUSE_FOCUS);
  set_int_field(L, "fullscreendesktop", SDL_WINDOW_FULLSCREEN_DESKTOP);
  set_int_field(L, "foreign", SDL_WINDOW_FOREIGN);
  set_int_field(L, "allowhighdpi", SDL_WINDOW_ALLOW_HIGHDPI);
  set_int_field(L, "mousecapture", SDL_WINDOW_MOUSE_CAPTURE);
  set_int_field(L, "alwaysontop", SDL_WINDOW_ALWAYS_ON_TOP);
  set_int_field(L, "skiptaskbar", SDL_WINDOW_SKIP_TASKBAR);
  set_int_field(L, "utility", SDL_WINDOW_UTILITY);
  set_int_field(L, "tooltip", SDL_WINDOW_TOOLTIP);
  set_int_field(L, "popupmenu", SDL_WINDOW_POPUP_MENU);
  set_int_field(L, "vulkan", SDL_WINDOW_VULKAN);

  set_int_field(L, "mousebuttonleft", SDL_BUTTON_LEFT);
  set_int_field(L, "mousebuttonmiddle", SDL_BUTTON_MIDDLE);
  set_int_field(L, "mousebuttonright", SDL_BUTTON_RIGHT);

  set_int_field(L, "rendersoftware", SDL_RENDERER_SOFTWARE);
  set_int_field(L, "renderaccelerated", SDL_RENDERER_ACCELERATED);
  set_int_field(L, "rendervsync", SDL_RENDERER_PRESENTVSYNC);
  set_int_field(L, "rendertargettexture", SDL_RENDERER_TARGETTEXTURE);
}
