// TODO license

#include "sound_bridge.h"

#include <lua.h>

#include "lua_helpers.h"
#include "sound.h"

int l_sound_deinit(lua_State* L) {
    sound_t* sound = luaL_checkudata(L, 1, "sound_t");
    sound_deinit(sound);
    return 0;
}

int l_sound_read(lua_State* L) {
    const char* file = luaL_checkstring(L, 1);

    sound_t* s = (sound_t*)lua_newuserdata(L, sizeof(sound_t));
    
    if(!sound_init(s, file)) {
        lua_pushnil(L);
        lua_pushfstring(L, "failed to load sound: %s\n", SDL_GetError());
        return 2;
    }

    set_gc_metamethod(L, "sound_t", l_sound_deinit);
    return 1;
}

int l_sound_play(lua_State* L) {
    sound_t* sound = luaL_checkudata(L, 1, "sound_t");
    int channel = luaL_checkinteger(L, 2);
    int nloops = luaL_checkinteger(L, 3);
    int duration = luaL_checkinteger(L, 4);

    sound_play(sound, channel, nloops, duration);
    return 1;
}


int l_set_sound_channel_volume(lua_State* L) {
    int chan = luaL_checkinteger(L, 1);
    double l = luaL_checknumber(L, 2);
    double r = luaL_checknumber(L, 3);

    lua_pushboolean(L, soundchannel_set_volume(chan, l, r));
    return 1;
}

int l_sound_channel_reallocate(lua_State* L) {
    int nchannels = luaL_checkinteger(L, 1);

    soundchannel_reallocate(nchannels);
    return 0;
}

void load_sound_bridge(lua_State* L) {
  const luaL_Reg soundlib[] = {
    {"read", l_sound_read},
    {"play", l_sound_play},
    {"setChannelVolume", l_set_sound_channel_volume},
    {"reallocateChannels", l_sound_channel_reallocate},
    {NULL, NULL}
  };

  luaL_newlib(L, soundlib);
}
