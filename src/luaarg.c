#include <string.h>

#include <lua.h>
#include <lauxlib.h>

#include "luaarg.h"


int luaarg_get_value_from_stack(lua_State* L, int idx, int type, luaarg_t* arg) {
    arg->val.type = type;

    switch(type) {
        case LUA_TBOOLEAN:
            arg->val.val.boolean = lua_toboolean(L, idx);
            break;

        case LUA_TLIGHTUSERDATA:
        case LUA_TUSERDATA:
            arg->val.val.userdata = lua_touserdata(L, idx);
            break;

        case LUA_TNUMBER:
            arg->val.val.number = lua_tonumber(L, idx);
            break;

        case LUA_TSTRING:
            arg->val.val.string = (char*)lua_tostring(L, idx);
            break;

        case LUA_TTABLE:
        case LUA_TFUNCTION:
        case LUA_TTHREAD:
            arg->val.val.index = idx;
        
        case LUA_TNIL:
        default:
            break;
    }

    return 1;
}


void luaarg_check_type(lua_State* L, int actualtype, const luaarg_t* arg, int argi) {
    if(!arg->required && (actualtype == LUA_TNIL))
        return;

    // If actualtype isn't in the set of types allowed for arg, give an error
    if(!(LUA_TYPE_FLAG(actualtype) & arg->typeflags)) {
        luaL_error(L, "type \"%s\" not allowed for argument #%d (\"%s\")",
                lua_typename(L, actualtype),
                argi,
                arg->key);
    }
}


int luaarg_find_positional(lua_State* L, luaarg_t* args) {
    int argc = lua_gettop(L);

    int argi = 1;
    for(luaarg_t* arg = args; arg->key && (argi <= argc); arg++) {
        if(!arg->found && arg->required) {

            // Is the argument the right type?
            int actualtype = lua_type(L, argi);
            luaarg_check_type(L, actualtype, arg, argi);

            // Copy value
            luaarg_get_value_from_stack(L, argi, actualtype, arg);

            // mark as found
            arg->found = 1;
        }

        argi++;
    }

    return 1;
}


// Returns the number of values it pushed onto the stack.
int luaarg_find_keyword(lua_State* L, int tableidx, luaarg_t* args) {
    int argi = 1;
    int npushed = 0;
    for(luaarg_t* arg = args; arg->key; arg++) {
        int actualtype = lua_getfield(L, tableidx, arg->key);
        // If the value is nil, it might mean that the key isn't in the table
        if(actualtype == LUA_TNIL) {
            // Try by array key
            actualtype = lua_geti(L, tableidx, argi);
        }

        // If not found in table and not marked found in arg list, if required, give error, else use default
        if(!arg->found && (actualtype == LUA_TNIL)) {
            if(arg->required) {
                luaL_error(L, "missing required argument #%d (\"%s\")", argi, arg->key);
            } else {
                argi++;
                continue;
            }
        }

        // Check type
        luaarg_check_type(L, actualtype, arg, argi);

        // Get value
        luaarg_get_value_from_stack(L, -1, actualtype, arg);

        if((actualtype == LUA_TTABLE)
                || (actualtype == LUA_TTHREAD)
                || (actualtype == LUA_TFUNCTION)) {
            npushed++;
        }

        // mark as found
        arg->found = 1;

        argi++;
    }

    return npushed;
}


int luaarg_check_required(lua_State* L, const luaarg_t* args) {
    int argi = 1;

    // Iterate over all arguments. If an argument is required but not found,
    // give an error.
    for(const luaarg_t* arg = args; arg->key; arg++) {
        if(arg->required && !arg->found) {
            return luaL_error(L, "missing required argument #%d (\"%s\")", argi, arg->key);
        }
        argi++;
    }

    return 1;
}


// Returns number of elements it placed on the stack
int luaarg_check(lua_State* L, luaarg_t* args) {
    int argc = lua_gettop(L);

    int npushed = 0;

    if(argc) {
        // If the last argument is a table, check for keyword arguments
        if(lua_istable(L, argc)) {
            npushed += luaarg_find_keyword(L, argc, args);
        }

        // Try to find positional arguments first
        if(!luaarg_find_positional(L, args))
            return -1;
    }

    // Did we find all of the required arguments?
    if(!luaarg_check_required(L, args))
        return -1;

    return npushed;
}


