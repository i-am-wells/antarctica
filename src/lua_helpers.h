// TODO license

#ifndef LUA_HELPERS_H_
#define LUA_HELPERS_H_

#include <lua.h>
#include <lauxlib.h>

#include "object.h"

// Store a destructor for Lua to use when garbage-collecting our structures
void set_gc_metamethod(lua_State* L, const char* udataname, lua_CFunction fn);

void set_int_field(lua_State* L, const char* key, int val);

// TODO get rid of these
void get_object_table(lua_State* L, object_t* o);
void collision_callback(void* d, object_t* oA, object_t* oB);
void object_update_callback(void* d, object_t* oA);
void bump_callback(void* d, object_t* oA, int directionmask);

#endif  // LUA_HELPERS_H_
