/**
 *  \file lantarcticalib.h
 */

#ifndef _LANTARCTICALIB_H
#define _LANTARCTICALIB_H

#include <lua.h>


/**
 *  Lua C function to load the antarctica library for use in Lua.
 *
 *  \param L    Lua state
 *  
 *  \return Always 1 (to tell Lua that we have left the library on the stack)
 */
int luaopen_antarctica(lua_State * L);

#endif


