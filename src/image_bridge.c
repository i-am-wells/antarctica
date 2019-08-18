// TODO license

#include "image_bridge.h"

#include <lua.h>
#include <lauxlib.h>

#include "image.h"
#include "lua_helpers.h"

int l_image_destroy(lua_State* L) {
    image_t* i = (image_t*)lua_touserdata(L, 1);
    image_deinit(i);
    return 0;
}

int l_image_load(lua_State* L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    luaL_checkstring(L, 2);
    luaL_checkinteger(L, 3);
    luaL_checkinteger(L, 4);

    lua_getfield(L, 1, "_engine");
    engine_t* e = (engine_t*)luaL_checkudata(L, -1, "engine_t");
    lua_pop(L, 1);
    const char* filename = lua_tostring(L, 2);
    int tw = lua_tointeger(L, 3);
    int th = lua_tointeger(L, 4);

    image_t* i = lua_newuserdata(L, sizeof(image_t));

    if(!image_init(i, e, filename, tw, th)) {
        lua_pop(L, 1);
        lua_pushnil(L);
        lua_pushstring(L, SDL_GetError());
        return 2;
    }

    set_gc_metamethod(L, "image_t", l_image_destroy);
    return 1;
}

int l_image_create_blank(lua_State* L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    luaL_checkinteger(L, 2);
    luaL_checkinteger(L, 3);
    luaL_checkinteger(L, 4);
    luaL_checkinteger(L, 5);

    lua_getfield(L, 1, "_engine");
    engine_t* e = (engine_t*)luaL_checkudata(L, -1, "engine_t");
    lua_pop(L, 1);
    int w = lua_tointeger(L, 2);
    int h = lua_tointeger(L, 3);
    int tw = lua_tointeger(L, 4);
    int th = lua_tointeger(L, 5);

    image_t* i = lua_newuserdata(L, sizeof(image_t));
    if(!image_init_blank(i, e, w, h, tw, th)) {
        lua_pop(L, 1);
        lua_pushnil(L);
        lua_pushstring(L, SDL_GetError());
        return 2;
    }
    
    set_gc_metamethod(L, "image_t", l_image_destroy);
    return 1;
}

int l_image_draw(lua_State* L) {
    image_t* i = (image_t*)lua_touserdata(L, 1);
    int sx = lua_tointeger(L, 2);
    int sy = lua_tointeger(L, 3);
    int sw = lua_tointeger(L, 4);
    int sh = lua_tointeger(L, 5);
    int dx = lua_tointeger(L, 6);
    int dy = lua_tointeger(L, 7);
    int dw = lua_tointeger(L, 8);
    int dh = lua_tointeger(L, 9);
    
    image_draw(i, sx, sy, sw, sh, dx, dy, dw, dh);
    return 0;
}

int l_image_draw_whole(lua_State* L) {
    image_t* i = (image_t*)lua_touserdata(L, 1);
    int dx = lua_tointeger(L, 2);
    int dy = lua_tointeger(L, 3);
    
    image_draw_whole(i, dx, dy);
    return 0;
}

int l_image_draw_tile(lua_State* L) {
    image_t* i = (image_t*)lua_touserdata(L, 1);
    int tilex = lua_tointeger(L, 2);
    int tiley = lua_tointeger(L, 3);
    int dx = lua_tointeger(L, 4);
    int dy = lua_tointeger(L, 5);
    
    image_draw_tile(i, tilex, tiley, dx, dy);
    return 0;
}

int l_image_color_mod(lua_State* L) {
    image_t* i = (image_t*)luaL_checkudata(L, 1, "image_t");
    int r = lua_tointeger(L, 2);
    int g = lua_tointeger(L, 3);
    int b = lua_tointeger(L, 4);

    lua_pushboolean(L, image_color_mod(i, r, g, b));
    return 1;
}


int l_image_alpha_mod(lua_State* L) {
    image_t* i = (image_t*)luaL_checkudata(L, 1, "image_t");
    int a = lua_tointeger(L, 2);

    lua_pushboolean(L, image_alpha_mod(i, a));
    return 1;
}

int l_image_get(lua_State* L) {
    // Arguments: engine pointer, destination table, properties table (optional)
    image_t* i = (image_t*)luaL_checkudata(L, 1, "image_t");
    luaL_checktype(L, 2, LUA_TTABLE);

    if(lua_istable(L, 3)) {
        // Iterate over keys
        lua_pushnil(L);  /* first key */
        while(lua_next(L, 3) != 0) {
            const char* name = lua_tostring(L, -1);

            if(strncmp(name, "w", 2) == 0) {
                lua_pushinteger(L, i->texturewidth);
                lua_setfield(L, 2, "w");
            } else if(strncmp(name, "h", 2) == 0) {
                lua_pushinteger(L, i->textureheight);
                lua_setfield(L, 2, "h");
            } else if(strncmp(name, "tw", 3) == 0) {
                lua_pushinteger(L, i->tw);
                lua_setfield(L, 2, "tw");
            } else if(strncmp(name, "th", 3) == 0) {
                lua_pushinteger(L, i->th);
                lua_setfield(L, 2, "th");
            }

            /* removes 'value'; keeps 'key' for next iteration */
            lua_pop(L, 1);
        }

        // pop final key
        lua_pop(L, 1);
    } else {
        // x, y, w, h, title
        lua_pushinteger(L, i->tw);
        lua_setfield(L, 2, "tw");
        lua_pushinteger(L, i->th);
        lua_setfield(L, 2, "th");
        lua_pushinteger(L, i->texturewidth);
        lua_setfield(L, 2, "w");
        lua_pushinteger(L, i->textureheight);
        lua_setfield(L, 2, "h");
    }

    return 0;
}

int l_image_draw_text(lua_State* L) {
    image_t* i = (image_t*)luaL_checkudata(L, 1, "image_t");
    const char* text = luaL_checkstring(L, 2);
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    int width = luaL_checkinteger(L, 5);

    image_draw_text(i, text, x, y, width);
    return 0;
}

int l_image_scale(lua_State* L) {
    image_t* i = (image_t*)luaL_checkudata(L, 1, "image_t");
    double scale = luaL_checknumber(L, 2);

    lua_pushinteger(L, image_scale(i, scale));
    return 1;
}

int l_image_target_image(lua_State* L) {
    image_t* i = (image_t*)luaL_checkudata(L, 1, "image_t");
    image_t* j = NULL;
    if(!lua_isnil(L, 2))
        j = (image_t*)luaL_checkudata(L, 2, "image_t");

    lua_pushboolean(L, image_target_image(i, j));
    return 1;
}

void load_image_bridge(lua_State* L) {
  const luaL_Reg imagelib[] = {
    {"load", l_image_load},
    {"destroy", l_image_destroy},
    {"draw", l_image_draw},
    {"drawWhole", l_image_draw_whole},
    {"drawTile", l_image_draw_tile},
    {"drawText", l_image_draw_text},
    {"get", l_image_get},
    {"scale", l_image_scale},
    {"colorMod", l_image_color_mod},
    {"alphaMod", l_image_alpha_mod},
    {"targetImage", l_image_target_image},
    {"createBlank", l_image_create_blank},
    {NULL, NULL}
  };
  luaL_newlib(L, imagelib);
}
