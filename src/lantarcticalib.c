
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <SDL.h>

#include <luaarg.h>

#include "engine.h"
#include "image.h"
#include "tilemap.h"
#include "object.h"

#include "lantarcticalib.h"


// Store a destructor for Lua to use when garbage-collecting our structures
static void set_gc_metamethod(lua_State* L, const char* udataname, lua_CFunction fn) {
    // Create or get metatable
    luaL_newmetatable(L, udataname);

    // push finalizer
    lua_pushcfunction(L, fn);
    lua_setfield(L, -2, "__gc");

    // set metatable
    lua_setmetatable(L, -2);
}


// Release memory for an engine_t
int l_engine_destroy(lua_State* L) {
    engine_t* e = (engine_t*)luaL_checkudata(L, 1, "engine_t");
    engine_deinit(e);

    // now the garbage collector can reclaim e
    return 0;
}


// Create an engine_t
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
        LOPTIONALNUMBER("rendererflags", SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC),
        LNULL
    };
    if(luaarg_check(L, args) == -1) {
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
    engine_t * e = (engine_t*)lua_newuserdata(L, sizeof(engine_t));

    // Register event handler table (registry[e] := handler table)
    lua_pushlightuserdata(L, e);
    lua_newtable(L);
    lua_settable(L, LUA_REGISTRYINDEX);

    // If this fails, return (nil, error message)
    if(!engine_init(e, wtitle, x, y, w, h, wflags, ridx, rflags)) {
        lua_pop(L, 1);
        lua_pushnil(L);
        lua_pushstring(L, SDL_GetError());
        return 2;
        //luaL_error(L, "failed to create engine: %s", SDL_GetError());
    }

    // Set destructor for garbage-collection
    set_gc_metamethod(L, "engine_t", l_engine_destroy);

    // We are left with only e on the stack; return it
    return 1;
}


// Set the 
int l_engine_sethandler(lua_State* L) {
    engine_t* e = (engine_t*)lua_touserdata(L, 1);
    //int type = lua_tonumber(L, 2);

    // Push the event handler table
    lua_pushlightuserdata(L, e);
    lua_gettable(L, LUA_REGISTRYINDEX);

    // Store the handler
    lua_pushnil(L);
    lua_pushnil(L);
    lua_copy(L, 2, -2); // key: type
    lua_copy(L, 3, -1); // value: handler
    lua_settable(L, -3);

    // Pop the event handler table
    lua_pop(L, 1);

    return 0;
}


int l_engine_setredraw(lua_State* L) {
    engine_t* e = (engine_t*)lua_touserdata(L, 1);

    lua_pushlightuserdata(L, e+1); // redraw key
    lua_pushnil(L);
    lua_copy(L, 2, -1); // redraw function
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

    e->running = 0;
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


static const luaL_Reg enginelib[] = {
    {"create", l_engine_create},
    {"destroy", l_engine_destroy},
    {"sethandler", l_engine_sethandler},
    {"setredraw", l_engine_setredraw},
    {"run", l_engine_run},
    {"stop", l_engine_stop},
    {"drawpoint", l_engine_draw_point},
    {"drawline", l_engine_draw_line},
    {"drawrect", l_engine_draw_rect},
    {"fillrect", l_engine_fill_rect},
    {"clear", l_engine_clear},
    {"setcolor", l_engine_set_draw_color},
    {"getcolor", l_engine_get_draw_color},
    {"setlogicalsize", l_engine_set_logical_size},
    {NULL, NULL}
};

// Image things

int l_image_destroy(lua_State* L) {
    image_t* i = (image_t*)lua_touserdata(L, 1);
    image_deinit(i);
    return 0;
}


int l_image_load(lua_State* L) {
    /*
    luaarg_t args[] = {
        LREQUIREDTABLE("engine"),
        LREQUIREDSTRING("file", ""),
        LOPTIONALNUMBER("tilew", 16),
        LOPTIONALNUMBER("tileh", 16),
        LNULL
    };
    if(luaarg_check(L, args) == -1)
        return 0;
    */

    //engine_t* e = (engine_t*)LUSERDATA_VALUE(args[0]);
    //char* filename = LSTRING_VALUE(args[1]);
    //int tw = LNUMBER_VALUE(args[2]);
    //int th = LNUMBER_VALUE(args[3]);

    // Get engine pointer
    //lua_getfield(L, -1, "_engine");
    //engine_t* e = (engine_t*)luaL_checkudata(L, -1, "engine_t");
    //lua_pop(L, 2);
    
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
        //return luaL_error(L, "failed to create image: %s", SDL_GetError());
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


static const luaL_Reg imagelib[] = {
    {"load", l_image_load},
    {"destroy", l_image_destroy},
    {"draw", l_image_draw},
    {"drawwhole", l_image_draw_whole},
    {"drawtile", l_image_draw_tile},
    {"get", l_image_get},
    {NULL, NULL}
};

/*
tilemap_t * tilemap_create(size_t nlayers, size_t w, size_t h);

void tilemap_destroy(tilemap_t * t);

int tilemap_init(tilemap_t * t, size_t nlayers, size_t w, size_t h);

tile_t * tilemap_get_tile_address(tilemap_t * t, size_t layer, size_t x, size_t y);

void tilemap_draw_layer(const tilemap_t* t, const image_t* i, int l, int px, int py, int pw, int ph);

int tilemap_read_from_file(tilemap_t * t, const char * path);

int tilemap_write_to_file(tilemap_t * t, const char * path);
*/


int l_tilemap_deinit(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    tilemap_deinit(t);
    return 0;
}


int l_tilemap_create_empty(lua_State* L) {
    int nlayers = luaL_checkinteger(L, 1);
    int w = luaL_checkinteger(L, 2);
    int h = luaL_checkinteger(L, 3);

    tilemap_t* t = (tilemap_t*)lua_newuserdata(L, sizeof(tilemap_t));
    
    if(!tilemap_init(t, nlayers, w, h)) {
        char buf[256];
        sprintf(buf, "failed to create empty %d-layer tilemap with size %dx%d", nlayers, w, h);
        lua_pop(L, 1);
        lua_pushnil(L);
        lua_pushstring(L, buf);
        return 2;
    }

    set_gc_metamethod(L, "tilemap_t", l_tilemap_deinit);

    return 1;
}


int l_tilemap_read(lua_State* L) {
    const char* filename = luaL_checkstring(L, 1);
    
    tilemap_t* t = (tilemap_t*)lua_newuserdata(L, sizeof(tilemap_t));

    if(!tilemap_read_from_file(t, filename)) {
        char buf[256];
        sprintf(buf, "failed to load tilemap file from %s", filename);
        lua_pop(L, 1);
        lua_pushnil(L);
        lua_pushstring(L, buf);
        return 2;
        //return luaL_error(L, "failed to load tilemap file from %s", filename);
    }

    set_gc_metamethod(L, "tilemap_t", l_tilemap_deinit);

    // Return the tilemap
    return 1;
}


// TODO return error
int l_tilemap_write(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    const char* filename = luaL_checkstring(L, 2);

    if(!tilemap_write_to_file(t, filename)) {
        return luaL_error(L, "failed to write tilemap to %s", filename);
    }

    lua_pushboolean(L, 1);
    return 1;
}

// TODO make layer, flags, etc. options to one function

int l_tilemap_draw_layer(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    image_t* i = (image_t*)luaL_checkudata(L, 2, "image_t");
    int layer = luaL_checkinteger(L, 3);
    int px = luaL_checkinteger(L, 4);
    int py = luaL_checkinteger(L, 5);
    int pw = luaL_checkinteger(L, 6);
    int ph = luaL_checkinteger(L, 7);
    
    tilemap_draw_layer(t, i, layer, px, py, pw, ph);

    return 0;
}


int l_tilemap_draw_layer_flags(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    image_t* i = (image_t*)luaL_checkudata(L, 2, "image_t");
    int layer = luaL_checkinteger(L, 3);
    int px = luaL_checkinteger(L, 4);
    int py = luaL_checkinteger(L, 5);
    int pw = luaL_checkinteger(L, 6);
    int ph = luaL_checkinteger(L, 7);
    
    tilemap_draw_layer_flags(t, i, layer, px, py, pw, ph);

    return 0;
}


int l_tilemap_draw_layer_objects(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    int layer = luaL_checkinteger(L, 2);
    int px = luaL_checkinteger(L, 3);
    int py = luaL_checkinteger(L, 4);
    int pw = luaL_checkinteger(L, 5);
    int ph = luaL_checkinteger(L, 6);
    
    tilemap_draw_objects(t, layer, px, py, pw, ph);

    return 0;
}


int l_tilemap_set_tile(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    int layer = luaL_checkinteger(L, 2);
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    int tx = luaL_checkinteger(L, 5);
    int ty = luaL_checkinteger(L, 6);
    
    tilemap_set_tile(t, layer, x, y, tx, ty);

    return 0;
}


int l_tilemap_get_flags(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    int layer = luaL_checkinteger(L, 2);
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    
    int flags = tilemap_get_flags(t, layer, x, y);
    
    lua_pushinteger(L, flags);
    return 1;
}

int l_tilemap_set_flags(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    int layer = luaL_checkinteger(L, 2);
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    int mask = luaL_checkinteger(L, 5);
    
    tilemap_set_flags(t, layer, x, y, mask);
    return 0;
}

int l_tilemap_clear_flags(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    int layer = luaL_checkinteger(L, 2);
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    int mask = luaL_checkinteger(L, 5);
    
    tilemap_clear_flags(t, layer, x, y, mask);
    return 0;
}

int l_tilemap_overwrite_flags(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    int layer = luaL_checkinteger(L, 2);
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    int mask = luaL_checkinteger(L, 5);
    
    tilemap_overwrite_flags(t, layer, x, y, mask);
    return 0;
}


int l_tilemap_export_slice(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    int w = luaL_checkinteger(L, 4);
    int h = luaL_checkinteger(L, 5);

    tile_t* slice = tilemap_export_slice(t, x, y, w, h);
    if(!slice) {
        lua_pushnil(L);
        return 1;
    }

    // Copy the slice into userdata
    size_t size = t->nlayers * w * h * sizeof(tile_t);
    tile_t* slice_udata = (tile_t*)lua_newuserdata(L, size);
    memcpy(slice_udata, slice, size);
    free(slice);

    // Return the slice userdata
    return 1;
}


int l_tilemap_patch(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    tile_t* patch_udata = (tile_t*)lua_touserdata(L, 2);
    if(!patch_udata)
        return 0;

    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    int w = luaL_checkinteger(L, 5);
    int h = luaL_checkinteger(L, 6);
    
    tilemap_patch(t, patch_udata, x, y, w, h);

    return 0;
}


int l_tilemap_get(lua_State* L) {
    // Arguments: engine pointer, destination table, properties table (optional)
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    luaL_checktype(L, 2, LUA_TTABLE);

    if(lua_istable(L, 3)) {
        // Iterate over keys
        lua_pushnil(L);  /* first key */
        while(lua_next(L, 3) != 0) {
            const char* name = lua_tostring(L, -1);

            if(strncmp(name, "w", 2) == 0) {
                lua_pushinteger(L, t->w);
                lua_setfield(L, 2, "w");
            } else if(strncmp(name, "h", 2) == 0) {
                lua_pushinteger(L, t->h);
                lua_setfield(L, 2, "h");
            } else if(strncmp(name, "nlayers", 8) == 0) {
                lua_pushinteger(L, t->nlayers);
                lua_setfield(L, 2, "nlayers");
            }

            /* removes 'value'; keeps 'key' for next iteration */
            lua_pop(L, 1);
        }

        // pop final key
        lua_pop(L, 1);
    } else {
        lua_pushinteger(L, t->w);
        lua_setfield(L, 2, "w");
        lua_pushinteger(L, t->h);
        lua_setfield(L, 2, "h");
        lua_pushinteger(L, t->nlayers);
        lua_setfield(L, 2, "nlayers");
    }

    return 0;
}


int l_tilemap_add_object(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    object_t* o = (object_t*)luaL_checkudata(L, 2, "object_t");

    tilemap_add_object(t, o);
    
    return 0;
}


int l_tilemap_remove_object(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    object_t* o = (object_t*)luaL_checkudata(L, 2, "object_t");

    tilemap_remove_object(t, o);
    
    return 0;
}



static const luaL_Reg tilemaplib[] = {
    {"read", l_tilemap_read},
    {"write", l_tilemap_write},
    {"create_empty", l_tilemap_create_empty},
    {"draw_layer", l_tilemap_draw_layer},
    {"draw_layer_flags", l_tilemap_draw_layer_flags},
    {"draw_layer_objects", l_tilemap_draw_layer_objects},
    {"set_tile", l_tilemap_set_tile},
    {"get_flags", l_tilemap_get_flags},
    {"set_flags", l_tilemap_set_flags},
    {"clear_flags", l_tilemap_clear_flags},
    {"overwrite_flags", l_tilemap_overwrite_flags},
    {"export_slice", l_tilemap_export_slice},
    {"patch", l_tilemap_patch},
    {"get", l_tilemap_get},
    {"addobject", l_tilemap_add_object},
    {"removeobject", l_tilemap_remove_object},
    {NULL, NULL}
};


// object_t methods

int l_object_deinit(lua_State* L) {
    object_t* o = (object_t*)luaL_checkudata(L, 1, "object_t");
    object_deinit(o);

    return 0;
}

int l_object_create(lua_State* L) {
    image_t* image = (image_t*)luaL_checkudata(L, 1, "image_t");
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    int layer = luaL_checkinteger(L, 4);
    int tx = luaL_checkinteger(L, 5);
    int ty = luaL_checkinteger(L, 6);
    int tw = luaL_checkinteger(L, 7);
    int th = luaL_checkinteger(L, 8);
    int acount = luaL_checkinteger(L, 9);
    int aperiod = luaL_checkinteger(L, 10);
        /*
        options.image._image,
        options.x,
        options.y,
        options.layer,
        options.tx,
        options.ty,
        options.animation_count,
        options.animation_period
    */

    object_t* o = (object_t*)lua_newuserdata(L, sizeof(object_t));
    
    object_init(o, image, tx, ty, tw, th, aperiod, acount, x, y, layer);

    set_gc_metamethod(L, "object_t", l_object_deinit);

    return 1;
}


int l_object_move_relative(lua_State* L) {
    tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
    object_t* o = (object_t*)luaL_checkudata(L, 2, "object_t");
    
    int dx = luaL_checkinteger(L, 3);
    int dy = luaL_checkinteger(L, 4);

    tilemap_move_object_relative(t, o->index, dx, dy);
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
    int acount = luaL_checkinteger(L, 4);
    int aperiod = luaL_checkinteger(L, 5);

    object_set_sprite(o, tx, ty, acount, aperiod);
    return 0;
}


static const luaL_Reg objectlib[] = {
    {"create", l_object_create},
    {"set_sprite", l_object_set_sprite},
    {"move_relative", l_object_move_relative},
    {"move_absolute", l_object_move_absolute},
    {NULL, NULL}
};


// TODO maybe put window/renderer constants in
static const luaL_Reg antarcticalib[] = {
    {NULL, NULL}
};

static void set_int_field(lua_State* L, const char* key, int val) {
    lua_pushinteger(L, val);
    lua_setfield(L, -2, key);
}

int luaopen_antarctica(lua_State * L) {
    // Create module table
    luaL_newlib(L, antarcticalib);

    // Load submodules
    
    // engine
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

    lua_setfield(L, -2, "engine");

    // image
    luaL_newlib(L, imagelib); 
    lua_setfield(L, -2, "image");

    // tilemap
    luaL_newlib(L, tilemaplib);
    set_int_field(L, "actionflag", TILEMAP_ACTION_MASK);
    set_int_field(L, "bumpeastflag", TILEMAP_BUMP_EAST_MASK);
    set_int_field(L, "bumpnorthflag", TILEMAP_BUMP_NORTH_MASK);
    set_int_field(L, "bumpwestflag", TILEMAP_BUMP_WEST_MASK);
    set_int_field(L, "bumpsouthflag", TILEMAP_BUMP_SOUTH_MASK);
    lua_setfield(L, -2, "tilemap");

    // object
    luaL_newlib(L, objectlib);
    lua_setfield(L, -2, "object");

    return 1;
}

