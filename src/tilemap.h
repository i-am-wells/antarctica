#ifndef _TILEMAP_H
#define _TILEMAP_H

#include <SDL_pixels.h>
#include <stdbool.h>

#include "image.h"
#include "object.h"
#include "vec.h"

typedef struct AnimationFrame {
  uint32_t x, y, start_time, duration;
} AnimationFrame;

typedef struct TileInfo {
  image_t* image;  // unowned
  int flags;
  int w, h;
  int sx, sy, dx, dy;

  // animation
  int frame_count;
  AnimationFrame* frames;
  // keep track of current frame between draws
  int current_frame;
  uint32_t last_cycle_start;

  // Used to identify the tile for editing and image loading.
  char* name;
  // Image file path
  char* image_path;
  // Scale drawing operations by this factor.
  double draw_scale;
} TileInfo;

/* new flags:
 * 0    - underwater
 * 1-4  - bump nsew
 * 5    - interact
 * 6-7  - ??
 */

typedef struct Tile16 {
  uint8_t byte0, byte1;
} Tile16;

typedef struct tilemap_t {
  uint64_t w, h;
  int nlayers;
  int tile_bits;
  Tile16* tiles;

  size_t tile_info_count;
  TileInfo* tile_info;

  // Sparse map things
  int* should_store_sparse_layer;
  uint64_t* last_non_empty_tile;

  vec_t objectvec; /**< vector containing "moving" objects on map */
  object_t* cameraobject;

  // Drawing details
  uint32_t clock;
  bool draw_flags, is_camera_underwater;
  int screen_w, screen_h;
  int tw, th;

  // misc
  SDL_Color underwater_color;

  // TODO: move object things out of here
  // Start a linked list of objects here
  object_t* head;
  void (*bump_callback)(void*, object_t*, int);
  void (*collision_callback)(void*, object_t*, object_t*);
  void (*object_update_callback)(void*, object_t*);
  void* object_callback_data;
  int updateParity;
} tilemap_t;

enum {
  TILEMAP_ANIM_COUNT_MASK =
      0x1 /**< number (log2) of animated frames for the tile */
      | 0x2,
  TILEMAP_ANIM_PERIOD_MASK = 0x4 /**< number (again log2) of redraw cycles each
                                    animation frame lasts for */
                             | 0x8,
  TILEMAP_UNUSED_MASK = 0x10 /**< unused bits */
                        | 0x20,
  TILEMAP_UNDERWATER_MASK = 0x40,
  TILEMAP_ACTION_MASK =
      0x80, /**< indicates that the tile fires an interaction event */
  TILEMAP_BUMP_SOUTH_MASK =
      0x100, /**< objects can't enter the square from the south */
  TILEMAP_BUMP_WEST_MASK = 0x200,  /**< objects can't enter from the west */
  TILEMAP_BUMP_NORTH_MASK = 0x400, /**< objects can't enter from the north */
  TILEMAP_BUMP_EAST_MASK = 0x800,  /**< objects can't enter from the east */
};

// Free current animation frames array and allocate a new one.
bool tile_info_replace_frames(TileInfo* info, int frames);

void tilemap_deinit(tilemap_t* t);
int tilemap_init(tilemap_t* t,
                 int nlayers,
                 uint64_t w,
                 uint64_t h,
                 int tw,
                 int th);

// Note: All TileInfo fields are copied. The tilemap takes ownership of
// info->frames.
int tilemap_add_tile_info(tilemap_t* t, TileInfo* info);
void tilemap_remove_tile_info(tilemap_t* t, uint16_t idx);

// Remove all TileInfos that don't appear in the map.
int tilemap_clean_tile_info(tilemap_t* t);

// Get the TileInfo for a given tile.
TileInfo* tilemap_get_tile_info(const tilemap_t* t,
                                int layer,
                                uint64_t x,
                                uint64_t y);
uint16_t tilemap_get_tile_info_idx_for_tile(const tilemap_t* t,
                                            int layer,
                                            uint64_t x,
                                            uint64_t y);
void tilemap_synchronize_animation(tilemap_t* t);

void tilemap_advance_clock(tilemap_t* t);
int tilemap_get_flags(const tilemap_t* t, int layer, uint64_t x, uint64_t y);
int tilemap_get_tile_data(const tilemap_t* t,
                          int layer,
                          uint64_t x,
                          uint64_t y);
void tilemap_set_tile_info_idx_for_tile(const tilemap_t* t,
                                        int layer,
                                        uint64_t x,
                                        uint64_t y,
                                        uint16_t idx);
void tilemap_set_object_callbacks(tilemap_t* t,
                                  void* data,
                                  void (*bump)(void*, object_t*, int),
                                  void (*collision)(void*,
                                                    object_t*,
                                                    object_t*));
void tilemap_get_camera_draw_location(const tilemap_t* t,
                                      uint64_t* x,
                                      uint64_t* y);
void tilemap_draw_layer_at_camera_object(const tilemap_t* t, int layer);
bool tilemap_is_camera_underwater(const tilemap_t* t, int layer);
void tilemap_move_object_relative(tilemap_t* t, object_t* o, int dx, int dy);
void tilemap_add_object(tilemap_t* t, object_t* o);
void tilemap_remove_object(tilemap_t* t, object_t* o);
void tilemap_move_object_absolute(tilemap_t* t,
                                  object_t* o,
                                  uint64_t x,
                                  uint64_t y);
void tilemap_update_objects(tilemap_t* t);
void tilemap_set_camera_object(tilemap_t* t, object_t* o);
object_t* tilemap_get_camera_object(const tilemap_t* t);
void tilemap_abort_update_objects(tilemap_t* t);
void tilemap_draw_objects(const tilemap_t* t, int layer, int px, int py);
void tilemap_draw_layer(const tilemap_t* t, int l, uint64_t px, uint64_t py);
void tilemap_draw_objects_interleaved(const tilemap_t* t,
                                      int layer,
                                      uint64_t px,
                                      uint64_t py);
void tilemap_draw_objects_at_camera_object(const tilemap_t* t, int layer);
void tilemap_set_sparse_layer(tilemap_t* t, int layer, int sparse);
void tilemap_set_underwater_color(tilemap_t* t,
                                  uint8_t r,
                                  uint8_t g,
                                  uint8_t b,
                                  uint8_t a);
void tilemap_set_underwater(tilemap_t* t,
                            int layer,
                            uint64_t x,
                            uint64_t y,
                            int underwater);
bool tilemap_read_from_file(tilemap_t* t, const char* path);
bool tilemap_write_to_file(const tilemap_t* t, const char* path);

#endif
