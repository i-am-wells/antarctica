/**
 *  \file tilemap.h
 */

#ifndef _OBJECT_H
#define _OBJECT_H

#include "image.h"


typedef struct object_t {
    // image and animation info
    image_t* image;
    int tx, ty, tw, th;
    int animperiod, animcount;

    // map location
    int x, y, layer;
    
    // velocity
    int velx, vely;

    // index in array
    size_t index;
} object_t;


int object_init(object_t* o, image_t* image, int tx, int ty, int tw, int th, int aperiod, int acount, int x, int y, int layer);

void object_deinit(object_t* o);


object_t* object_create(image_t* image, int tx, int ty, int tw, int th, int aperiod, int acount, int x, int y, int layer);

void object_set_sprite(object_t* o, int tx, int ty, int animcount, int animperiod);

void object_destroy(object_t* o);

void object_draw(const object_t* o, int vx, int vy);

void object_set_velocity(object_t* o, int velx, int vely);
void object_set_x_velocity(object_t* o, int velx);
void object_set_y_velocity(object_t* o, int vely);

void object_get_map_location(const object_t* o, int* mapx, int* mapy);

#endif

