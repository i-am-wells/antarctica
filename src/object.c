#include "object.h"

#include <assert.h>
#include <stdlib.h>

#include "image.h"
#include "tilemap.h"

int object_init(object_t* o,
                image_t* image,
                int tx,
                int ty,
                int tw,
                int th,
                int aperiod,
                int acount,
                int x,
                int y,
                int layer) {
  o->image = image;
  o->tx = tx;
  o->ty = ty;
  o->tw = tw;
  o->th = th;

  // TODO remove?
  o->animperiod = aperiod;
  o->animcount = acount;

  o->x = x;
  o->y = y;
  o->layer = layer;

  // TODO remove
  o->index = -1;
  o->toRemove = 0;

  o->offX = 0;
  o->offY = 0;

  object_set_bounding_box(o, 0, 0, tw, th);

  // object_set_velocity(o, 0, 0);
  o->vx = 0;
  o->vy = 0;

  o->activeWallBump = 0;

  o->updateParity = 0;

  return 1;
}

void object_deinit(object_t* o) {
  // nothing yet
}

object_t* object_create(image_t* image,
                        int tx,
                        int ty,
                        int tw,
                        int th,
                        int aperiod,
                        int acount,
                        int x,
                        int y,
                        int layer) {
  object_t* o = (object_t*)malloc(sizeof(object_t*));
  if (!o)
    return NULL;

  if (!object_init(o, image, tx, ty, tw, th, aperiod, acount, x, y, layer)) {
    free(o);
    return NULL;
  }

  return o;
}

void object_set_bounding_box(object_t* o, int x, int y, int w, int h) {
  o->boundX = x;
  o->boundY = y;
  o->boundW = w;
  o->boundH = h;
}

void object_set_sprite(object_t* o,
                       int tx,
                       int ty,
                       int tw,
                       int th,
                       int animcount,
                       int animperiod,
                       int offX,
                       int offY) {
  o->tx = tx;
  o->ty = ty;
  o->tw = tw;
  o->th = th;
  o->animperiod = animperiod;
  o->animcount = animcount;
  o->offX = offX;
  o->offY = offY;
}

void object_destroy(object_t* o) {
  object_deinit(o);
  free(o);
}

void object_draw(const object_t* o, int vx, int vy, int counter) {
  int orig_tw = o->image->tw;
  int orig_th = o->image->th;
  o->image->tw = o->tw;
  o->image->th = o->th;
  image_draw_tile(o->image, o->tx,
                  o->ty + (counter / o->animperiod) % o->animcount,
                  o->x - vx + o->offX, o->y - vy + o->offY);
  o->image->tw = orig_tw;
  o->image->th = orig_th;
}

void object_set_velocity(object_t* o, double vx, double vy) {
  object_set_x_velocity(o, vx);
  object_set_y_velocity(o, vy);
}

void object_set_x_velocity(object_t* o, double vx) {
  if ((vx > 0) && (o->activeWallBump & TILEMAP_BUMP_WEST_MASK))
    return;

  if ((vx < 0) && (o->activeWallBump & TILEMAP_BUMP_EAST_MASK))
    return;

  o->vx = vx;
}

void object_set_y_velocity(object_t* o, double vy) {
  if ((vy > 0) && (o->activeWallBump & TILEMAP_BUMP_NORTH_MASK))
    return;

  if ((vy < 0) && (o->activeWallBump & TILEMAP_BUMP_SOUTH_MASK))
    return;

  o->vy = vy;
}

void object_get_map_location(const object_t* o, int* mapx, int* mapy) {
  if (mapx)
    *mapx = o->x / o->image->tw;

  if (mapy)
    *mapy = o->y / o->image->th;
}

void object_set_image(object_t* o, image_t* i) {
  o->image = i;
}
