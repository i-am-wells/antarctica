// TODO license

#include "object_bridge.h"

#include <lua.h>

#include "lua_helpers.h"
#include "object.h"
#include "tilemap.h"

int l_object_deinit(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    object_deinit(o);

    return 0;
}

int l_object_create(lua_State* L) {
    // Object table
    luaL_checktype(L, 1, LUA_TTABLE);

    image_t* image = (image_t*)luaL_checkudata(L, 2, "image_t");
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    int layer = luaL_checkinteger(L, 5);
    int tx = luaL_checkinteger(L, 6);
    int ty = luaL_checkinteger(L, 7);
    int tw = luaL_checkinteger(L, 8);
    int th = luaL_checkinteger(L, 9);
    int acount = luaL_checkinteger(L, 10);
    int aperiod = luaL_checkinteger(L, 11);

    object_t* o = (object_t*)lua_newuserdata(L, sizeof(object_t));
    
    // Store the object table in registry
    lua_pushlightuserdata(L, o);
    lua_pushvalue(L, 1);
    lua_settable(L, LUA_REGISTRYINDEX);

    object_init(o, image, tx, ty, tw, th, aperiod, acount, x, y, layer);

    set_gc_metamethod(L, "object_t", l_object_deinit);

    return 1;
}


int l_object_set_bounding_box(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    int w = luaL_checkinteger(L, 4);
    int h = luaL_checkinteger(L, 5);
   
    object_set_bounding_box(o, x, y, w, h);
    return 0;
}


int l_object_move_relative(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    object_t* o = (object_t*)luaL_checkudata(L, 2, "object_t");
    
    int dx = luaL_checkinteger(L, 3);
    int dy = luaL_checkinteger(L, 4);

    tilemap_move_object_relative(t, o, dx, dy);
    return 0;
}


int l_object_move_absolute(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    object_t* o = (object_t*)luaL_checkudata(L, 2, "object_t");
    
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);

    tilemap_move_object_absolute(t, o, x, y);
    return 0;
}


int l_object_set_sprite(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    
    int tx = luaL_checkinteger(L, 2);
    int ty = luaL_checkinteger(L, 3);
    int tw = luaL_checkinteger(L, 4);
    int th = luaL_checkinteger(L, 5);

    int acount = luaL_checkinteger(L, 6);
    int aperiod = luaL_checkinteger(L, 7);
    int offX = luaL_checkinteger(L, 8);
    int offY = luaL_checkinteger(L, 9);
    
    object_set_sprite(o, tx, ty, tw, th, acount, aperiod, offX, offY);
    return 0;
}


int l_object_set_x_velocity(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    int vx = luaL_checkinteger(L, 2);

    object_set_x_velocity(o, vx);
    
    return 0;
}


int l_object_set_y_velocity(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    int vy = luaL_checkinteger(L, 2);

    object_set_y_velocity(o, vy);
    
    return 0;
}

int l_object_set_velocity(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    int vx = luaL_checkinteger(L, 2);
    int vy = luaL_checkinteger(L, 3);

    object_set_velocity(o, vx, vy);
    
    return 0;
}

int l_object_get_location(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    
    lua_pushinteger(L, o->x);
    lua_pushinteger(L, o->y);
    return 2;
}


int l_object_remove_self(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    o->toRemove = 1;

    return 0;
}


int l_object_set_image(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    image_t* i = (image_t*)luaL_checkudata(L, 2, "image_t");

    object_set_image(o, i);

    return 0;
}


void load_object_bridge(lua_State* L) {
const luaL_Reg objectlib[] = {
    {"create", l_object_create},
    {"setSprite", l_object_set_sprite},
    {"moveRelative", l_object_move_relative},
    {"moveAbsolute", l_object_move_absolute},
    {"setXVelocity", l_object_set_x_velocity},
    {"setYVelocity", l_object_set_y_velocity},
    {"setVelocity", l_object_set_velocity},
    {"getLocation", l_object_get_location},
    {"setBoundingBox", l_object_set_bounding_box},
    {"removeSelf", l_object_remove_self},
    {"setImage", l_object_set_image},
    {NULL, NULL}
};
    luaL_newlib(L, objectlib);
}
