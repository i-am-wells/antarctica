// for endianness conversion functions
#define _DEFAULT_SOURCE

#include "tilemap.h"

#include <SDL.h>
#include <assert.h>
#include <endian.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "engine.h"
#include "image.h"
#include "object.h"
#include "vec.h"

#define DEFAULT_NON_EMPTY 4294967295

static uint16_t mask16[17] = {
    0x1 - 1,  // 0 bits
    0x2 - 1,   0x4 - 1,    0x8 - 1,    0x10 - 1,   0x20 - 1,
    0x40 - 1,  0x80 - 1,   0x100 - 1,  0x200 - 1,  0x400 - 1,
    0x800 - 1, 0x1000 - 1, 0x2000 - 1, 0x4000 - 1, 0x8000 - 1,
    0xffff  // 16 bits
};

// Tile16: per_tile_flags | tileinfo_index
//  where tileinfo_index is map.tile_bits wide
//  and per_tile_flags is (16 - map.tile_bits) wide

// Get the TileInfo index.
static inline uint16_t Tile16_tile(Tile16 t, int tile_bits) {
  return (((uint16_t)t.byte0 << 8) | ((uint16_t)t.byte1)) & mask16[tile_bits];
}

// Get per-tile flags.
static inline uint16_t Tile16_flags(Tile16 t, int tile_bits) {
  uint16_t mask = mask16[tile_bits] ^ 0xffff;
  return ((((uint16_t)t.byte0 << 8) | t.byte1) & mask) >> tile_bits;
}

static inline uint16_t get_tile_info_idx(const tilemap_t* map, Tile16 tile) {
  return Tile16_tile(tile, map->tile_bits);
}

static inline uint16_t get_flags(const tilemap_t* map, Tile16 tile) {
  return Tile16_flags(tile, map->tile_bits);
}

static inline TileInfo* get_tile_info(const tilemap_t* map, Tile16 tile) {
  return map->tile_info + get_tile_info_idx(map, tile);
}

static inline Tile16 get_tile(const tilemap_t* map,
                              int layer,
                              uint64_t x,
                              uint64_t y) {
  if (layer >= 0 && layer < map->nlayers && x < map->w && y < map->h)
    return map->tiles[map->w * (layer * map->h + y) + x];
  Tile16 zero_tile = {0, 0};
  return zero_tile;
}

static inline Tile16* get_tile_ptr(const tilemap_t* map,
                                   int layer,
                                   uint64_t x,
                                   uint64_t y) {
  if (layer >= 0 && layer < map->nlayers && x < map->w && y < map->h)
    return map->tiles + map->w * (layer * map->h + y) + x;
  return NULL;
}

void tilemap_deinit(tilemap_t* t) {
  if (t) {
    if (t->tiles) {
      free(t->tiles);
      t->tiles = NULL;
    }

    if (t->tile_info) {
      for (size_t i = 0; i < t->tile_info_count; ++i) {
        if (t->tile_info[i].frames)
          free(t->tile_info[i].frames);
      }
      free(t->tile_info);
      t->tile_info = NULL;
    }

    if (t->should_store_sparse_layer)
      free(t->should_store_sparse_layer);

    if (t->last_non_empty_tile)
      free(t->last_non_empty_tile);

    vec_deinit(&(t->objectvec));
  }
}

// Make an empty map
int tilemap_init(tilemap_t* t, int nlayers, uint64_t w, uint64_t h) {
  assert(t);
  memset(t, 0, sizeof(tilemap_t));

  if (w && h && nlayers) {
    t->tiles = (Tile16*)calloc(w * h * nlayers, sizeof(Tile16));
    if (!t->tiles)
      return 0;
  }

  // Create object vector
  vec_init(&(t->objectvec), 8);

  tilemap_set_object_callbacks(t, NULL, NULL, NULL);

  t->w = w;
  t->h = h;
  t->nlayers = nlayers;
  // TODO pass this in?
  t->tile_bits = 16;

  tilemap_set_underwater_color(t, 0, 0, 0, SDL_ALPHA_OPAQUE);

  t->should_store_sparse_layer = (int*)calloc(nlayers, sizeof(int));
  if (!t->should_store_sparse_layer) {
    tilemap_deinit(t);
    return 0;
  }

  t->last_non_empty_tile = (uint64_t*)malloc(nlayers * sizeof(uint64_t));
  if (!t->last_non_empty_tile) {
    tilemap_deinit(t);
    return 0;
  }
  for (int i = 0; i < nlayers; i++) {
    t->last_non_empty_tile[i] = DEFAULT_NON_EMPTY;
  }

  // Add default empty tile info.
  TileInfo default_tile_info;
  memset(&default_tile_info, 0, sizeof(TileInfo));
  tilemap_add_tile_info(t, &default_tile_info);
  return 1;
}

bool tile_info_replace_frames(TileInfo* info, int frames) {
  if (info->frames)
    free(info->frames);

  info->frames = (AnimationFrame*)calloc(frames, sizeof(AnimationFrame));
  if (info->frames) {
    info->frame_count = frames;
    return true;
  }
  info->frame_count = 0;
  return false;
}

int tilemap_add_tile_info(tilemap_t* t, TileInfo* info) {
  TileInfo* infos = (TileInfo*)realloc(
      t->tile_info, (t->tile_info_count + 1) * sizeof(TileInfo));
  if (!infos)
    return 0;

  t->tile_info = infos;

  // info->frames will be freed by tilemap_deinit.
  memcpy(t->tile_info + t->tile_info_count, info, sizeof(TileInfo));
  t->tile_info_count++;

  return 1;
}

void tilemap_remove_tile_info(tilemap_t* t, uint16_t idx) {
  if (t->tile_info[idx].frames) {
    free(t->tile_info[idx].frames);
  }
  memmove(t->tile_info + idx, t->tile_info + idx + 1,
          t->tile_info_count - idx - 1);
  --t->tile_info_count;
  t->tile_info =
      (TileInfo*)realloc(t->tile_info, t->tile_info_count * sizeof(TileInfo));
}

// Remove all TileInfos that aren't referenced in map data.
int tilemap_clean_tile_info(tilemap_t* t) {
  uint8_t* infos_found = calloc(t->tile_info_count, 1);
  if (!infos_found)
    return 0;

  for (int layer = 0; layer < t->nlayers; ++layer) {
    for (uint64_t y = 0ul; y < t->h; ++y) {
      for (uint64_t x = 0ul; x < t->w; ++x) {
        uint16_t tile_idx = Tile16_tile(get_tile(t, layer, x, y), t->tile_bits);
        if (tile_idx >= t->tile_info_count) {
          fprintf(stderr, "unknown tile at %d, %zu, %zu\n", layer, x, y);
          free(infos_found);
          return 0;
        }
        infos_found[tile_idx] = 1;
      }
    }
  }

  for (int i = 0; i < t->tile_info_count; ++i) {
    if (!infos_found[i])
      tilemap_remove_tile_info(t, i);
  }
  free(infos_found);
  return 1;
}

void tilemap_set_tile_info_idx_for_tile(const tilemap_t* t,
                                        int layer,
                                        uint64_t x,
                                        uint64_t y,
                                        uint16_t idx) {
  Tile16* tile = get_tile_ptr(t, layer, x, y);
  if (tile) {
    uint16_t mask = mask16[t->tile_bits];
    uint16_t mask_inv = mask ^ 0xffff;
    uint16_t masked_idx = idx & mask;
    tile->byte0 = (tile->byte0 & (mask_inv >> 8)) | (masked_idx >> 8);
    tile->byte1 = (tile->byte1 & mask_inv) | (masked_idx & 0xff);
  }
}

TileInfo* tilemap_get_tile_info(const tilemap_t* t,
                                int layer,
                                uint64_t x,
                                uint64_t y) {
  return get_tile_info(t, get_tile(t, layer, x, y));
}

/*
static int tilemap_empty(const tilemap_t* t, int layer, uint64_t x, uint64_t y)
{ return get_tile_info_idx(t, get_tile(t, layer, x, y)) == 0;
}
*/

void tilemap_increment_clock(tilemap_t* t) {
  ++t->clock;
}

int tilemap_get_flags(const tilemap_t* t, int layer, uint64_t x, uint64_t y) {
  return tilemap_get_tile_info(t, layer, x, y)->flags;
}

int tilemap_get_tile_data(const tilemap_t* t,
                          int layer,
                          uint64_t x,
                          uint64_t y) {
  // TODO rename to get_data or something
  return get_flags(t, get_tile(t, layer, x, y));
}

/*
static void tilemap_set_last_non_empty_tile(tilemap_t* t,
                                            int layer,
                                            uint64_t x,
                                            uint64_t y) {
  if (t->should_store_sparse_layer[layer]) {
    uint32_t pos = y * t->w + x;
    if (t->last_non_empty_tile[layer] == DEFAULT_NON_EMPTY ||
        pos > t->last_non_empty_tile[layer]) {
      t->last_non_empty_tile[layer] = pos;
    }
  }
}
*/

void tilemap_set_object_callbacks(tilemap_t* t,
                                  void* data,
                                  void (*bump)(void*, object_t*, int),
                                  void (*collision)(void*,
                                                    object_t*,
                                                    object_t*)) {
  assert(t);
  t->bump_callback = bump;
  t->collision_callback = collision;
  t->object_callback_data = data;
}

#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

void tilemap_get_camera_draw_location(const tilemap_t* t,
                                      uint64_t* x,
                                      uint64_t* y) {
  uint64_t px = 0;
  uint64_t py = 0;
  if (t->cameraobject) {
    int px = MAX(0, t->cameraobject->x - (t->screen_w / 2));
    int py = MAX(0, t->cameraobject->y - (t->screen_h / 2));
    px = MIN(px, t->w * t->cameraobject->image->tw - t->screen_w);
    py = MIN(py, t->h * t->cameraobject->image->th - t->screen_h);
  }

  if (x)
    *x = px;

  if (y)
    *y = py;
}

void tilemap_draw_layer_at_camera_object(const tilemap_t* t, int layer) {
  uint64_t px, py;
  tilemap_get_camera_draw_location(t, &px, &py);
  tilemap_draw_layer(t, layer, px, py);
}

// TODO should camera provide layer?
bool tilemap_is_camera_underwater(const tilemap_t* t, int layer) {
  // TODO finish
  return false;

  /*
  if (!t->cameraobject)
    return false;

  int flags =
      tilemap_get_flags(t, layer, t->cameraobject->x, t->cameraobject->y);
  Tile16 tile = get_tile(t, layer, t->cameraobject->x /

  return flags & TILEMAP_UNDERWATER_MASK;
  */
}

#define OBJECT_AT(ovec, i) ((object_t*)(ovec.data[(i)]))

static size_t tilemap_binary_search_objects(const tilemap_t* t,
                                            int q,
                                            size_t first,
                                            size_t last) {
  if (last == -1)
    return -1;

  int firstval = OBJECT_AT(t->objectvec, first)->y;
  if (q < firstval)
    return first - 1;

  int lastval = OBJECT_AT(t->objectvec, last)->y;
  if (q >= lastval)
    return last;

  while (last - first > 1) {
    size_t mid = (first + last) / 2;

    int midval = OBJECT_AT(t->objectvec, mid)->y;

    if (midval > q) {
      last = mid;
    } else if (midval == q) {
      return mid;
    } else {
      first = mid;
    }
  }

  return first;
}

void tilemap_move_object_relative(tilemap_t* t, object_t* o, int dx, int dy) {
  assert(o);
  size_t object_idx = o->index;
  size_t dest_idx = object_idx;

  int next_y = o->y + dy;

  // Search linearly for new y index
  if (dy > 0) {
    while ((dest_idx < t->objectvec.size) &&
           (OBJECT_AT(t->objectvec, dest_idx)->y < next_y))
      dest_idx++;

    dest_idx--;
  } else if (dy < 0) {
    while ((dest_idx > 0) &&
           (OBJECT_AT(t->objectvec, dest_idx - 1)->y > next_y))
      dest_idx--;
  }

  // Move object in objects vector
  vec_move(&(t->objectvec), dest_idx, object_idx);
  size_t firstI = MIN(object_idx, dest_idx);
  size_t lastI = MAX(object_idx, dest_idx);
  for (size_t i = firstI; i <= lastI; i++)
    OBJECT_AT(t->objectvec, i)->index = i;

  // Update object's coordinates on map
  o->x += dx;
  o->y += dy;
}

void tilemap_add_object(tilemap_t* t, object_t* o) {
  size_t index =
      tilemap_binary_search_objects(t, o->y, 0, t->objectvec.size - 1);
  index++;

  assert(vec_insert(&(t->objectvec), index, o));
  o->index = index;

  for (size_t i = o->index + 1; i < t->objectvec.size; i++) {
    object_t* obj = OBJECT_AT(t->objectvec, i);
    obj->index = i;
  }
}

void tilemap_remove_object(tilemap_t* t, object_t* o) {
  vec_remove(&(t->objectvec), o->index, 1);
  for (size_t i = o->index; i < t->objectvec.size; i++) {
    object_t* obj = OBJECT_AT(t->objectvec, i);
    obj->index = i;
  }
}

static void tilemap_remove_object_by_index(tilemap_t* t, size_t idx) {
  vec_remove(&(t->objectvec), idx, 1);
  for (size_t i = idx; i < t->objectvec.size; i++) {
    object_t* obj = OBJECT_AT(t->objectvec, i);
    obj->index = i;
  }
}

void tilemap_move_object_absolute(tilemap_t* t,
                                  object_t* o,
                                  uint64_t x,
                                  uint64_t y) {
  tilemap_remove_object(t, o);
  o->x = x;
  o->y = y;
  tilemap_add_object(t, o);
}

#define ABS(a) ((a) < 0) ? (-a) : (a)

// True if a and b positive or a and b negative
static inline int samesign(double a, double b) {
  return (a * b) > 0;
}

// Returns a bump direction for A
static int checkCollision(int xa0,
                          int ya0,
                          int xa1,
                          int ya1,
                          int xb0,
                          int yb0,
                          int xb1,
                          int yb1) {
  int diffX = 0;
  int diffY = 0;

  xa1--;
  xb1--;
  ya1--;
  yb1--;

  if (ya0 <= yb0) {
    if (ya1 > yb0)
      diffY = ya1 - yb0;
    else
      return 0;

    if (xa0 <= xb0) {
      if (xa1 > xb0)
        diffX = xa1 - xb0;
      else
        return 0;

      if (diffX > diffY)
        return TILEMAP_BUMP_NORTH_MASK;
      else
        return TILEMAP_BUMP_WEST_MASK;
    } else if (xa0 > xb0) {
      if (xb1 > xa0)
        diffX = xb1 - xa0;
      else
        return 0;

      if (diffX > diffY)
        return TILEMAP_BUMP_NORTH_MASK;
      else
        return TILEMAP_BUMP_EAST_MASK;
    }
  } else if (ya0 > yb0) {
    if (yb1 > ya0)
      diffY = yb1 - ya0;
    else
      return 0;

    if (xa0 <= xb0) {
      if (xa1 > xb0)
        diffX = xa1 - xb0;
      else
        return 0;

      if (diffX > diffY)
        return TILEMAP_BUMP_SOUTH_MASK;
      else
        return TILEMAP_BUMP_WEST_MASK;
    } else if (xa0 > xb0) {
      if (xb1 > xa0)
        diffX = xb1 - xa0;
      else
        return 0;

      if (diffX > diffY)
        return TILEMAP_BUMP_SOUTH_MASK;
      else
        return TILEMAP_BUMP_EAST_MASK;
    }
  }

  return 0;
}

static int check_wall_bump(const tilemap_t* t, object_t* o) {
  // bounding box at starting point
  int x0 = o->x + o->boundX;
  int w0 = o->boundW;
  int y0 = o->y + o->boundY;
  int h0 = o->boundH;

  // ending position
  int x1 = x0 + o->vx;
  int y1 = y0 + o->vy;

  int bumpDir = 0;

  // Check whether we've crossed tile boundaries, and if so, whether new
  // overlapped tiles have bump flags
  int checkFlagX = 0;
  int mapX0 = (x0 + w0 - 1) / t->tw;  // FURTHEST
  int checkMapX = (x1 + w0 - 1) / t->tw;
  if (checkMapX > mapX0) {
    // if traveling east
    checkFlagX = TILEMAP_BUMP_WEST_MASK;
  } else if ((x1 / t->tw) < (x0 / t->tw)) {
    // if traveling west
    checkMapX = x1 / t->tw;
    checkFlagX = TILEMAP_BUMP_EAST_MASK;
  }

  // Check edge for bump flag
  if (checkFlagX) {
    int mapY0 = y1 / t->th;
    int mapY1 = (y1 + h0) / t->th;
    for (int y = mapY0; y <= mapY1; y++) {
      if (tilemap_get_flags(t, o->layer, checkMapX, y) & checkFlagX) {
        bumpDir |= checkFlagX;
        break;
      }
    }
  }

  // Same thing, different axis
  //
  // Check whether we've crossed tile boundaries, and if so, whether new
  // overlapped tiles have bump flags
  int checkFlagY = 0;
  int mapY0 = (y0 + h0 - 1) / t->th;
  int checkMapY = (y1 + h0 - 1) / t->th;
  if (checkMapY > mapY0) {
    // traveling south
    checkFlagY = TILEMAP_BUMP_NORTH_MASK;
  } else if ((y1 / t->tw) < (y0 / t->tw)) {
    // if traveling north
    checkFlagY = TILEMAP_BUMP_SOUTH_MASK;
    checkMapY = y1 / t->th;
  }

  // Check edge for bump flag
  if (checkFlagY) {
    int mapX0 = x1 / t->tw;
    int mapX1 = (x1 + w0) / t->tw;
    for (int x = mapX0; x <= mapX1; x++) {
      if (tilemap_get_flags(t, o->layer, x, checkMapY) & checkFlagY) {
        bumpDir |= checkFlagY;
        break;
      }
    }
  }

  return bumpDir;
}

void tilemap_update_objects(tilemap_t* t) {
  // updateParity is -1 if "abort update" has been called
  if (t->updateParity == -1) {
    t->updateParity = 0;
    return;
  }

  for (size_t i = 0; i < t->objectvec.size; i++) {
    object_t* objectA = OBJECT_AT(t->objectvec, i);

    if (objectA->toRemove) {
      tilemap_remove_object_by_index(t, i);
      i--;
      continue;
    }

    // If we've already seen objectA this round (meaning it moved forward
    // in the object vector) skip it.
    if (objectA->updateParity != t->updateParity)
      continue;

    objectA->updateParity = !objectA->updateParity;

    // positions of corners
    int xa0 = objectA->x + objectA->boundX;
    int xa1 = xa0 + objectA->boundW;
    int ya0 = objectA->y + objectA->boundY;
    int ya1 = ya0 + objectA->boundH;

    // positions of corners in next step
    int nextXA0 = xa0 + objectA->vx;
    int nextXA1 = xa1 + objectA->vx;
    int nextYA0 = ya0 + objectA->vy;
    int nextYA1 = ya1 + objectA->vy;

    double dx = objectA->vx;
    double dy = objectA->vy;

    // TODO break if objectB is too far away
    for (size_t j = i + 1; j < t->objectvec.size; j++) {
      object_t* objectB = OBJECT_AT(t->objectvec, j);

      if (objectB->toRemove) {
        tilemap_remove_object_by_index(t, j);
        j--;
        continue;
      }

      int xb0 = objectB->x + objectB->boundX;
      int xb1 = xb0 + objectB->boundW;
      int yb0 = objectB->y + objectB->boundY;
      int yb1 = yb0 + objectB->boundH;

      int nextXB0 = xb0 + objectB->vx;
      int nextXB1 = xb1 + objectB->vx;
      int nextYB0 = yb0 + objectB->vy;
      int nextYB1 = yb1 + objectB->vy;

      // check collision

      // if(isOverlap(nextXA0, nextYA0, nextXA1, nextYA1, nextXB0, nextYB0,
      // nextXB1, nextYB1)) {
      int collisionDir = checkCollision(nextXA0, nextYA0, nextXA1, nextYA1,
                                        nextXB0, nextYB0, nextXB1, nextYB1);
      if (collisionDir) {
        objectA->activeWallBump |= collisionDir;
        switch (collisionDir) {
          case TILEMAP_BUMP_NORTH_MASK:
            objectB->activeWallBump |= TILEMAP_BUMP_SOUTH_MASK;
            break;
          case TILEMAP_BUMP_SOUTH_MASK:
            objectB->activeWallBump |= TILEMAP_BUMP_NORTH_MASK;
            break;
          case TILEMAP_BUMP_EAST_MASK:
            objectB->activeWallBump |= TILEMAP_BUMP_WEST_MASK;
            break;
          case TILEMAP_BUMP_WEST_MASK:
            objectB->activeWallBump |= TILEMAP_BUMP_EAST_MASK;
            break;
        }

        // run collision callback
        t->collision_callback(t->object_callback_data, objectA, objectB);

        // updateParity is -1 if "abort update" has been called
        if (t->updateParity == -1) {
          t->updateParity = 0;
          return;
        }
      }
    }

    // Check wall bump. This is done last so that no objects end up overlapping
    // walls while still traveling towards them.
    int wallBumpDir = check_wall_bump(t, objectA);
    if (wallBumpDir)
      t->bump_callback(t->object_callback_data, objectA, wallBumpDir);

    objectA->activeWallBump |= wallBumpDir;

    // updateParity is -1 if "abort update" has been called
    if (t->updateParity == -1) {
      t->updateParity = 0;
      return;
    }

    // Wall bump: object bounces perfectly
    if (objectA->activeWallBump & TILEMAP_BUMP_NORTH_MASK)
      dy = MIN(0, dy);

    if (objectA->activeWallBump & TILEMAP_BUMP_SOUTH_MASK)
      dy = MAX(0, dy);

    if (objectA->activeWallBump & TILEMAP_BUMP_EAST_MASK)
      dx = MAX(0, dx);

    if (objectA->activeWallBump & TILEMAP_BUMP_WEST_MASK)
      dx = MIN(0, dx);

    // If object has been removed already, remove it before
    // tilemap_move_object_relative
    if (objectA->toRemove) {
      tilemap_remove_object_by_index(t, i);
      i--;
      continue;
    } else {
      tilemap_move_object_relative(t, objectA, dx, dy);
    }

    // run update callback
    t->object_update_callback(t->object_callback_data, objectA);

    // updateParity is -1 if "abort update" has been called
    if (t->updateParity == -1) {
      t->updateParity = 0;
      return;
    }

    objectA->activeWallBump = 0;
  }

  // Prepare for next round of updates
  t->updateParity = !t->updateParity;
}

void tilemap_set_camera_object(tilemap_t* t, object_t* o) {
  t->cameraobject = o;
}

object_t* tilemap_get_camera_object(const tilemap_t* t) {
  return t->cameraobject;
}

void tilemap_abort_update_objects(tilemap_t* t) {
  t->updateParity = -1;
}

// draw objects from one map layer
void tilemap_draw_objects(const tilemap_t* t, int layer, int px, int py) {
  // TODO Find range of objects to draw
  size_t idx0, idx1;
  // if(t->objectvec_orientation == 0) {
  // idx0 = tilemap_binary_search_objects(t, px, 0, t->objectvec.size - 1);
  // idx1 = tilemap_binary_search_objects(t, px + t->screen_w, idx0,
  // t->objectvec.size - 1);
  //} else if(t->objectvec_orientation == 1) {

  /*
      idx0 = tilemap_binary_search_objects(t, py, 0, t->objectvec.size - 1);
      if(idx0 >= t->objectvec.size)
          idx0 = 0;

      idx1 = tilemap_binary_search_objects(t, py + t->screen_h, idx0,
     t->objectvec.size - 1); idx1++;
      //}
  */

  // For now, just draw all objects
  idx0 = 0;
  idx1 = t->objectvec.size - 1;

  for (size_t i = idx0; i <= idx1; i++) {
    object_t* obj = OBJECT_AT(t->objectvec, i);

    if ((obj->layer == layer) && (obj->x < px + t->screen_w) &&
        (obj->y < py + t->screen_h) && (obj->x + obj->tw > px) &&
        (obj->y + obj->th > py)) {
      object_draw(obj, px, py, t->clock);
    }
  }
}

static void tilemap_draw_flags(const tilemap_t* t,
                               SDL_Renderer* renderer,
                               uint16_t flags,
                               uint16_t tile_flags,
                               uint64_t x,
                               uint64_t y) {
  assert(renderer);

  int thickness = 2;
  SDL_Rect dst;

  int x1 = x + t->tw - thickness;
  int y1 = y + t->th - thickness;

  // draw map square borders in red to show directional bump flags
  SDL_SetRenderDrawColor(renderer, 255, 0, 0, SDL_ALPHA_OPAQUE);
  if (flags & TILEMAP_BUMP_EAST_MASK) {
    dst.x = x1;
    dst.y = y;
    dst.w = thickness;
    dst.h = t->th;
    SDL_RenderFillRect(renderer, &dst);
  }
  if (flags & TILEMAP_BUMP_NORTH_MASK) {
    dst.x = x;
    dst.y = y;
    dst.w = t->tw;
    dst.h = thickness;
    SDL_RenderFillRect(renderer, &dst);
  }
  if (flags & TILEMAP_BUMP_WEST_MASK) {
    dst.x = x;
    dst.y = y;
    dst.w = thickness;
    dst.h = t->th;
    SDL_RenderFillRect(renderer, &dst);
  }
  if (flags & TILEMAP_BUMP_SOUTH_MASK) {
    dst.x = x;
    dst.y = y1;
    dst.w = t->tw;
    dst.h = thickness;
    SDL_RenderFillRect(renderer, &dst);
  }

  // draw a green rectangle in the center of map squares with
  // the "action" flag set
  SDL_SetRenderDrawColor(renderer, 0, 255, 0, SDL_ALPHA_OPAQUE);
  if (flags & TILEMAP_ACTION_MASK) {
    dst.x = x + t->tw / 4;
    dst.y = y + t->th / 4;
    dst.w = t->tw / 2;
    dst.h = t->th / 2;
    SDL_RenderFillRect(renderer, &dst);
  }
}

static void draw_tile(const tilemap_t* t, Tile16 tile, int dx, int dy) {
  TileInfo* info = get_tile_info(t, tile);
  AnimationFrame* frame = info->frames + info->current_frame;
  if (t->clock >= frame->start_time + frame->duration)
    frame = info->frames + (++info->current_frame);

  image_draw(info->image, info->sx + frame->tile_x, info->sy, info->w, info->h,
             dx, dy, info->w, info->h);

  if (t->draw_flags) {
    tilemap_draw_flags(t, info->image->renderer, info->flags,
                       get_flags(t, tile), dx, dy);
  }
}

/*
static void fill_underwater_color(const tilemap_t* t,
                                  SDL_Renderer* renderer,
                                  uint64_t x,
                                  uint64_t y,
                                  uint64_t w,
                                  uint64_t h) {
  // Save current draw color
  Uint8 or, og, ob, oa;
  if (SDL_GetRenderDrawColor(renderer, &or, &og, &ob, &oa) == -1)
    return;

  SDL_Rect rect = {x, y, w, h};
  if (SDL_SetRenderDrawColor(renderer, t->underwater_color.r,
                             t->underwater_color.g, t->underwater_color.b,
                             t->underwater_color.a) != -1) {
    SDL_RenderFillRect(renderer, &rect);
  }

  // Restore original draw color
  SDL_SetRenderDrawColor(renderer, or, og, ob, oa);
}
*/

static void tilemap_draw_row(const tilemap_t* t,
                             int layer,
                             int px,
                             int dy,
                             int row) {
  for (int xx = px / t->tw; xx <= (px + t->screen_w) / t->tw; xx++) {
    int dx = xx * t->tw - px;
    Tile16 tile = get_tile(t, layer, xx, row);
    bool tile_underwater =
        get_tile_info(t, tile)->flags & TILEMAP_UNDERWATER_MASK;

    if (tilemap_is_camera_underwater(t, layer)) {
      if (tile_underwater) {
        // camera is underwater and tile is underwater; normal tile draw
        draw_tile(t, tile, dx, dy);
      } else {
        // TODO make this a tile draw
        // camera is underwater but tile is not; fill underwater color
        // fill_underwater_color(t, dx, dy, t->tw, t->th);
      }
    } else {
      if (tile_underwater) {
        // TODO draw water surface
        draw_tile(t, tile, dx, dy);
      } else {
        draw_tile(t, tile, dx, dy);
      }
    }
  }
}

static void tilemap_draw_layer_rows(const tilemap_t* t,
                                    int layer,
                                    uint64_t px,
                                    uint64_t py,
                                    int row_start,
                                    int row_end) {
  for (int row = row_start; row <= row_end; row++) {
    int dy = row * t->th - py;
    tilemap_draw_row(t, layer, px, dy, row);
  }
}

void tilemap_draw_layer(const tilemap_t* t, int l, uint64_t px, uint64_t py) {
  int row_start = py / t->th;
  int row_end = row_start + (t->screen_h / t->th) + 2;
  tilemap_draw_layer_rows(t, l, px, py, row_start, row_end);
}

// draw objects from one map layer
void tilemap_draw_objects_interleaved(const tilemap_t* t,
                                      int layer,
                                      uint64_t px,
                                      uint64_t py) {
  // Find range of objects to draw
  size_t idx0, idx1;

  // For now, just draw all objects
  idx0 = 0;
  idx1 = t->objectvec.size - 1;

  // top row of tiles
  int lastMapY = py / t->th;

  for (size_t i = idx0; i <= idx1; i++) {
    object_t* obj = OBJECT_AT(t->objectvec, i);

    // bottom edge of sprite
    int bottomY = obj->y + obj->offY + obj->th - 1;

    // do we need to draw more tile rows first?
    int bottomMapY = bottomY / t->th;
    if (bottomMapY > lastMapY) {
      // draw new rows
      tilemap_draw_layer_rows(t, layer, px, py, lastMapY, bottomMapY);

      lastMapY = bottomMapY;
    }

    if ((obj->layer == layer) && (obj->x + obj->offX < px + t->screen_w) &&
        (obj->y + obj->offY < py + t->screen_h) &&
        (obj->x + obj->offX + obj->tw >= px) &&
        (obj->y + obj->offY + obj->th >= py)) {
      object_draw(obj, px, py, t->clock);
    }
  }

  // Draw remaining rows
  tilemap_draw_layer_rows(t, layer, px, py, lastMapY,
                          (py + t->screen_h) / t->th);
}

void tilemap_draw_objects_at_camera_object(const tilemap_t* t, int layer) {
  uint64_t px, py;
  tilemap_get_camera_draw_location(t, &px, &py);
  tilemap_draw_objects_interleaved(t, layer, px, py);
}

void tilemap_set_sparse_layer(tilemap_t* t, int layer, int sparse) {
  assert(layer >= 0 && layer < t->nlayers);
  t->should_store_sparse_layer[layer] = sparse;
}

void tilemap_set_underwater_color(tilemap_t* t,
                                  uint8_t r,
                                  uint8_t g,
                                  uint8_t b,
                                  uint8_t a) {
  t->underwater_color.r = r;
  t->underwater_color.g = g;
  t->underwater_color.b = b;
  t->underwater_color.a = a;
}

// TODO
void tilemap_set_underwater(tilemap_t* t,
                            int layer,
                            uint64_t x,
                            uint64_t y,
                            int underwater) {
  /*
  if (underwater)
    tilemap_set_flags(t, layer, x, y, TILEMAP_UNDERWATER_MASK);
  else
    tilemap_clear_flags(t, layer, x, y, TILEMAP_UNDERWATER_MASK);
    */
}

#define TILEMAP_FILE_VERSION 2

// Tilemap file format version 2
//  - all numbers are little-endian
//  - (byte offset): thing, size
//    - (0):  magic, 13 bytes
//    - (13): version, 2 bytes
//    - (15): w, 8 bytes
//    - (23): h, 8 bytes
//    - (31): nlayers, 4 bytes
//    - (35): tile bits, 1 byte
//    - (36): tile info count, 8 bytes
//    - (44): tile pixel width, 4 bytes
//    - (48): tile pixel height, 4 bytes
//    - (52): begin repeated tile info
//      - (info+0):  flags, 4 bytes
//      - (info+4):  frame count, 4 bytes
//      - (info+8):  image name length, 2 bytes
//      - (info+10): image file name
//      - (info+10+name): begin repeated frames
//        - (frame+0): tile x, 4 bytes
//        - (frame+4): duration, 4 bytes
//    - (??): tile data, (w * h * nlayers * 2) bytes

static const char magic[] = "antarcticamap";
static const size_t magic_len = 13ul;

static bool file_io_failure(const char* op,
                            const char* path,
                            const char* error,
                            FILE* f) {
  fprintf(stderr, "failed to %s %s: %s\n", op, path, error);
  if (f)
    fclose(f);
  return false;
}

static bool read_failure(tilemap_t* t,
                         const char* path,
                         const char* error,
                         FILE* f) {
  tilemap_deinit(t);
  return file_io_failure("read", path, error, f);
}

static uint8_t get8(char** ptr) {
  uint8_t result = **ptr;
  (*ptr)++;
  return result;
}

static uint16_t get16(char** ptr) {
  uint16_t result = le16toh(*(uint16_t*)(*ptr));
  *ptr += 2;
  return result;
}

static uint32_t get32(char** ptr) {
  uint32_t result = le32toh(*(uint32_t*)(*ptr));
  *ptr += 4;
  return result;
}

static uint64_t get64(char** ptr) {
  uint64_t result = le64toh(*(uint64_t*)(*ptr));
  *ptr += 8;
  return result;
}

static void put8(char** ptr, uint8_t v) {
  **ptr = v;
  (*ptr)++;
}

static void put16(char** ptr, uint16_t v) {
  *(uint16_t*)(*ptr) = htole16(v);
  *ptr += 2;
}

static void put32(char** ptr, uint32_t v) {
  *(uint32_t*)(*ptr) = htole32(v);
  *ptr += 4;
}

static void put64(char** ptr, uint64_t v) {
  *(uint64_t*)(*ptr) = htole64(v);
  *ptr += 8;
}

static const char error_eof[] = "unexpectedly reached end of file";
static const char error_memory[] = "couldn't allocate memory";

static bool read_v2(tilemap_t* t, char* buffer, const char* path, FILE* f) {
  char* cursor = buffer;
  t->w = get64(&cursor);
  t->h = get64(&cursor);
  t->nlayers = get32(&cursor);

  t->tile_bits = get8(&cursor);
  t->tile_info_count = get64(&cursor);
  t->tw = get32(&cursor);
  t->th = get32(&cursor);

  // Read tile info
  t->tile_info = (TileInfo*)calloc(t->tile_info_count, sizeof(TileInfo));
  if (!t->tile_info)
    return read_failure(t, path, error_memory, f);

  for (TileInfo* info = t->tile_info + 1;
       info < t->tile_info + t->tile_info_count; ++info) {
    if (!fread(buffer, 34, 1, f))
      return read_failure(t, path, error_eof, f);

    cursor = buffer;
    info->flags = get32(&cursor);              // 4 bytes so far
    info->w = get32(&cursor);                  // 8
    info->h = get32(&cursor);                  // 12
    info->sx = get32(&cursor);                 // 16
    info->sy = get32(&cursor);                 // 20
    info->dx = get32(&cursor);                 // 24
    info->dy = get32(&cursor);                 // 28
    info->frame_count = get32(&cursor);        // 32
    uint16_t image_name_len = get16(&cursor);  // 34

    // Don't load images here; just get the file names.
    info->name = malloc(image_name_len + 1);
    if (!info->name)
      return read_failure(t, path, error_memory, f);

    if (!fread(info->name, image_name_len, 1, f))
      return read_failure(t, path, error_eof, f);
    info->name[image_name_len] = '\0';

    // Read animation frames
    info->frames =
        (AnimationFrame*)calloc(info->frame_count, sizeof(AnimationFrame));
    if (!info->frames)
      return read_failure(t, path, error_memory, f);

    uint32_t start_time = 0;
    for (AnimationFrame* frame = info->frames;
         frame < info->frames + info->frame_count; ++frame) {
      if (!fread(buffer, 8, 1, f))
        return read_failure(t, path, error_eof, f);

      cursor = buffer;
      frame->tile_x = get32(&cursor);
      frame->duration = get32(&cursor);
      frame->start_time = start_time;
      start_time += frame->duration;
    }
  }

  // Read tile data
  size_t tiles_size = t->w * t->h * t->nlayers * sizeof(Tile16);
  t->tiles = (Tile16*)malloc(tiles_size);
  if (!t->tiles)
    return read_failure(t, path, error_memory, f);

  if (!fread(t->tiles, tiles_size, 1, f))
    return read_failure(t, path, error_eof, f);

  fclose(f);
  return true;
}

bool tilemap_read_from_file(tilemap_t* t, const char* path) {
  assert(t);
  tilemap_init(t, 0, 0ul, 0ul);

  FILE* f = fopen(path, "rb");
  if (!f)
    return read_failure(t, path, "couldn't open file for reading", f);

  // Read header
  char buffer[64];
  if (!fread(buffer, 52, 1, f))
    return read_failure(t, path, error_eof, f);

  if (strncmp(buffer, magic, magic_len) != 0)
    return read_failure(t, path, "file doesn't start with magic bytes", f);

  char* cursor = buffer + magic_len;
  // version
  switch (get16(&cursor)) {
    case 2:
      return read_v2(t, cursor, path, f);
    default:
      return read_failure(t, path, "unknown map version", f);
  }
  return false;
}

static bool write_failure(const char* path, const char* error, FILE* f) {
  return file_io_failure("write", path, error, f);
}

bool tilemap_write_to_file(const tilemap_t* t, const char* path) {
  FILE* f = fopen(path, "wb");
  if (!f)
    return write_failure(path, "couldn't open file for writing", f);

  char buffer[64];
  strncpy(buffer, magic, magic_len);
  char* cursor = buffer + magic_len;

  put16(&cursor, TILEMAP_FILE_VERSION);
  put64(&cursor, t->w);
  put64(&cursor, t->h);
  put32(&cursor, t->nlayers);
  put8(&cursor, t->tile_bits);

  put64(&cursor, t->tile_info_count);
  put32(&cursor, t->tw);
  put32(&cursor, t->th);

  if (!fwrite(buffer, cursor - buffer, 1, f))
    return write_failure(path, "couldn't write header bytes", f);

  // Write tile info
  for (TileInfo* info = t->tile_info + 1;
       info < t->tile_info + t->tile_info_count; ++info) {
    cursor = buffer;
    put32(&cursor, info->flags);
    put32(&cursor, info->w);
    put32(&cursor, info->h);
    put32(&cursor, info->sx);
    put32(&cursor, info->sy);
    put32(&cursor, info->dx);
    put32(&cursor, info->dy);
    put32(&cursor, info->frame_count);

    size_t image_name_len = strlen(info->name);
    put16(&cursor, (uint16_t)image_name_len);

    if (!fwrite(buffer, cursor - buffer, 1, f))
      return write_failure(path, "couldn't write tile info", f);

    if (!fwrite(info->name, image_name_len, 1, f))
      return write_failure(path, "couldn't write tile image name", f);

    for (AnimationFrame* frame = info->frames;
         frame < info->frames + info->frame_count; ++frame) {
      cursor = buffer;
      put32(&cursor, frame->tile_x);
      put32(&cursor, frame->duration);
      if (!fwrite(buffer, cursor - buffer, 1, f))
        return write_failure(path, "couldn't write animation info", f);
    }
  }

  // Write tiles
  if (!fwrite(t->tiles, t->w * t->h * t->nlayers * sizeof(Tile16), 1, f))
    return write_failure(path, "couldn't write tile data", f);

  // TODO sparse map?

  fclose(f);
  return true;
}
