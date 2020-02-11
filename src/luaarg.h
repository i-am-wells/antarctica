#ifndef _LUAARG_H
#define _LUAARG_H

#include <lua.h>

#define LUA_TYPE_FLAG(t) (1 << (t + 1))

typedef union luaval_u {
  int boolean;
  void* userdata;
  double number;
  char* string;
  int index;
} luaval_u;

typedef struct luaval_t {
  int type;
  luaval_u val;
} luaval_t;

typedef struct luaarg_t {
  char* key;
  int required;
  int typeflags;
  int found;
  luaval_t val;
} luaarg_t;

#define FLAG_NIL LUA_TYPE_FLAG(LUA_TNIL)
#define FLAG_BOOLEAN LUA_TYPE_FLAG(LUA_TBOOLEAN)
#define FLAG_LIGHTUSERDATA LUA_TYPE_FLAG(LUA_TLIGHTUSERDATA)
#define FLAG_NUMBER LUA_TYPE_FLAG(LUA_TNUMBER)
#define FLAG_STRING LUA_TYPE_FLAG(LUA_TSTRING)
#define FLAG_TABLE LUA_TYPE_FLAG(LUA_TTABLE)
#define FLAG_FUNCTION LUA_TYPE_FLAG(LUA_TFUNCTION)
#define FLAG_USERDATA LUA_TYPE_FLAG(LUA_TUSERDATA)
#define FLAG_THREAD LUA_TYPE_FLAG(LUA_TTHREAD)

#define LNIL                 \
  {                          \
    LUA_TNIL, { .index = 0 } \
  }
#define LBOOLEAN(b)                  \
  {                                  \
    LUA_TBOOLEAN, { .boolean = (b) } \
  }
#define LLIGHTUSERDATA(p)                   \
  {                                         \
    LUA_TLIGHTUSERDATA, { .userdata = (p) } \
  }
#define LNUMBER(n)                 \
  {                                \
    LUA_TNUMBER, { .number = (n) } \
  }
#define LSTRING(s)                 \
  {                                \
    LUA_TSTRING, { .string = (s) } \
  }
#define LTABLE                 \
  {                            \
    LUA_TTABLE, { .index = 0 } \
  }
#define LFUNCTION                 \
  {                               \
    LUA_TFUNCTION, { .index = 0 } \
  }
#define LUSERDATA(p)                   \
  {                                    \
    LUA_TUSERDATA, { .userdata = (p) } \
  }
#define LTHREAD                 \
  {                             \
    LUA_TTHREAD, { .index = 0 } \
  }

#define LNULL \
  { NULL, 0, 0, 0, LNIL }

#define LREQUIRED(key, typeflags, defaultval) \
  { key, 1, typeflags, 0, defaultval }

#define LREQUIREDNIL(key) LREQUIRED(key, FLAG_NIL, LNIL)
#define LREQUIREDBOOLEAN(key, value) \
  LREQUIRED(key, FLAG_BOOLEAN, LBOOLEAN(value))
#define LREQUIREDLIGHTUSERDATA(key, value) \
  LREQUIRED(key, FLAG_LIGHTUSERDATA, LLIGHTUSERDATA(value))
#define LREQUIREDNUMBER(key, value) LREQUIRED(key, FLAG_NUMBER, LNUMBER(value))
#define LREQUIREDSTRING(key, value) LREQUIRED(key, FLAG_STRING, LSTRING(value))
#define LREQUIREDTABLE(key) LREQUIRED(key, FLAG_TABLE, LTABLE)
#define LREQUIREDFUNCTION(key) LREQUIRED(key, FLAG_FUNCTION, LFUNCTION)
#define LREQUIREDUSERDATA(key, value) \
  LREQUIRED(key, FLAG_USERDATA, LUSERDATA(value))
#define LREQUIREDTHREAD(key) LREQUIRED(key, FLAG_THREAD, LTHREAD)

#define LOPTIONAL(key, typeflags, defaultval) \
  { key, 0, typeflags, 0, defaultval }

#define LOPTIONALNIL(key) LOPTIONAL(key, FLAG_NIL, LNIL)
#define LOPTIONALBOOLEAN(key, value) \
  LOPTIONAL(key, FLAG_BOOLEAN, LBOOLEAN(value))
#define LOPTIONALLIGHTUSERDATA(key, value) \
  LOPTIONAL(key, FLAG_LIGHTUSERDATA, LLIGHTUSERDATA(value))
#define LOPTIONALNUMBER(key, value) LOPTIONAL(key, FLAG_NUMBER, LNUMBER(value))
#define LOPTIONALSTRING(key, value) LOPTIONAL(key, FLAG_STRING, LSTRING(value))
#define LOPTIONALTABLE(key) LOPTIONAL(key, FLAG_TABLE, LTABLE)
#define LOPTIONALFUNCTION(key) LOPTIONAL(key, FLAG_FUNCTION, LFUNCTION)
#define LOPTIONALUSERDATA(key, value) \
  LOPTIONAL(key, FLAG_USERDATA, LUSERDATA(value))
#define LOPTIONALTHREAD(key) LOPTIONAL(key, FLAG_THREAD, LTHREAD)

// For retrieving values
#define LBOOLEAN_VALUE(a) (a.val.val.boolean)
#define LLIGHTUSERDATA_VALUE(a) (a.val.val.userdata)
#define LNUMBER_VALUE(a) (a.val.val.number)
#define LSTRING_VALUE(a) (a.val.val.string)
#define LUSERDATA_VALUE(a) (a.val.val.userdata)

int luaarg_check(lua_State* L, luaarg_t* args);

#endif
