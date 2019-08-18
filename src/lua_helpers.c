// TODO license

#include "lua_helpers.h"

void set_int_field(lua_State* L, const char* key, int val) {
    lua_pushinteger(L, val);
    lua_setfield(L, -2, key);
}


// TODO get rid of these!

// Pushes o onto the stack and then replaces it with the corresponding Object table
void get_object_table(lua_State* L, object_t* o) {
    lua_pushlightuserdata(L, o);    
    lua_gettable(L, LUA_REGISTRYINDEX);
}


// for running lua callbacks on object-wall and object-object collision
void bump_callback(void* d, object_t* oA, int directionmask) {
    lua_State* L = (lua_State*)d;

    get_object_table(L, oA);
    if(lua_getfield(L, -1, "onwallbump") == LUA_TFUNCTION) {
        // push a copy of oA's table and the direction mask
        lua_pushvalue(L, -2);
        lua_pushinteger(L, directionmask);
        lua_call(L, 2, 0);
    } else {
        lua_pop(L, 1);
    }

    // pop oA's table
    lua_pop(L, 1);
}


void collision_callback(void* d, object_t* oA, object_t* oB) {
    lua_State* L = (lua_State*)d;

    get_object_table(L, oA);
    if(lua_isnil(L, -1)) {
        lua_pop(L, 1);
        return;
    }

    if(lua_getfield(L, -1, "oncollision") == LUA_TFUNCTION) {
        // push a copy of oA's table and oB's table
        lua_pushvalue(L, -2);
        get_object_table(L, oB);
        lua_call(L, 2, 0);
    } else {
        lua_pop(L, 1);
    }

    get_object_table(L, oB);
    if(lua_isnil(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    if(lua_getfield(L, -1, "oncollision") == LUA_TFUNCTION) {
        lua_pushvalue(L, -2); // oB table
        lua_pushvalue(L, -4); // oA table
        lua_call(L, 2, 0);
    } else {
        lua_pop(L, 1);
    }

    // pop both object tables
    lua_pop(L, 2);
}

void object_update_callback(void* d, object_t* oA) {
    lua_State* L = (lua_State*)d;

    get_object_table(L, oA);
    if(lua_isnil(L, -1)) {
        lua_pop(L, 1);
        return;
    }

    if(lua_getfield(L, -1, "onupdate") == LUA_TFUNCTION) {
        // push "self"
        lua_pushvalue(L, -2);
        lua_call(L, 1, 0);
    } else {
        lua_pop(L, 1);
    }

    // pop object table
    lua_pop(L, 1);
}

// Store a destructor for Lua to use when garbage-collecting our structures
void set_gc_metamethod(lua_State* L, const char* udataname, lua_CFunction fn) {
    // Create or get metatable
    luaL_newmetatable(L, udataname);

    // push finalizer
    lua_pushcfunction(L, fn);
    lua_setfield(L, -2, "__gc");

    // set metatable
    lua_setmetatable(L, -2);
}

