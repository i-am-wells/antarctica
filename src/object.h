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

    // TODO remove?
    int animperiod, animcount;

    // map location
    int x, y, layer;
    
    // bounding box;
    int boundX, boundY, boundW, boundH;

    // sprite draw offset
    int offX, offY; 

    size_t index;

    int toRemove;

    // physics
    double vx, vy;

    int activeWallBump;

    int updateParity;
} object_t;


int object_init(object_t* o, image_t* image, int tx, int ty, int tw, int th, int aperiod, int acount, int x, int y, int layer);

void object_deinit(object_t* o);


void object_set_bounding_box(object_t* o, int x, int y, int w, int h);

void object_set_sprite(object_t* o, int tx, int ty, int tw, int th, int animcount, int animperiod, int offX, int offY);

void object_draw(const object_t* o, int vx, int vy, int counter);

void object_set_velocity(object_t* o, double vx, double vy);
void object_set_x_velocity(object_t* o, double vx);
void object_set_y_velocity(object_t* o, double vy);

void object_get_map_location(const object_t* o, int* mapx, int* mapy);

void object_set_image(object_t* o, image_t* i);

#endif

