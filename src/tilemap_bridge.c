// TODO license

#include "tilemap_bridge.h"

#include <lua.h>

#include "lua_helpers.h"
#include "tilemap.h"

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

  if (!tilemap_init(t, nlayers, w, h)) {
    char buf[256];
    sprintf(buf, "failed to create empty %d-layer tilemap with size %dx%d",
            nlayers, w, h);
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, buf);
    return 2;
  }

  // TODO clean up
  tilemap_set_object_callbacks(t, L, bump_callback, collision_callback);
  t->object_update_callback = object_update_callback;

  set_gc_metamethod(L, "tilemap_t", l_tilemap_deinit);

  return 1;
}

int l_tilemap_read(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);

  tilemap_t* t = (tilemap_t*)lua_newuserdata(L, sizeof(tilemap_t));

  if (!tilemap_read_from_file(t, filename)) {
    char buf[256];
    sprintf(buf, "failed to load tilemap file from %s", filename);
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, buf);
    return 2;
    // return luaL_error(L, "failed to load tilemap file from %s", filename);
  }

  // TODO clean up
  tilemap_set_object_callbacks(t, L, bump_callback, collision_callback);
  t->object_update_callback = object_update_callback;

  set_gc_metamethod(L, "tilemap_t", l_tilemap_deinit);

  // Return the tilemap
  return 1;
}

// TODO return error
int l_tilemap_write(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  const char* filename = luaL_checkstring(L, 2);

  if (!tilemap_write_to_file(t, filename)) {
    return luaL_error(L, "failed to write tilemap to %s", filename);
  }

  lua_pushboolean(L, 1);
  return 1;
}

// TODO get rid of one of these?
int l_tilemap_draw_layer(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  image_t* i = (image_t*)luaL_checkudata(L, 2, "image_t");
  int layer = luaL_checkinteger(L, 3);
  int px = luaL_checkinteger(L, 4);
  int py = luaL_checkinteger(L, 5);
  int pw = luaL_checkinteger(L, 6);
  int ph = luaL_checkinteger(L, 7);
  int counter = luaL_checkinteger(L, 8);
  int draw_flags = lua_toboolean(L, 9);

  tilemap_draw_layer(t, i, layer, px, py, pw, ph, counter, draw_flags);
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
  int counter = luaL_checkinteger(L, 8);

  tilemap_draw_layer(t, i, layer, px, py, pw, ph, counter, /*draw_flags=*/1);
  return 0;
}

int l_tilemap_draw_layer_objects(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  int px = luaL_checkinteger(L, 3);
  int py = luaL_checkinteger(L, 4);
  int pw = luaL_checkinteger(L, 5);
  int ph = luaL_checkinteger(L, 6);
  int counter = luaL_checkinteger(L, 7);

  tilemap_draw_objects(t, layer, px, py, pw, ph, counter);

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

int l_tilemap_get_tile(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  int x = luaL_checkinteger(L, 3);
  int y = luaL_checkinteger(L, 4);

  int tx = -1;
  int ty = -1;
  if (!tilemap_get_tile(t, layer, x, y, &tx, &ty)) {
    lua_pushnil(L);
    return 1;
  }

  lua_pushinteger(L, tx);
  lua_pushinteger(L, ty);
  return 2;
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
  if (!slice) {
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
  if (!patch_udata)
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

int l_tilemap_get_camera_location(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int pw = luaL_checkinteger(L, 2);
  int ph = luaL_checkinteger(L, 3);

  int x = -1;
  int y = -1;
  tilemap_get_camera_location(t, pw, ph, &x, &y);

  if ((x != -1) && (y != -1)) {
    lua_pushinteger(L, x);
    lua_pushinteger(L, y);
    return 2;
  }

  lua_pushnil(L);
  return 1;
}

int l_tilemap_update_objects(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");

  tilemap_update_objects(t);

  return 0;
}

int l_tilemap_draw_layer_at_camera_object(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  image_t* i = (image_t*)luaL_checkudata(L, 2, "image_t");
  int layer = luaL_checkinteger(L, 3);
  int pw = luaL_checkinteger(L, 4);
  int ph = luaL_checkinteger(L, 5);
  int counter = luaL_checkinteger(L, 6);
  int draw_flags = lua_toboolean(L, 7);
  tilemap_draw_layer_at_camera_object(t, i, layer, pw, ph, counter, draw_flags);
  return 0;
}

int l_tilemap_draw_objects_at_camera_object(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  image_t* i = (image_t*)luaL_checkudata(L, 2, "image_t");
  int layer = luaL_checkinteger(L, 3);
  int pw = luaL_checkinteger(L, 4);
  int ph = luaL_checkinteger(L, 5);
  int counter = luaL_checkinteger(L, 6);
  int draw_flags = lua_toboolean(L, 7);
  tilemap_draw_objects_at_camera_object(t, i, layer, pw, ph, counter,
                                        draw_flags);

  return 0;
}

int l_tilemap_get_tile_animation_info(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  int x = luaL_checkinteger(L, 3);
  int y = luaL_checkinteger(L, 4);

  int period, count;
  if (tilemap_get_tile_animation_info(t, layer, x, y, &period, &count)) {
    lua_pushinteger(L, period);
    lua_pushinteger(L, count);
    return 2;
  }

  // failure
  lua_pushnil(L);
  return 1;
}

int l_tilemap_set_tile_animation_info(lua_State* L) {
  tilemap_t* t = (tilemap_t*)luaL_checkudata(L, 1, "tilemap_t");
  int layer = luaL_checkinteger(L, 2);
  int x = luaL_checkinteger(L, 3);
  int y = luaL_checkinteger(L, 4);
  int period = luaL_checkinteger(L, 5);
  int count = luaL_checkinteger(L, 6);

  if (tilemap_set_tile_animation_info(t, layer, x, y, period, count)) {
    lua_pushboolean(L, 1);
    return 1;
  }

  // failure
  lua_pushnil(L);
  return 1;
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

void load_tilemap_bridge(lua_State* L) {
  const luaL_Reg tilemaplib[] = {
      {"read", l_tilemap_read},
      {"write", l_tilemap_write},
      {"createEmpty", l_tilemap_create_empty},
      {"drawLayer", l_tilemap_draw_layer},
      {"drawLayerFlags", l_tilemap_draw_layer_flags},
      {"drawLayerObjects", l_tilemap_draw_layer_objects},
      {"setTile", l_tilemap_set_tile},
      {"getTile", l_tilemap_get_tile},
      {"getFlags", l_tilemap_get_flags},
      {"setFlags", l_tilemap_set_flags},
      {"clearFlags", l_tilemap_clear_flags},
      {"overwriteFlags", l_tilemap_overwrite_flags},
      {"exportSlice", l_tilemap_export_slice},
      {"patch", l_tilemap_patch},
      {"get", l_tilemap_get},
      {"addObject", l_tilemap_add_object},
      {"removeObject", l_tilemap_remove_object},
      {"setCameraObject", l_tilemap_set_camera_object},
      {"getCameraObject", l_tilemap_get_camera_object},
      {"getCameraLocation", l_tilemap_get_camera_location},

      {"updateObjects", l_tilemap_update_objects},
      {"drawLayerAtCameraObject", l_tilemap_draw_layer_at_camera_object},
      {"drawObjectsAtCameraObject", l_tilemap_draw_objects_at_camera_object},
      {"getTileAnimationInfo", l_tilemap_get_tile_animation_info},
      {"setTileAnimationInfo", l_tilemap_set_tile_animation_info},
      {"setSparseLayer", l_tilemap_set_sparse_layer},

      {"abortUpdateObjects", l_tilemap_abort_update_objects},

      {NULL, NULL}};

  luaL_newlib(L, tilemaplib);
  set_int_field(L, "actionflag", TILEMAP_ACTION_MASK);
  set_int_field(L, "bumpeastflag", TILEMAP_BUMP_EAST_MASK);
  set_int_field(L, "bumpnorthflag", TILEMAP_BUMP_NORTH_MASK);
  set_int_field(L, "bumpwestflag", TILEMAP_BUMP_WEST_MASK);
  set_int_field(L, "bumpsouthflag", TILEMAP_BUMP_SOUTH_MASK);
  set_int_field(L, "bumpnortheastflag", TILEMAP_BUMP_NORTHEAST_MASK);
  set_int_field(L, "bumpnorthwestflag", TILEMAP_BUMP_NORTHWEST_MASK);
  set_int_field(L, "bumpsouthwestflag", TILEMAP_BUMP_SOUTHWEST_MASK);
  set_int_field(L, "bumpsoutheastflag", TILEMAP_BUMP_SOUTHEAST_MASK);
}
