// TODO license

// for strndup
#define _POSIX_C_SOURCE 200809L

#include "tilemap_bridge.h"

#include <lua.h>
#include <string.h>

#include "lua_helpers.h"
#include "tilemap.h"

int l_tilemap_deinit(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  tilemap_deinit(t);
  return 0;
}

int l_tilemap_create_empty(lua_State* L) {
  int nlayers = luaL_checkinteger(L, 1);
  uint64_t w = luaL_checkinteger(L, 2);
  uint64_t h = luaL_checkinteger(L, 3);

  tilemap_t* t = (tilemap_t*)lua_newuserdata(L, sizeof(tilemap_t));

  if (!tilemap_init(t, nlayers, w, h)) {
    char buf[256];
    sprintf(buf, "failed to create empty %d-layer tilemap with size %zux%zu",
            nlayers, w, h);
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, buf);
    return 2;
  }

  // TODO clean up object code
  tilemap_set_object_callbacks(t, L, bump_callback, collision_callback);
  t->object_update_callback = object_update_callback;

  set_gc_metamethod(L, "tilemap_t", l_tilemap_deinit);

  return 1;
}

int l_tilemap_read(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);
  tilemap_t* t = (tilemap_t*)lua_newuserdata(L, sizeof(tilemap_t));

  if (!tilemap_read_from_file(t, filename)) {
    lua_pushboolean(L, false);
    return 1;
  }

  // TODO clean up object code
  tilemap_set_object_callbacks(t, L, bump_callback, collision_callback);
  t->object_update_callback = object_update_callback;

  set_gc_metamethod(L, "tilemap_t", l_tilemap_deinit);

  // Return the tilemap
  return 1;
}

int l_tilemap_write(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  lua_pushboolean(L, tilemap_write_to_file(t, luaL_checkstring(L, 2)));
  return 1;
}

int l_tilemap_get_draw_flags(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  lua_pushboolean(L, t->draw_flags);
  return 1;
}

int l_tilemap_set_draw_flags(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  t->draw_flags = lua_toboolean(L, 2);
  return 0;
}

int l_tilemap_draw_layer(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  uint64_t px = luaL_checkinteger(L, 3);
  uint64_t py = luaL_checkinteger(L, 4);

  tilemap_draw_layer(t, layer, px, py);
  return 0;
}

int l_tilemap_draw_layer_objects(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  uint64_t px = luaL_checkinteger(L, 3);
  uint64_t py = luaL_checkinteger(L, 4);

  tilemap_draw_objects(t, layer, px, py);
  return 0;
}

// TODO update this?
int l_tilemap_get(lua_State* L) {
  // Arguments: engine pointer, destination table, properties table (optional)
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  luaL_checktype(L, 2, LUA_TTABLE);

  if (lua_istable(L, 3)) {
    // Iterate over keys
    lua_pushnil(L); /* first key */
    while (lua_next(L, 3) != 0) {
      const char* name = lua_tostring(L, -1);

      if (strncmp(name, "w", 2) == 0) {
        lua_pushinteger(L, t->w);
        lua_setfield(L, 2, "w");
      } else if (strncmp(name, "h", 2) == 0) {
        lua_pushinteger(L, t->h);
        lua_setfield(L, 2, "h");
      } else if (strncmp(name, "nlayers", 8) == 0) {
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

int l_tilemap_set_camera_object(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  object_t* o = (object_t*)luaL_checkudata(L, 2, "object_t");

  tilemap_set_camera_object(t, o);

  return 0;
}

int l_tilemap_get_camera_object(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");

  object_t* o = tilemap_get_camera_object(t);
  if (o) {
    get_object_table(L, o);
  } else {
    lua_pushnil(L);
  }

  return 1;
}

int l_tilemap_get_camera_draw_location(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");

  uint64_t x, y;
  tilemap_get_camera_draw_location(t, &x, &y);
  lua_pushinteger(L, x);
  lua_pushinteger(L, y);
  return 2;
}

int l_tilemap_update_objects(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  tilemap_update_objects(t);
  return 0;
}

int l_tilemap_draw_layer_at_camera_object(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  tilemap_draw_layer_at_camera_object(t, layer);
  return 0;
}

int l_tilemap_draw_objects_at_camera_object(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  tilemap_draw_objects_at_camera_object(t, layer);
  return 0;
}

int l_tilemap_abort_update_objects(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  tilemap_abort_update_objects(t);
  return 0;
}

int l_tilemap_set_sparse_layer(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  int sparse = lua_toboolean(L, 3);
  tilemap_set_sparse_layer(t, layer, sparse);
  return 0;
}

int l_tilemap_set_underwater_color(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int r = luaL_checkinteger(L, 2);
  int g = luaL_checkinteger(L, 3);
  int b = luaL_checkinteger(L, 4);
  int a = luaL_checkinteger(L, 5);
  tilemap_set_underwater_color(t, r, g, b, a);
  return 0;
}

int l_tilemap_set_underwater(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  uint64_t x = luaL_checkinteger(L, 3);
  uint64_t y = luaL_checkinteger(L, 4);
  int underwater = lua_toboolean(L, 5);
  tilemap_set_underwater(t, layer, x, y, underwater);
  return 0;
}

int l_tilemap_get_tile_info(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  uint64_t x = luaL_checkinteger(L, 3);
  uint64_t y = luaL_checkinteger(L, 4);
  TileInfo* info = tilemap_get_tile_info(t, layer, x, y);

  // Populate table with everything but the image.
  lua_createtable(L, 3, 0);
  char* name = info->name;
  if (!name)
    name = "";
  lua_pushstring(L, name);
  lua_setfield(L, -2, "name");
  lua_pushinteger(L, info->flags);
  lua_setfield(L, -2, "flags");

  // Animation frames
  lua_createtable(L, 0, info->frame_count);
  for (int i = 0; i < info->frame_count; ++i) {
    lua_createtable(L, 2, 0);
    lua_pushinteger(L, info->frames[i].tile_x);
    lua_setfield(L, -2, "tileX");
    lua_pushinteger(L, info->frames[i].duration);
    lua_setfield(L, -2, "duration");
    lua_seti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "frames");

  // Get tile-specific flags
  lua_pushinteger(L, tilemap_get_tile_data(t, layer, x, y));
  return 2;
}

static int set_tile_info(lua_State* L, tilemap_t* t, TileInfo* info) {
  // Last arg should be tile info table
  luaL_checktype(L, -1, LUA_TTABLE);

  if (lua_getfield(L, -1, "name") == LUA_TSTRING) {
    size_t name_len = 0;
    const char* name = lua_tolstring(L, -1, &name_len);
    if (!info->name || strcmp(info->name, name) != 0) {
      if (info->name)
        free(info->name);
      info->name = strndup(name, name_len + 1);
    }
  }
  lua_pop(L, 1);

  if (lua_getfield(L, -1, "flags") == LUA_TNUMBER)
    info->flags = lua_tointeger(L, -1);
  lua_pop(L, 1);

  if (lua_getfield(L, -1, "frames") == LUA_TTABLE) {
    int frame_count = luaL_len(L, -1);
    if (tile_info_replace_frames(info, frame_count)) {
      int start_time = 0;
      for (int i = 0; i < frame_count; ++i) {
        // get AnimationFrame
        if (lua_geti(L, -1, i + 1) == LUA_TTABLE) {
          lua_getfield(L, -1, "tileX");
          info->frames[i].tile_x = luaL_optinteger(L, -1, /*default=*/0);
          lua_pop(L, 1);

          lua_getfield(L, -1, "duration");
          int duration = luaL_optinteger(L, -1, /*default=*/0);
          lua_pop(L, 1);

          info->frames[i].duration = duration;
          info->frames[i].start_time = start_time;
          start_time += duration;
        }
        lua_pop(L, 1);
      }
    }
  }
  lua_pop(L, 1);

  if (lua_getfield(L, -1, "image") == LUA_TTABLE) {
    // We just need the image_t
    if (lua_getfield(L, -1, "_image") == LUA_TUSERDATA)
      info->image = (image_t*)luaL_checkudata(L, -1, "image_t");
    lua_pop(L, 1);
  }
  lua_pop(L, 1);

  lua_pushboolean(L, true);
  return 1;
}

int l_tilemap_set_tile_info(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int tile_info_idx = luaL_checkinteger(L, 2);

  if (tile_info_idx < 0 || tile_info_idx >= t->tile_info_count)
    return 0;
  TileInfo* info = t->tile_info + tile_info_idx;

  return set_tile_info(L, t, info);
}

int l_tilemap_add_tile_info(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  TileInfo info;
  memset(&info, 0, sizeof(TileInfo));
  int ret = set_tile_info(L, t, &info);
  tilemap_add_tile_info(t, &info);
  return ret;
}

int l_tilemap_set_tile_info_idx_for_tile(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  uint64_t x = luaL_checkinteger(L, 3);
  uint64_t y = luaL_checkinteger(L, 4);
  int idx = luaL_checkinteger(L, 5);

  tilemap_set_tile_info_idx_for_tile(t, layer, x, y, idx);
  return 0;
}

void load_tilemap_bridge(lua_State* L) {
  const luaL_Reg tilemaplib[] = {
      {"read", l_tilemap_read},
      {"write", l_tilemap_write},
      {"createEmpty", l_tilemap_create_empty},
      {"drawLayer", l_tilemap_draw_layer},
      {"drawLayerObjects", l_tilemap_draw_layer_objects},
      {"get", l_tilemap_get},
      {"addObject", l_tilemap_add_object},
      {"removeObject", l_tilemap_remove_object},
      {"setCameraObject", l_tilemap_set_camera_object},
      {"getCameraObject", l_tilemap_get_camera_object},
      {"getCameraDrawLocation", l_tilemap_get_camera_draw_location},

      {"updateObjects", l_tilemap_update_objects},
      {"drawLayerAtCameraObject", l_tilemap_draw_layer_at_camera_object},
      {"drawObjectsAtCameraObject", l_tilemap_draw_objects_at_camera_object},
      {"setSparseLayer", l_tilemap_set_sparse_layer},
      {"setUnderwaterColor", l_tilemap_set_underwater},

      {"abortUpdateObjects", l_tilemap_abort_update_objects},

      {"getTileInfo", l_tilemap_get_tile_info},
      {"setTileInfo", l_tilemap_set_tile_info},
      {"addTileInfo", l_tilemap_add_tile_info},
      {"setTileInfoIdxForTile", l_tilemap_set_tile_info_idx_for_tile},

      {NULL, NULL}};

  luaL_newlib(L, tilemaplib);
  set_int_field(L, "actionflag", TILEMAP_ACTION_MASK);
  set_int_field(L, "bumpeastflag", TILEMAP_BUMP_EAST_MASK);
  set_int_field(L, "bumpnorthflag", TILEMAP_BUMP_NORTH_MASK);
  set_int_field(L, "bumpwestflag", TILEMAP_BUMP_WEST_MASK);
  set_int_field(L, "bumpsouthflag", TILEMAP_BUMP_SOUTH_MASK);
}
