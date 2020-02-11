#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <SDL.h>

#include "tilemap.h"
#include "image.h"
#include "engine.h"
#include "object.h"

#include "vec.h"

#define TILEMAP_FILE_FORMAT_LATEST_VERSION 1
#define DEFAULT_NON_EMPTY 4294967295

void tilemap_deinit(tilemap_t* t) {
    if(t) {
        // Free tiles arrays
        if(t->tiles) {
            for(size_t i = 0; i < t->nlayers; i++) {
                free(t->tiles[i]);
                t->tiles[i] = NULL;
            }

            free(t->tiles);
            t->tiles = NULL;
        }
        
        if (t->should_store_sparse_layer)
          free(t->should_store_sparse_layer);
        
        if (t->last_non_empty_tile)
          free(t->last_non_empty_tile);

        vec_deinit(&(t->objectvec));
    }
}


int tilemap_init(tilemap_t * t, size_t nlayers, size_t w, size_t h) {
    assert(t);

    if(w && h && nlayers) {
        // Allocate layers array
        t->tiles = (tile_t**)calloc(1, nlayers * sizeof(tile_t*));
        if(!t->tiles)
            return 0;

        // Allocate each layer
        tile_t** maplayers = t->tiles;
        for(size_t i = 0; i < nlayers; i++) {
            maplayers[i] = (tile_t*)calloc(w * h, sizeof(tile_t));
            if(!(maplayers[i])) {
                tilemap_deinit(t);
                return 0;
            }
        }
    } else {
        t->tiles = NULL;
    }

    // Create object vector
    vec_init(&(t->objectvec), 8);

    // no objects yet
    t->head = NULL;

    t->cameraobject = NULL;

    tilemap_set_object_callbacks(t, NULL, NULL, NULL);

    t->w = w;
    t->h = h;
    t->nlayers = nlayers;

    t->updateParity = 0;

    t->should_store_sparse_layer = (int*)calloc(nlayers, sizeof(int));
    if (!t->should_store_sparse_layer) {
      tilemap_deinit(t);
      return 0;
    }

    t->last_non_empty_tile = (uint32_t*)malloc(nlayers * sizeof(uint32_t));
    if (!t->last_non_empty_tile) {
      tilemap_deinit(t);
      return 0;
    }
    for (size_t i = 0; i < nlayers; i++) {
      t->last_non_empty_tile[i] = DEFAULT_NON_EMPTY;
    }

    return 1;
}

tile_t * tilemap_get_tile_address(const tilemap_t * t, size_t layer, size_t x, size_t y) {
    if((layer < t->nlayers)
            && (x < t->w)
            && (y < t->h)) {
        return t->tiles[layer] + y * t->w + x;
    }

    // Return NULL if (layer, x, y) isn't on the map.
    return NULL;
}

// TODO x, y should always be int
int tilemap_empty(const tilemap_t* t, size_t layer, int x, int y) {
  tile_t* tile = tilemap_get_tile_address(t, layer, x, y);
  return (tile->tilex || tile->tiley || tile->flags) == 0;
}

static void tilemap_set_last_non_empty_tile(tilemap_t* t, size_t layer, uint32_t x, uint32_t y) {
    if (t->should_store_sparse_layer[layer]) {
      uint32_t pos = y * t->w + x;
      if (t->last_non_empty_tile[layer] == DEFAULT_NON_EMPTY || 
          pos > t->last_non_empty_tile[layer]) {
        t->last_non_empty_tile[layer] = pos;
      }
    }
}

void tilemap_set_tile(tilemap_t* t, size_t layer, size_t x, size_t y, int tilex, int tiley) {
    assert(t);

    // Set the image to be used for this map square
    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        tileptr->tilex = tilex & 0xff;
        tileptr->tiley = tiley & 0xff;
    
        tilemap_set_last_non_empty_tile(t, layer, x, y);
    }
}

int tilemap_get_tile(tilemap_t* t, size_t layer, size_t x, size_t y, int* tx, int* ty) {
    assert(t);

    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        if(tx)
            *tx = tileptr->tilex;
        if(ty)
            *ty = tileptr->tiley;

        return 1;
    }

    return 0;
}


int tilemap_get_flags(const tilemap_t* t, size_t layer, size_t x, size_t y) {
    assert(t);

    // set the image to be used for this map square
    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        return tileptr->flags;
    }

    return 0;
}


void tilemap_set_flags(tilemap_t* t, size_t layer, size_t x, size_t y, int mask) {
    assert(t);

    // set the image to be used for this map square
    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        tileptr->flags |= (uint16_t)(mask & 0xffff);
    }
}


void tilemap_clear_flags(tilemap_t* t, size_t layer, size_t x, size_t y, int mask) {
    assert(t);

    // Set the image to be used for this map square
    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        tileptr->flags &= (uint16_t)(~(mask & 0xffff));
    }
}


void tilemap_overwrite_flags(tilemap_t* t, size_t layer, size_t x, size_t y, int mask) {
    assert(t);

    // Set the image to be used for this map square
    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        tileptr->flags = (uint16_t)(mask & 0xffff);
    }
}


void tilemap_set_object_callbacks(tilemap_t* t, void* data, void (*bump)(void*, object_t*, int), void (*collision)(void*, object_t*, object_t*)) {
    assert(t);
    t->bump_callback = bump;
    t->collision_callback = collision;
    t->object_callback_data = data;
}


#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

// TODO move centering math into drawing functions
//
void tilemap_get_camera_location(const tilemap_t* t, int pw, int ph, int* x, int* y) {
    if(!t->cameraobject)
        return;

    int px = MAX(0, t->cameraobject->x - (pw / 2));
    int py = MAX(0, t->cameraobject->y - (ph / 2));
    px = MIN(px, t->w * t->cameraobject->image->tw - pw);
    py = MIN(py, t->h * t->cameraobject->image->th - ph);

    if(x)
        *x = px;

    if(y)
        *y = py;
}

void tilemap_draw_layer_at_camera_object(const tilemap_t* t, const image_t* i, int layer, int pw, int ph, int counter, int draw_flags) {
    int px = 0;
    int py = 0;
    tilemap_get_camera_location(t, pw, ph, &px, &py);
    tilemap_draw_layer(t, i, layer, px, py, pw, ph, counter, draw_flags);
}


#define OBJECT_AT(ovec, i) ((object_t*)(ovec.data[(i)]))


static size_t tilemap_binary_search_objects(const tilemap_t* t, int q, size_t first, size_t last) {
    if(last == -1)
        return -1;
        
    int firstval = OBJECT_AT(t->objectvec, first)->y;
    if(q < firstval)
        return first - 1;

    int lastval = OBJECT_AT(t->objectvec, last)->y;
    if(q >= lastval)
        return last;

    while(last - first > 1) {
        size_t mid = (first + last) / 2;

        int midval = OBJECT_AT(t->objectvec, mid)->y;

        if(midval > q) {
            last = mid;
        } else if(midval == q) {
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
    if(dy > 0) {
        while((dest_idx < t->objectvec.size) && (OBJECT_AT(t->objectvec, dest_idx)->y < next_y))
            dest_idx++;

        dest_idx--;
    } else if(dy < 0) {
        while((dest_idx > 0) && (OBJECT_AT(t->objectvec, dest_idx - 1)->y > next_y))
            dest_idx--;
    }

    // Move object in objects vector
    vec_move(&(t->objectvec), dest_idx, object_idx);
    size_t firstI = MIN(object_idx, dest_idx);
    size_t lastI = MAX(object_idx, dest_idx);
    for(size_t i = firstI; i <= lastI; i++)
        OBJECT_AT(t->objectvec, i)->index = i;

    // Update object's coordinates on map
    o->x += dx;
    o->y += dy;
}


void tilemap_add_object(tilemap_t* t, object_t* o) {
    size_t index = tilemap_binary_search_objects(t, o->y, 0, t->objectvec.size - 1);
    index++;

    assert(vec_insert(&(t->objectvec), index, o));
    o->index = index;

    for(size_t i = o->index + 1; i < t->objectvec.size; i++) {
        object_t* obj = OBJECT_AT(t->objectvec, i);
        obj->index = i;
    }
}


void tilemap_remove_object(tilemap_t* t, object_t* o) {
    vec_remove(&(t->objectvec), o->index, 1);
    for(size_t i = o->index; i < t->objectvec.size; i++) {
        object_t* obj = OBJECT_AT(t->objectvec, i);
        obj->index = i;
    }
}

static void tilemap_remove_object_by_index(tilemap_t* t, size_t idx) {
    vec_remove(&(t->objectvec), idx, 1);
    for(size_t i = idx; i < t->objectvec.size; i++) {
        object_t* obj = OBJECT_AT(t->objectvec, i);
        obj->index = i;
    }
}


void tilemap_move_object_absolute(tilemap_t* t, object_t* o, int x, int y) {
    tilemap_remove_object(t, o);
    o->x = x;
    o->y = y;
    tilemap_add_object(t, o);
}

#define ABS(a) ((a)<0)?(-a):(a)

// True if a and b positive or a and b negative
static inline int samesign(double a, double b) {
    return (a * b) > 0;
}


/*
// TODO untested. In theory, checks wall bumps for arbitrarily high vx, vy
static int check_wall_bump(const tilemap* t, size_t layer, int sx, int sy, int* vx, int* vy) {
    // TODO use actual tile dimensions instead
    const int tw = 16;
    const int th = 16;
    

    if(*vx == 0) {
        if(*vy == 0) {
            return;
        } else {
            // move in y only
            int direction = (*vy > 0) ? 1 : -1;
            int mapX = sx / tw;
            int mapY = sy / th;
            int y = sy;

            // check diagonal bump for first square
            // TODO

            while(1) {
                int newY = y + direction * MIN(th, ABS(*vy));
                int newMapY = newY / th;

                if(newMapY != mapY) {
                    int flags = tilemap_get_flags(t, layer, mapX, newMapY);

                    // TODO check diagonal
                    if(direction > 0) {
                        // check north flag
                        if(flags & TILEMAP_BUMP_NORTH_MASK) {
                            *vy = (newMapY * th) - sy - 1;
                            return TILEMAP_BUMP_NORTH_MASK;
                        }
                    } else {
                        // check south flag
                        if(flags & TILEMAP_BUMP_SOUTH_MASK) {
                            *vy = (mapY * th) - sy;
                            return TILEMAP_BUMP_SOUTH_MASK;
                        }
                    }
                }
                
                mapY = newMapY;
                y = newY;

                if(((direction < 0) && (newY < (sy + *vy))) || ((direction > 0) && (newY > (sy + *vy)))) {
                    break;
                }
            }
        }
    } else {
        if(*vy == 0) {
            // move in x only
            int direction = (*vx > 0) ? 1 : -1;
            int mapX = sx / tw;
            int mapY = sy / th;
            int x = sx;

            // TODO check diagonal bump for first square

            while(1) {
                int newX = x + direction * MIN(tw, ABS(*vx));
                int newMapX = newX / tw;

                if(newMapX != mapX) {
                    int flags = tilemap_get_flags(t, layer, newMapX, mapY);

                    // TODO check diagonal
                    if(direction > 0) {
                        // check west flag
                        if(flags & TILEMAP_BUMP_WEST_MASK) {
                            *vx = (newMapX * tw) - sx - 1;
                            return TILEMAP_BUMP_WEST_MASK;
                        }
                    } else {
                        // check east flag
                        if(flags & TILEMAP_BUMP_EAST_MASK) {
                            *vx = (mapX * tw) - sx;
                            return TILEMAP_BUMP_EAST_MASK;
                        }
                    }
                }
                
                mapX = newMapX;
                x = newX;

                if(((direction < 0) && (newX < (sx + *vx))) || ((direction > 0) && (newX > (sx + *vx)))) {
                    break;
                }
            }
        } else {
            // move in x and y 
            // TODO diagonals

            // which edges to check?
            int flagEW, flagNS;
            if(*vy > 0) {
                if(*vx > 0) {
                    flagEW = TILEMAP_BUMP_WEST_MASK;
                    flagNS = TILEMAP_BUMP_NORTH_MASK;
                } else {
                    flagEW = TILEMAP_BUMP_EAST_MASK;
                    flagNS = TILEMAP_BUMP_NORTH_MASK;
                }
            } else {
                if(*vx > 0) {
                    flagEW = TILEMAP_BUMP_WEST_MASK;
                    flagNS = TILEMAP_BUMP_SOUTH_MASK;
                } else {
                    flagEW = TILEMAP_BUMP_EAST_MASK;
                    flagNS = TILEMAP_BUMP_SOUTH_MASK;
                }
            }

            // march to the end point checking edges
            double x = sx;
            double y = sy;
            int mapX = sx / tw;
            int mapY = sy / th;
            double endX = sx + *vx;
            double endY = sy + *vy;
            
            double slope = (double)(*vy) / (double)(*vx);

            // loop until we're just past the end point
            // (loop while endX - x has same sign as vx, etc.)
            while(samesign(endX - x, *vx) && samesign(endY - y, *vy)) {
                // TODO diagonals
                
                
                // find boundaries of current tile
                int x0 = mapX * tw;
                int x1 = x0 + tw;
                int y0 = mapY * th;
                int y1 = y0 + th;

                int checkFlag = flagEW;


                // solve for intersections
                double newX, newY;
                int newMapX, newMapY;
                if(flagEW & TILEMAP_BUMP_WEST_MASK) {
                    newX = x1;
                    newY = y + (x1 - x) * slope;
                    newMapX = mapX + 1;
                    newMapY = mapY;
                } else {
                    newX = x0;
                    newY = y + (x0 - x) * slope;
                    newMapX = mapX - 1;
                    newMapY = mapY;
                }
                
                // do we actually hit a horizontal boundary first?
                if(newY > y1) {
                    newX = x + (y1 - y) / slope;
                    newY = y1;
                    newMapX = mapX;
                    newMapY = mapY + 1
                    checkFlag = flagNS;
                } else if(newY <= y0) {
                    newX = x + (y - y0) / slope;
                    newY = y0;
                    newMapX = mapX;
                    newMapY = mapY - 1;
                    checkFlag = flagNS;
                }

                // check next tile
                if(tilemap_get_flags(t, layer, newMapX, newMapY) & checkFlag) {
                    *vx = newX - sx;
                    *vy = newY - sy;
                    return checkFlag;
                }

                // last thing: move to new position
                mapX = newMapX;
                mapY = newMapY;
                x = newX;
                y = newY;
            }
        }
    }

    // no bump
    return 0;
}

// end bad check wall bump
*/


/*
// Returns 1 if two rectangles overlap
static int isOverlap(int xa0, int ya0, int xa1, int ya1, int xb0, int yb0, int xb1, int yb1) {
    
    int xOverlap = ((xa0 < xb0) && (xa1 > xb0)) || ((xa0 > xb0) && (xa0 < xb1));
    int yOverlap = ((ya0 < yb0) && (ya1 > yb0)) || ((ya0 > yb0) && (ya0 < yb1));

    return xOverlap && yOverlap;
}
*/


// Returns a bump direction for A
static int checkCollision(int xa0, int ya0, int xa1, int ya1, int xb0, int yb0, int xb1, int yb1) {
    int diffX = 0;
    int diffY = 0;

    xa1--;
    xb1--;
    ya1--;
    yb1--;

    if(ya0 <= yb0) {
        if(ya1 > yb0)
            diffY = ya1 - yb0;
        else
            return 0;

        if(xa0 <= xb0) {
            if(xa1 > xb0)
                diffX = xa1 - xb0;
            else
                return 0;
            
            if(diffX > diffY)
                return TILEMAP_BUMP_NORTH_MASK;
            else
                return TILEMAP_BUMP_WEST_MASK;
        } else if(xa0 > xb0) {
            if(xb1 > xa0)
                diffX = xb1 - xa0;
            else
                return 0;
        
            if(diffX > diffY)
                return TILEMAP_BUMP_NORTH_MASK;
            else
                return TILEMAP_BUMP_EAST_MASK;
        }
    } else if(ya0 > yb0) {
        if(yb1 > ya0)
            diffY = yb1 - ya0;
        else
            return 0;
        
        if(xa0 <= xb0) {
            if(xa1 > xb0)
                diffX = xa1 - xb0;
            else
                return 0;
            
            if(diffX > diffY)
                return TILEMAP_BUMP_SOUTH_MASK;
            else
                return TILEMAP_BUMP_WEST_MASK;
        } else if(xa0 > xb0) {
            if(xb1 > xa0)
                diffX = xb1 - xa0;
            else
                return 0;
        
            if(diffX > diffY)
                return TILEMAP_BUMP_SOUTH_MASK;
            else
                return TILEMAP_BUMP_EAST_MASK;
        }
    }

    return 0;
}


static int check_wall_bump(const tilemap_t* t, object_t* o) {    
    // TODO fix
    const int tw = 16;
    const int th = 16;
    
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
    int mapX0 = (x0 + w0 - 1) / tw; // FURTHEST
    int checkMapX = (x1 + w0 - 1) / tw;    
    if(checkMapX > mapX0) {
        // if traveling east
        checkFlagX = TILEMAP_BUMP_WEST_MASK;
    } else if((x1 / tw) < (x0 / tw)) {
        // if traveling west
        checkMapX = x1 / tw;
        checkFlagX = TILEMAP_BUMP_EAST_MASK;
    }

    // Check edge for bump flag
    if(checkFlagX) {
        int mapY0 = y1 / th;
        int mapY1 = (y1 + h0) / th;
        for(int y = mapY0; y <= mapY1; y++) {
            if(tilemap_get_flags(t, o->layer, checkMapX, y) & checkFlagX) {
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
    int mapY0 = (y0 + h0 - 1) / th;
    int checkMapY = (y1 + h0 - 1) / th;    
    if(checkMapY > mapY0) {
        // traveling south
        checkFlagY = TILEMAP_BUMP_NORTH_MASK;
    } else if((y1 / tw) < (y0 / tw)) {
        // if traveling north
        checkFlagY = TILEMAP_BUMP_SOUTH_MASK;
        checkMapY = y1 / th;
    }

    // Check edge for bump flag
    if(checkFlagY) {
        int mapX0 = x1 / tw;
        int mapX1 = (x1 + w0) / tw;
        for(int x = mapX0; x <= mapX1; x++) {
            if(tilemap_get_flags(t, o->layer, x, checkMapY) & checkFlagY) {
                bumpDir |= checkFlagY;
                break;
            }
        }
    }

        
    return bumpDir;
}


void tilemap_update_objects(tilemap_t* t) {
    // updateParity is -1 if "abort update" has been called
    if(t->updateParity == -1) {
        t->updateParity = 0;
        return;
    }

    for(size_t i = 0; i < t->objectvec.size; i++) {
        object_t* objectA = OBJECT_AT(t->objectvec, i);

        if(objectA->toRemove) {
            tilemap_remove_object_by_index(t, i);
            i--;
            continue;
        }

        // If we've already seen objectA this round (meaning it moved forward
        // in the object vector) skip it.
        if(objectA->updateParity != t->updateParity)
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
        for(size_t j = i + 1; j < t->objectvec.size; j++) {
            object_t* objectB = OBJECT_AT(t->objectvec, j);

            if(objectB->toRemove) {
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

            //if(isOverlap(nextXA0, nextYA0, nextXA1, nextYA1, nextXB0, nextYB0, nextXB1, nextYB1)) {
            int collisionDir = checkCollision(nextXA0, nextYA0, nextXA1, nextYA1, nextXB0, nextYB0, nextXB1, nextYB1);
            if(collisionDir) {
                objectA->activeWallBump |= collisionDir;
                switch(collisionDir) {
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
                if(t->updateParity == -1) {
                    t->updateParity = 0;
                    return;
                }
            }
        }

        // Check wall bump. This is done last so that no objects end up overlapping
        // walls while still traveling towards them.
        int wallBumpDir = check_wall_bump(t, objectA);    
        if(wallBumpDir)
            t->bump_callback(t->object_callback_data, objectA, wallBumpDir);
        
        objectA->activeWallBump |= wallBumpDir;
       

        // updateParity is -1 if "abort update" has been called
        if(t->updateParity == -1) {
            t->updateParity = 0;
            return;
        }

        // Wall bump: object bounces perfectly
        if(objectA->activeWallBump & TILEMAP_BUMP_NORTH_MASK)
            dy = MIN(0, dy);

        if(objectA->activeWallBump & TILEMAP_BUMP_SOUTH_MASK)
            dy = MAX(0, dy);

        if(objectA->activeWallBump & TILEMAP_BUMP_EAST_MASK)
            dx = MAX(0, dx);

        if(objectA->activeWallBump & TILEMAP_BUMP_WEST_MASK)
            dx = MIN(0, dx);

        
        // If object has been removed already, remove it before tilemap_move_object_relative
        if(objectA->toRemove) {
            tilemap_remove_object_by_index(t, i);
            i--;
            continue;
        } else {
            tilemap_move_object_relative(t, objectA, dx, dy);
        }

        // run update callback
        t->object_update_callback(t->object_callback_data, objectA);
        
        // updateParity is -1 if "abort update" has been called
        if(t->updateParity == -1) {
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
void tilemap_draw_objects(const tilemap_t* t, int layer, int px, int py, int pw, int ph, int counter) {

    // TODO Find range of objects to draw
    size_t idx0, idx1;
    //if(t->objectvec_orientation == 0) {
        //idx0 = tilemap_binary_search_objects(t, px, 0, t->objectvec.size - 1);
        //idx1 = tilemap_binary_search_objects(t, px + pw, idx0, t->objectvec.size - 1);
    //} else if(t->objectvec_orientation == 1) {
        
    /*
        idx0 = tilemap_binary_search_objects(t, py, 0, t->objectvec.size - 1);
        if(idx0 >= t->objectvec.size)
            idx0 = 0;

        idx1 = tilemap_binary_search_objects(t, py + ph, idx0, t->objectvec.size - 1);
        idx1++;
        //}
    */

    // For now, just draw all objects
    idx0 = 0;
    idx1 = t->objectvec.size - 1;

    for(size_t i = idx0; i <= idx1; i++) {
        object_t* obj = OBJECT_AT(t->objectvec, i);
        
        if((obj->layer == layer)
                && (obj->x < px + pw)
                && (obj->y < py + ph)
                && (obj->x + obj->tw > px)
                && (obj->y + obj->th > py)) {
            object_draw(obj, px, py, counter);
        }
    }
}

static void tilemap_draw_flags(SDL_Renderer* renderer, uint16_t flags, int x, int y, int tw, int th) {
    int thickness = 2;
    SDL_Rect dst;

    int x1 = x + tw - thickness;
    int y1 = y + th - thickness;

    // draw map square borders in red to show directional bump flags
    SDL_SetRenderDrawColor(renderer, 255, 0, 0, SDL_ALPHA_OPAQUE);
    if(flags & TILEMAP_BUMP_EAST_MASK) {
      dst.x = x1;
      dst.y = y;
      dst.w = thickness;
      dst.h = th;
      SDL_RenderFillRect(renderer, &dst);
    }
    if(flags & TILEMAP_BUMP_NORTH_MASK) {
      dst.x = x;
      dst.y = y;
      dst.w = tw;
      dst.h = thickness;
      SDL_RenderFillRect(renderer, &dst);
    }
    if(flags & TILEMAP_BUMP_WEST_MASK) {
      dst.x = x;
      dst.y = y;
      dst.w = thickness;
      dst.h = th;
      SDL_RenderFillRect(renderer, &dst);
    }
    if(flags & TILEMAP_BUMP_SOUTH_MASK) {
      dst.x = x;
      dst.y = y1;
      dst.w = tw;
      dst.h = thickness;
      SDL_RenderFillRect(renderer, &dst);
    }

    // TODO remove
    if(flags & (TILEMAP_BUMP_NORTHWEST_MASK | TILEMAP_BUMP_SOUTHEAST_MASK)) {
      SDL_RenderDrawLine(renderer, x, y+th, x+tw, y);
    }
    if(flags & (TILEMAP_BUMP_NORTHEAST_MASK | TILEMAP_BUMP_SOUTHWEST_MASK)) {
      SDL_RenderDrawLine(renderer, x, y, x+tw, y+th);
    }

    // draw a green rectangle in the center of map squares with
    // the "action" flag set
    SDL_SetRenderDrawColor(renderer, 0, 255, 0, SDL_ALPHA_OPAQUE);
    if(flags & TILEMAP_ACTION_MASK) {
      dst.x = x + tw / 4;
      dst.y = y + th / 4;
      dst.w = tw / 2;
      dst.h = th / 2;
      SDL_RenderFillRect(renderer, &dst);
    }
}

static void tilemap_draw_row(
    const tilemap_t* t, 
    const image_t* i, 
    int layer, 
    int px, 
    int dy, 
    int pw, 
    int row, 
    int counter,
    int draw_flags) {

  // TODO change this
  counter /= 2;
  
  for(int xx = px / i->tw; xx <= (px + pw) / i->tw; xx++) {
    int dx = xx * i->tw - px;
    tile_t* tile = tilemap_get_tile_address(t, layer, xx, row);

    if(tile) {
      // TODO what is this? remove
      if(!((tile->tilex == 16) && (tile->tiley == 0))) {
        // TODO rewrite animation
        int tiley = tile->tiley + (counter / TILE_ANIM_PERIOD(tile)) % TILE_ANIM_COUNT(tile);
        image_draw_tile(i, tile->tilex, tiley, dx, dy);

        if (draw_flags)
          tilemap_draw_flags(i->renderer, tile->flags, dx, dy, i->tw, i->th);
      }
    }
  }
}

static void tilemap_draw_layer_rows(const tilemap_t* t, const image_t* i, int layer, int px, int py, int pw, int row_start, int row_end, int counter, int draw_flags) { 
    // if drawing flags, save current drawing color
    Uint8 or, og, ob, oa;
    if (draw_flags)
      SDL_GetRenderDrawColor(i->renderer, &or, &og, &ob, &oa);

    for(int row = row_start; row <= row_end; row++) {
        int dy = row * i->th - py;
        tilemap_draw_row(t, i, layer, px, dy, pw, row, counter, draw_flags);
    }

    if (draw_flags)
      SDL_SetRenderDrawColor(i->renderer, or, og, ob, oa);
}

void tilemap_draw_layer(const tilemap_t* t, const image_t* i, int l, int px, int py, int pw, int ph, int counter, int draw_flags) {
  int row_start = py / i->th;
  int row_end = row_start + (ph / i->th) + 2;
  tilemap_draw_layer_rows(t, i, l, px, py, pw, row_start, row_end, counter, draw_flags);
}


// draw objects from one map layer
void tilemap_draw_objects_interleaved(const tilemap_t* t, const image_t* img, int layer, int px, int py, int pw, int ph, int counter, int draw_flags) {
    // Find range of objects to draw
    size_t idx0, idx1;

    // For now, just draw all objects
    idx0 = 0;
    idx1 = t->objectvec.size - 1;

    // top row of tiles
    int lastMapY = py / img->th;

    for(size_t i = idx0; i <= idx1; i++) {
        object_t* obj = OBJECT_AT(t->objectvec, i);
        
        // bottom edge of sprite
        int bottomY = obj->y + obj->offY + obj->th - 1;

        // do we need to draw more tile rows first?
        int bottomMapY = bottomY / img->th;
        if(bottomMapY > lastMapY) {
            // draw new rows
            tilemap_draw_layer_rows(t, img, layer, px, py, pw, lastMapY, bottomMapY, counter, draw_flags);

            lastMapY = bottomMapY;
        }

        if((obj->layer == layer)
                && (obj->x + obj->offX < px + pw)
                && (obj->y + obj->offY < py + ph)
                && (obj->x + obj->offX + obj->tw >= px)
                && (obj->y + obj->offY + obj->th >= py)) {
            object_draw(obj, px, py, counter);    
        }
    }

    // Draw remaining rows
    tilemap_draw_layer_rows(t, img, layer, px, py, pw, lastMapY, (py + ph) / img->th, counter, draw_flags);
}
    

void tilemap_draw_objects_at_camera_object(const tilemap_t* t, const image_t* img, int layer, int pw, int ph, int counter, int draw_flags) {
    int px = 0;
    int py = 0;
    tilemap_get_camera_location(t, pw, ph, &px, &py);
    tilemap_draw_objects_interleaved(t, img, layer, px, py, pw, ph, counter, draw_flags);
}


tile_t* tilemap_export_slice(const tilemap_t* t, int x, int y, int w, int h) {
    assert(t);
    assert((x > -1) && (x < t->w) && ((x+w) <= t->w));
    assert((y > -1) && (y < t->h) && ((y+h) <= t->h));

    tile_t* slice = (tile_t*)malloc(t->nlayers * w * h * sizeof(tile_t));
    if(!slice)
        return NULL;

    size_t rowsize = w * sizeof(tile_t);

    for(size_t l = 0; l < t->nlayers; l++) {
        tile_t* destlayer = slice + l * w * h;
        tile_t* srclayer = t->tiles[l];

        for(int yy = 0; yy < h; yy++) {
            // Copy map rows
            memcpy(destlayer + yy * w, srclayer + (y + yy) * t->w + x, rowsize);
        }
    }

    return slice;
}


void tilemap_patch(tilemap_t* t, tile_t* patch, int x, int y, int w, int h) {
    assert(t);
    assert(patch);
    assert((x > -1) && (x < t->w) && ((x+w) < t->w));
    assert((y > -1) && (y < t->h) && ((y+h) < t->h));
    
    size_t rowsize = w * sizeof(tile_t);

    // For each layer, copy rows of the patch array into the map
    for(int l = 0; l < t->nlayers; l++) {
        tile_t* layer = t->tiles[l];
        tile_t* patchlayer = patch + (l * w * h);

        for(int my = 0; my < h; my++) {
            //for(int mx = 0; mx < w; mx++) {
                memcpy(layer + (y + my) * t->w + x, patchlayer + my * w, rowsize);
            //}
        }
    }
}

static int tilemap_read_v0(tilemap_t* t, FILE* f, const char* path) { 
  t->tiles = (tile_t**)malloc(t->nlayers * sizeof(tile_t*));
  if(!t->tiles) {
    fclose(f);
    return 0;
  }

  // Read each layer
  for(size_t i = 0; i < t->nlayers; i++) {

    // Allocate layer
    size_t layer_bytes_size = t->w * t->h * sizeof(tile_t);
    t->tiles[i] = (tile_t*)malloc(layer_bytes_size);
    if(!t->tiles[i])
      goto tilemap_read_fail;

    // Read layer
    if(fread(t->tiles[i], layer_bytes_size, 1, f) != 1) {
      fprintf(stderr, "couldn't load %s: file ends unexpectedly\n", path);
      goto tilemap_read_fail;
    }
  }

  // TODO check
  vec_init(&(t->objectvec), 8);

  // Success
  fclose(f);
  return 1;

tilemap_read_fail:
  tilemap_deinit(t);
  fclose(f);
  return 0;
}

static int read_pos(FILE* f, uint32_t* out) {
  char buf[4];
  if (fread(buf, 4, 1, f) != 1)
    return 0;

  *out = buf[0];
  for (int i = 1; i < 4; i++) {
    *out <<= 8;
    *out |= 0xff & buf[i];
  }
  return 1;
}

static int write_pos(FILE* f, uint32_t pos) {
  char buf[4];
  buf[0] = (pos & 0xff000000) >> 24;
  buf[1] = (pos & 0xff0000) >> 16;
  buf[2] = (pos & 0xff00) >> 8;
  buf[3] = pos & 0xff;
  if (fwrite(buf, 4, 1, f) != 1)
    return 0;
  return 1;
}

static int tilemap_read_v1(tilemap_t* t, FILE* f, const char* path) {
  t->tiles = (tile_t**)malloc(t->nlayers * sizeof(tile_t*));
  if(!t->tiles) {
    fclose(f);
    return 0;
  }
  
  if(fread(t->should_store_sparse_layer, t->nlayers * sizeof(int), 1, f) != 1)
    goto tilemap_read_fail;

  // Read each layer
  for(size_t i = 0; i < t->nlayers; i++) {
    // Allocate layer
    size_t layer_bytes_size = t->w * t->h * sizeof(tile_t);
    t->tiles[i] = (tile_t*)malloc(layer_bytes_size);
    if(!t->tiles[i])
      goto tilemap_read_fail;
    
    // Read layer
    if (t->should_store_sparse_layer[i]) {
      fprintf(stderr, "offset: %lu\n", ftell(f));
      // Get position of last non-empty tile
      if (!read_pos(f, t->last_non_empty_tile + i)) {
        fprintf(stderr, "couldn't load %s: file ends unexpectedly\n", path);
        goto tilemap_read_fail;
      }

      uint32_t pos = DEFAULT_NON_EMPTY;
      fprintf(stderr, "last non empty for layer %zu: %u\n", i, t->last_non_empty_tile[i]);
      while (pos != t->last_non_empty_tile[i]) {
        // Read tile position
        if (!read_pos(f, &pos)) {
          fprintf(stderr, "couldn't load %s: file ends unexpectedly\n", path);
          goto tilemap_read_fail;
        }

        int px = pos % t->w;
        int py = pos / t->h;
        fprintf(stderr, "sparse read at %zu, %d, %d\n", i, px, py);
        
        // Read tile
        if (fread(t->tiles[i] + pos, sizeof(tile_t), 1, f) != 1) {
          fprintf(stderr, "couldn't load %s: file ends unexpectedly\n", path);
          goto tilemap_read_fail;
        }
      }
    } else {
      if(fread(t->tiles[i], layer_bytes_size, 1, f) != 1) {
        fprintf(stderr, "couldn't load %s: file ends unexpectedly\n", path);
        goto tilemap_read_fail;
      }
    }
  }

  // Success
  fclose(f);
  return 1;

tilemap_read_fail:
  tilemap_deinit(t);
  fclose(f);
  return 0;
}

int tilemap_read_from_file(tilemap_t * t, const char * path) {
    assert(t);

    FILE * f = fopen(path, "rb");
    if(!f) {
      fprintf(stderr, "failed to open %s for reading\n", path);
      return 0;
    }

    // Read map file header (magic(2) + version(2) + nlayers(1) + w(2) + h(2) = 9 bytes)
    char buffer[32];
    int nread = fread(buffer, 9, 1, f);
    if(nread != 1) {
        fprintf(stderr, "failed to read from %s\n", path);
        fclose(f);
        return 0;
    }

    // magic
    if(!((buffer[0] == (char)0xac) && (buffer[1] == (char)0xc0))) {
        fprintf(stderr, "%s missing magic bytes\n", path);
        fclose(f);
        return 0;
    }

    t->nlayers = 0;
    t->w = 0;
    t->h = 0;

    // Get dimensions
    int nlayers = buffer[4];
    int w = ((buffer[5] << 8) & 0xff00) | (buffer[6] & 0xff);
    int h = ((buffer[7] << 8) & 0xff00) | (buffer[8] & 0xff);
    
    tilemap_init(t, nlayers, w, h);
    
    //int majversion = buffer[2];
    int minor_version = buffer[3];
    switch (minor_version) {
      case 0:
        return tilemap_read_v0(t, f, path);
      case 1:
        return tilemap_read_v1(t, f, path);
      default:
        fprintf(stderr, "%s has unknown map version %d\n", path, minor_version);
        return 0;
    }
}

static void serialize_int16(int i, char* buffer, size_t offset) {
  buffer[offset] = (i & 0xff00) >> 8;
  buffer[offset+1] = i & 0xff;
}

int tilemap_write_to_file(const tilemap_t * t, const char * path) {
    assert(t);
    
    FILE * f = fopen(path, "wb");
    if(!f)
        return 0;

    // Map file header (magic(2) + version(2) + nlayers(1) + w(2) + h(2) = 9 bytes)
    char buffer[32];
    // magic bytes
    buffer[0] = 0xac;
    buffer[1] = 0xc0;
    
    // version info
    buffer[2] = 0;
    buffer[3] = TILEMAP_FILE_FORMAT_LATEST_VERSION;

    // number of layers
    buffer[4] = t->nlayers & 0xff;
    
    // width and height
    serialize_int16(t->w, buffer, 5);
    serialize_int16(t->h, buffer, 7);

    if(fwrite(buffer, 9, 1, f) != 1) {
        goto tilemap_write_fail;
    }

    if (TILEMAP_FILE_FORMAT_LATEST_VERSION == 0) {
      fprintf(stderr, "version 0\n");
      // Write each layer
      size_t layer_bytes_size = t->w * t->h * sizeof(tile_t);
      for(size_t i = 0; i < t->nlayers; i++) {
          if(t->tiles[i]) {
              if(fwrite(t->tiles[i], layer_bytes_size, 1, f) != 1)
                  goto tilemap_write_fail;
          } else {
              goto tilemap_write_fail;
          }
      }
    } else if (TILEMAP_FILE_FORMAT_LATEST_VERSION == 1) {
      fprintf(stderr, "version 1\n");
      if (fwrite(t->should_store_sparse_layer, sizeof(int), t->nlayers, f) != t->nlayers)
        goto tilemap_write_fail;
      
      fprintf(stderr, "wrote sparse\n");

      for (size_t i = 0; i < t->nlayers; i++) {
        if (t->should_store_sparse_layer[i]) {
          fprintf(stderr, "last non-empty: %u\n", t->last_non_empty_tile[i]);
          // Write last non-empty position
          
          fprintf(stderr, "offset: %lu\n", ftell(f));
          if (!write_pos(f, t->last_non_empty_tile[i]))
            goto tilemap_write_fail;

          for (int y = 0; y < t->h; y++) {
            for (int x = 0; x < t->w; x++) {
              if (!tilemap_empty(t, i, x, y)) {
                fprintf(stderr, "write %zu, %d, %d\n", i, x, y);
                // Store as offset:tile
                if (!write_pos(f, y * t->w + x))
                  goto tilemap_write_fail;

                tile_t* tile = tilemap_get_tile_address(t, i, x, y);
                if(fwrite(tile, sizeof(tile_t), 1, f) != 1)
                  goto tilemap_write_fail;
              }
            }
          }
        } else {
          if(t->tiles[i]) {
              if(fwrite(t->tiles[i], t->w * t->h * sizeof(tile_t), 1, f) != 1)
                  goto tilemap_write_fail;
          } else {
              goto tilemap_write_fail;
          }
        }
      }
    }

    // Success
    fclose(f);
    return 1;

tilemap_write_fail:
    fclose(f);
    fprintf(stderr, "write failed\n");
    return 0;
}

void tilemap_set_sparse_layer(tilemap_t* t, int layer, int sparse) {
  assert(layer >= 0 && layer < t->nlayers);
  t->should_store_sparse_layer[layer] = sparse;
}

int tilemap_get_tile_animation_info(const tilemap_t* t, size_t layer, int x, int y, int* period, int* count) {
    assert(t);
    tile_t* tile = tilemap_get_tile_address(t, layer, x, y);
    if(!tile)
        return 0;

    if(period)
        *period = TILE_ANIM_PERIOD(tile);

    if(count)
        *count = TILE_ANIM_COUNT(tile);

    return 1;
};


int tilemap_set_tile_animation_info(tilemap_t* t, size_t layer, int x, int y, int period, int count) {
    assert(t);
    tile_t* tile = tilemap_get_tile_address(t, layer, x, y);
    if(!tile)
        return 0;

    tilemap_set_last_non_empty_tile(t, layer, x, y);

    if(period != -1) {
        // set period (take log2 by right-shifting)
        int log_period = 0;
        while(period ^ 0x1) {
            period >>= 1;
            log_period++;
        }
        tile->flags &= ~TILEMAP_ANIM_PERIOD_MASK;
        tile->flags |= (log_period & 0x3) << 2;
    }

    if(count != -1) {
        // set count
        int log_count = 0;
        while(count ^ 0x1) {
            count >>= 1;
            log_count++;
        }
        tile->flags &= ~TILEMAP_ANIM_COUNT_MASK;
        tile->flags |= (log_count & 0x3);
    }

    return 1;
};

