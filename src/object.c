#include <stdlib.h>

#include "object.h"

#include "image.h"


int object_init(object_t* o, image_t* image, int tx, int ty, int tw, int th, int aperiod, int acount, int x, int y, int layer) {
    o->image = image;
    o->tx = tx;
    o->ty = ty;
    o->tw = tw;
    o->th = th;
    o->animperiod = aperiod;
    o->animcount = acount;
    o->x = x;
    o->y = y;
    o->layer = layer;
    o->index = -1;

    object_set_velocity(o, 0, 0);
    return 1;
}

void object_deinit(object_t* o) {
    // nothing yet
}


object_t* object_create(image_t* image, int tx, int ty, int tw, int th, int aperiod, int acount, int x, int y, int layer) {
    object_t* o = (object_t*)malloc(sizeof(object_t*));
    if(!o)
        return NULL;

    if(!object_init(o, image, tx, ty, tw, th, aperiod, acount, x, y, layer)) {
        free(o);
        return NULL;
    }

    return o;
}


void object_set_sprite(object_t* o, int tx, int ty, int animcount, int animperiod) {
    o->tx = tx;
    o->ty = ty;
    o->animperiod = animperiod;
    o->animcount = animcount;
}


void object_destroy(object_t* o) {
    object_deinit(o);
    free(o);
}


void object_draw(const object_t* o, int vx, int vy) {
    int orig_tw = o->image->tw;
    int orig_th = o->image->th;
    o->image->tw = o->tw;
    o->image->th = o->th;
    image_draw_tile(o->image, o->tx, o->ty, o->x - vx, o->y - vy);
    o->image->tw = orig_tw;
    o->image->th = orig_th;
}


void object_set_velocity(object_t* o, int velx, int vely) {
    o->velx = velx;
    o->vely = vely;
}


void object_set_x_velocity(object_t* o, int velx) {
    o->velx = velx;
}


void object_set_y_velocity(object_t* o, int vely) {
    o->vely = vely;
}


void object_get_map_location(const object_t* o, int* mapx, int* mapy) {
    if(mapx)
        *mapx = o->x / o->image->tw;
    
    if(mapy)
        *mapy = o->y / o->image->th;
}

