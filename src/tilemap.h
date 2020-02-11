/**
 *  \file tilemap.h
 */

#ifndef _TILEMAP_H
#define _TILEMAP_H

#include "image.h"
#include "object.h"

#include "vec.h"

/**
 *  \struct tile_t
 *
 *  Represents a single square in the tilemap.
 *
 *  \field tilex and \field tiley represent the coordinates of the square's 
 *  image within a tile set and can be passed to image_draw_tile.
 *
 *  \field flags is a mask with various flags to do with how the tile is drawn
 *  and how objects interact with it. See the flags enum for details.
 */
typedef struct tile_t {
    uint8_t tilex;  /**< tile image x */
    uint8_t tiley;  /**< tile image y */
    uint16_t flags; /**< tile flags */
} tile_t;


/**
 *  \struct tilemap_t
 *
 *  Stores tiles as layers of 2D arrays.
 */
typedef struct tilemap_t {
    size_t w;           /**< map width (tiles) */
    size_t h;           /**< map height (tiles) */
    size_t  nlayers;    /**< number of layers */
    int* should_store_sparse_layer;
    uint32_t* last_non_empty_tile;

    vec_t objectvec; /**< vector containing "moving" objects on map */
    //int objectvec_orientation; /**< 0 if objectvec is sorted by x, 1 if sorted by y */

    object_t* cameraobject;

    // Start a linked list of objects here
    object_t* head;

    void (*bump_callback)(void*, object_t*, int);
    void (*collision_callback)(void*, object_t*, object_t*);
    void (*object_update_callback)(void*, object_t*);
    void* object_callback_data;

    tile_t** tiles;     /**< tile data */

    int updateParity;
} tilemap_t;


enum {
    TILEMAP_ANIM_COUNT_MASK =     0x1   /**< number (log2) of animated frames for the tile */
                                | 0x2,
    TILEMAP_ANIM_PERIOD_MASK =    0x4   /**< number (again log2) of redraw cycles each animation frame lasts for */
                                | 0x8,
    TILEMAP_UNUSED_MASK =         0x10  /**< unused bits */
                                | 0x20,
    TILEMAP_UNDERWATER_MASK =     0x40,
    TILEMAP_ACTION_MASK =         0x80,     /**< indicates that the tile fires an interaction event */
    TILEMAP_BUMP_SOUTH_MASK =     0x100,    /**< objects can't enter the square from the south */
    TILEMAP_BUMP_WEST_MASK =      0x200,    /**< objects can't enter from the west */
    TILEMAP_BUMP_NORTH_MASK =     0x400,    /**< objects can't enter from the north */
    TILEMAP_BUMP_EAST_MASK =      0x800,    /**< objects can't enter from the east */
    
    // TODO implement
    TILEMAP_BUMP_NORTHEAST_MASK = 0x1000,
    TILEMAP_BUMP_NORTHWEST_MASK = 0x2000,
    TILEMAP_BUMP_SOUTHWEST_MASK = 0x4000,
    TILEMAP_BUMP_SOUTHEAST_MASK = 0x8000
};

// get
#define TILE_ANIM_COUNT(t) (1 << ((t)->flags & TILEMAP_ANIM_COUNT_MASK))
#define TILE_ANIM_PERIOD(t) (1 << (((t)->flags & TILEMAP_ANIM_PERIOD_MASK) >> 2))

/**
 *  Frees memory held by the tilemap for the tile arrays.
 *  
 *  \param t    tilemap pointer
 */
void tilemap_deinit(tilemap_t * t);


/**
 *  Initializes a tilemap by allocating memory for \param nlayers tile layers
 *  each of size \param w by \param h.
 *
 *  \param t    tilemap pointer
 *  \param nlayers  number of tile layers to allocate
 *  \param w    width (tiles) of each map layer
 *  \param h    height (tiles) of each map layer
 *  
 *  \return 1 on success, 0 on failure
 */
int tilemap_init(tilemap_t * t, size_t nlayers, size_t w, size_t h);

/**
 *  Gets the address of the tile at (\param layer, \param x, \param y).
 *
 *  \param t    tilemap pointer
 *  \param layer    layer index
 *  \param x    map square x
 *  \param y    map square y
 *  
 *  \return address of the tile at (layer, x, y), or NULL if that position isn't
 *  on the map.
 */
tile_t * tilemap_get_tile_address(const tilemap_t* t, size_t layer, size_t x, size_t y);


/**
 *  Sets the image to be used for the tile at (layer, x, y).
 *
 *  \param t    tilemap pointer
 *  \param layer    layer index
 *  \param x    x location of tile
 *  \param y    y location of tile
 *  \param tilex    x index of tile in image
 *  \param tiley    y index of tile in image
 */
void tilemap_set_tile(tilemap_t* t, size_t layer, size_t x, size_t y, int tilex, int tiley);
int tilemap_get_tile(tilemap_t* t, size_t layer, size_t x, size_t y, int* tx, int* ty);

/**
 *  Given the pixel dimensions of the renderer and a location on the map in
 *  pixels, draws a layer of the map to the renderer.
 *
 *  \param t    tilemap pointer
 *  \param i    tile image
 *  \param l    index of map layer to draw
 *  \param px   pixel x offset of left edge of visible area of the map
 *  \param py   pixel y offset of top edge of the visible area of the map
 *  \param pw   pixel width of the view
 *  \param ph   pixel height of the view
 *  \param counter  used for animation
 */
void tilemap_draw_layer(const tilemap_t* t, const image_t* i, int l, int px, int py, int pw, int ph, int counter, int draw_flags);

/**
 *  Create a copy of tile data from all layers within a rectangular region.
 *
 *  \param t    tilemap pointer
 *  \param x    x position of the left edge of the region to copy
 *  \param y    y position of the top edge of the region to copy
 *  \param w    width (map squares) of region
 *  \param h    height (map squares) of region
 *
 *  \return tile array
 */
tile_t* tilemap_export_slice(const tilemap_t* t, int x, int y, int w, int h);


/**
 *  Copy tiles from \param patch into a region of tilemap \param t.
 *
 *  \param t    tilemap pointer
 *  \param patch    tile array as produced by tilemap_export_slice
 *  \param x    x position (map squares)
 *  \param y    y position (map squares)
 *  \param w    width
 *  \param h    height
 */
void tilemap_patch(tilemap_t* t, tile_t* patch, int x, int y, int w, int h);


/**
 *  Reads a tilemap file and initializes \param t with its contents.
 *
 *  \param t    tilemap pointer
 *  \param path path to map file to load
 *
 *  \return 1 on success, 0 on failure
 */
int tilemap_read_from_file(tilemap_t * t, const char * path);


/**
 *  Writes the tilemap at \param t to a file.
 *
 *  \param t    tilemap pointer
 *  \param path path to file to be written
 *
 *  \return 1 on success, 0 on failure
 */
int tilemap_write_to_file(const tilemap_t * t, const char * path);

/** NEW **/


void tilemap_draw_objects(const tilemap_t* t, int layer, int px, int py, int pw, int ph, int counter);

void tilemap_add_object(tilemap_t* t, object_t* o);
void tilemap_remove_object(tilemap_t* t, object_t* o);

void tilemap_move_object_absolute(tilemap_t* t, object_t* o, int x, int y);
void tilemap_move_object_relative(tilemap_t* t, object_t* o, int dx, int dy);

void tilemap_set_flags(tilemap_t* t, size_t layer, size_t x, size_t y, int mask);
void tilemap_clear_flags(tilemap_t* t, size_t layer, size_t x, size_t y, int mask);
void tilemap_overwrite_flags(tilemap_t* t, size_t layer, size_t x, size_t y, int mask);

int tilemap_get_flags(const tilemap_t* t, size_t layer, size_t x, size_t y);


void tilemap_set_object_callbacks(tilemap_t* t, void* data, void (*bump)(void*, object_t*, int), void (*collision)(void*, object_t*, object_t*));
void tilemap_update_objects(tilemap_t* t);

// Camera object
void tilemap_set_camera_object(tilemap_t* t, object_t* o);
object_t* tilemap_get_camera_object(const tilemap_t* t);
void tilemap_get_camera_location(const tilemap_t* t, int pw, int ph, int* x, int* y);

void tilemap_draw_layer_at_camera_object(const tilemap_t* t, const image_t* i, int layer, int pw, int ph, int counter, int draw_flags);
void tilemap_draw_objects_at_camera_object(const tilemap_t* t, const image_t* i, int layer, int pw, int ph, int counter, int draw_flags);

int tilemap_get_tile_animation_info(const tilemap_t* t, size_t layer, int x, int y, int* period, int* count);
int tilemap_set_tile_animation_info(tilemap_t* t, size_t layer, int x, int y, int period, int count);

void tilemap_abort_update_objects(tilemap_t* t);

void tilemap_set_sparse_layer(tilemap_t* t, int layer, int sparse);

int tilemap_empty(const tilemap_t* t, size_t layer, int x, int y);

#endif

