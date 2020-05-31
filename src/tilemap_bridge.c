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
  int tw = luaL_checkinteger(L, 4);
  int th = luaL_checkinteger(L, 5);

  tilemap_t* t = (tilemap_t*)lua_newuserdata(L, sizeof(tilemap_t));

  if (!tilemap_init(t, nlayers, w, h, tw, th)) {
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
  // Tilemap table
  luaL_checktype(L, 2, LUA_TTABLE);
  tilemap_t* t = (tilemap_t*)lua_newuserdata(L, sizeof(tilemap_t));

  if (!tilemap_read_from_file(t, filename)) {
    lua_pushboolean(L, false);
    return 1;
  }

  // TODO clean up object code
  tilemap_set_object_callbacks(t, L, bump_callback, collision_callback);
  t->object_update_callback = object_update_callback;

  set_gc_metamethod(L, "tilemap_t", l_tilemap_deinit);

  // Set important fields
  lua_pushinteger(L, t->nlayers);
  lua_setfield(L, 2, "nlayers");
  lua_pushinteger(L, t->w);
  lua_setfield(L, 2, "w");
  lua_pushinteger(L, t->h);
  lua_setfield(L, 2, "h");
  lua_pushinteger(L, t->tw);
  lua_setfield(L, 2, "tw");
  lua_pushinteger(L, t->th);
  lua_setfield(L, 2, "th");

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

static inline void write_int_field(lua_State* L, const char* name, int val) {
  lua_pushinteger(L, val);
  lua_setfield(L, -2, name);
}

// Leaves the tile info table on the stack.
static void tile_info_to_lua(lua_State* L, TileInfo* info) {
  // Populate table with everything but the image.
  lua_createtable(L, /*nrec=*/9, /*narr=*/0);
  char* name = info->name;
  if (!name)
    name = "";
  lua_pushstring(L, name);
  lua_setfield(L, -2, "name");

  char* image_path = info->image_path;
  if (!image_path)
    image_path = "";
  lua_pushstring(L, image_path);
  lua_setfield(L, -2, "imagePath");

  write_int_field(L, "flags", info->flags);
  write_int_field(L, "w", info->w);
  write_int_field(L, "h", info->h);
  write_int_field(L, "sx", info->sx);
  write_int_field(L, "sy", info->sy);
  write_int_field(L, "dx", info->dx);
  write_int_field(L, "dy", info->dy);

  // Animation frames
  lua_createtable(L, 0, info->frame_count);
  for (int i = 0; i < info->frame_count; ++i) {
    lua_createtable(L, /*nrec=*/2, /*narr=*/0);
    write_int_field(L, "x", info->frames[i].x);
    write_int_field(L, "y", info->frames[i].y);
    write_int_field(L, "duration", info->frames[i].duration);
    lua_seti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "frames");
}

int l_tilemap_get_tile_info(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  uint64_t x = luaL_checkinteger(L, 3);
  uint64_t y = luaL_checkinteger(L, 4);

  tile_info_to_lua(L, tilemap_get_tile_info(t, layer, x, y));
  lua_pushinteger(L, tilemap_get_tile_data(t, layer, x, y));
  return 2;
}

static inline int read_int_field(lua_State* L, const char* name) {
  int result = 0;
  if (lua_getfield(L, -1, name) == LUA_TNUMBER)
    result = lua_tointeger(L, -1);
  lua_pop(L, 1);
  return result;
}

static int tile_info_from_lua(lua_State* L, tilemap_t* t, TileInfo* info) {
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

  if (lua_getfield(L, -1, "imagePath") == LUA_TSTRING) {
    size_t len = 0;
    const char* path = lua_tolstring(L, -1, &len);
    if (!info->image_path || strcmp(info->image_path, path) != 0) {
      if (info->image_path)
        free(info->image_path);
      info->image_path = strndup(path, len + 1);
    }
  }
  lua_pop(L, 1);

  info->flags = read_int_field(L, "flags");
  info->w = read_int_field(L, "w");
  info->h = read_int_field(L, "h");
  info->sx = read_int_field(L, "sx");
  info->sy = read_int_field(L, "sy");
  info->dx = read_int_field(L, "dx");
  info->dy = read_int_field(L, "dy");

  if (lua_getfield(L, -1, "frames") == LUA_TTABLE) {
    int frame_count = luaL_len(L, -1);
    if (tile_info_replace_frames(info, frame_count)) {
      int start_time = 0;
      for (int i = 0; i < frame_count; ++i) {
        // get AnimationFrame
        if (lua_geti(L, -1, i + 1) == LUA_TTABLE) {
          info->frames[i].x = read_int_field(L, "x");
          info->frames[i].y = read_int_field(L, "y");
          int duration = read_int_field(L, "duration");

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
  size_t tile_info_idx = luaL_checkinteger(L, 2);
  luaL_checktype(L, 3, LUA_TTABLE);

  if (tile_info_idx < 0ul || tile_info_idx >= t->tile_info_count)
    return 0;
  TileInfo* info = t->tile_info + tile_info_idx;

  return tile_info_from_lua(L, t, info);
}

int l_tilemap_add_tile_info(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  TileInfo info;
  memset(&info, 0, sizeof(TileInfo));
  int ret = tile_info_from_lua(L, t, &info);
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

int l_tilemap_get_tile_info_idx_for_tile(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  uint64_t x = luaL_checkinteger(L, 3);
  uint64_t y = luaL_checkinteger(L, 4);

  lua_pushinteger(L, tilemap_get_tile_info_idx_for_tile(t, layer, x, y));
  return 1;
}

int l_tilemap_get_all_tile_infos(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");

  lua_createtable(L, /*nrec=*/0, /*narr=*/t->tile_info_count);
  for (size_t i = 0; i < t->tile_info_count; ++i) {
    tile_info_to_lua(L, t->tile_info + i);
    lua_seti(L, -2, i + 1);
  }
  return 1;
}

int l_tilemap_advance_clock(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  tilemap_advance_clock(t);
  return 0;
}

int l_tilemap_set_screen_size(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  t->screen_w = luaL_checkinteger(L, 2);
  t->screen_h = luaL_checkinteger(L, 3);
  return 0;
}

int l_tilemap_synchronize_animation(lua_State* L) {
  tilemap_synchronize_animation((tilemap_t*)luaL_checkudata(L, 1, "tilemap_t"));
  return 0;
}

void load_tilemap_bridge(lua_State* L) {
  const luaL_Reg tilemaplib[] = {
      {"read", l_tilemap_read},
      {"write", l_tilemap_write},
      {"createEmpty", l_tilemap_create_empty},
      {"drawLayer", l_tilemap_draw_layer},
      {"drawLayerObjects", l_tilemap_draw_layer_objects},
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
      {"getAllTileInfos", l_tilemap_get_all_tile_infos},
      {"setTileInfo", l_tilemap_set_tile_info},
      {"addTileInfo", l_tilemap_add_tile_info},
      {"setTileInfoIdxForTile", l_tilemap_set_tile_info_idx_for_tile},
      {"getTileInfoIdxForTile", l_tilemap_get_tile_info_idx_for_tile},
      {"synchronizeAnimation", l_tilemap_synchronize_animation},

      // TODO get rid of these, add engine field to map
      {"advanceClock", l_tilemap_advance_clock},
      {"setScreenSize", l_tilemap_set_screen_size},

      {NULL, NULL}};

  luaL_newlib(L, tilemaplib);
  set_int_field(L, "actionflag", TILEMAP_ACTION_MASK);
  set_int_field(L, "bumpeastflag", TILEMAP_BUMP_EAST_MASK);
  set_int_field(L, "bumpnorthflag", TILEMAP_BUMP_NORTH_MASK);
  set_int_field(L, "bumpwestflag", TILEMAP_BUMP_WEST_MASK);
  set_int_field(L, "bumpsouthflag", TILEMAP_BUMP_SOUTH_MASK);
}
