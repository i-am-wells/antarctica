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


tilemap_t * tilemap_create(size_t nlayers, size_t w, size_t h) {
    // Try to allocate a tilemap_t
    tilemap_t * t = (tilemap_t*)malloc(sizeof(tilemap_t));
    if(!t)
        return NULL;

    // Initialize
    if(!tilemap_init(t, w, h, nlayers)) {
        free(t);
        return NULL;
    }

    return t;
}


void tilemap_destroy(tilemap_t * t) {
    // Deinitialize and free
    tilemap_deinit(t);
    free(t);
}


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

        vec_deinit(&(t->objectvec));

        if(t->prerender) {
            for(size_t i = 0; i < t->nlayers; i++) {
                if(t->prerender[i])
                    SDL_DestroyTexture(t->prerender[i]);
            }
            free(t->prerender);
        }
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
                tilemap_destroy(t);
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

    t->prerender = (SDL_Texture**)calloc(nlayers, sizeof(SDL_Texture*));
    if(!t->prerender) {
        fprintf(stderr, "failed to allocate memory for map prerender\n");
    }

    t->updateParity = 0;

    return 1;
}


int tilemap_prerender_layer(tilemap_t* t, size_t layer, const image_t* image) {
    assert(t);
    assert(image);
    assert(layer < t->nlayers);

    int pixW = t->w * image->tw;
    int pixH = t->h * image->th;

    // Render to one enormous texture! Renderer must support texture as rendering target.
    Uint32 pixelformat;
    if(SDL_QueryTexture(image->texture, &pixelformat, NULL, NULL, NULL) == -1)
        return 0;

    SDL_Texture* tex = SDL_CreateTexture(
            image->renderer, 
            pixelformat, 
            SDL_TEXTUREACCESS_TARGET,
            pixW,
            pixH
        );
    if(!tex) {
        fprintf(stderr, "failed to prerender map layer %zu: %s\n", layer, SDL_GetError());
        return 0;
    }

    if(t->prerender[layer]) 
        SDL_DestroyTexture(t->prerender[layer]);
    t->prerender[layer] = NULL;

    // Target the prerender texture
    SDL_SetRenderTarget(image->renderer, tex);

    // Draw tiles
    tilemap_draw_layer(t, image, layer, 0, 0, pixW, pixH, 0);

    // Target the screen again
    SDL_SetRenderTarget(image->renderer, NULL);
    
    
    t->prerender[layer] = tex;
    return 1; // success
}


tile_t * tilemap_get_tile_address(const tilemap_t * t, size_t layer, size_t x, size_t y) {
    assert(t);
    if((layer < t->nlayers)
            && (x < t->w)
            && (y < t->h)) {
        return t->tiles[layer] + y * t->w + x;
    }

    // Return NULL if (layer, x, y) isn't on the map.
    return NULL;
}


void tilemap_set_tile(tilemap_t* t, size_t layer, size_t x, size_t y, int tilex, int tiley) {
    assert(t);

    // Set the image to be used for this map square
    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        tileptr->tilex = tilex & 0xff;
        tileptr->tiley = tiley & 0xff;
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


void tilemap_draw_layer(const tilemap_t* t, const image_t* i, int l, int px, int py, int pw, int ph, int counter) {
    // check for prerender
    if(t->prerender && t->prerender[l]) {
        SDL_Rect src, dst;
        src.x = px;
        src.y = py;
        src.w = pw;
        src.h = ph;
        dst.x = 0;
        dst.y = 0;
        dst.w = pw;
        dst.h = ph;
        SDL_RenderCopy(i->renderer, t->prerender[l], &src, &dst);
        return;
    }

    // Get the starting position and dimensions for drawing in map square coordinates
    int startx = (px / i->tw);
    int starty = (py / i->th);
    int nx = (pw / i->tw) + 2;
    int ny = (ph / i->th) + 2;

    // Allow for drawing tiles offset from map square boundaries
    int offx = px % i->tw;
    int offy = py % i->th;

    // get tile tile array for the layer we're drawing
    tile_t* layer = t->tiles[l];

    // For each map square within our view, draw the corresponding tile
    for(int y = 0; y < ny; y++) {
        int drawy = starty + y; // map square y to draw

        // are we on the map vertically?
        if((drawy > -1) && (drawy < t->h)) {
            for(int x = 0; x < nx; x++) {
                int drawx = startx + x; // map square x to draw

                // are we on the map horizontally?
                if((drawx > -1) && (drawx < t->w)) {
                    // draw the tile at (layer, drawx, drawy)
                    tile_t* tile = layer + drawy * t->w + drawx;
                   
                    if((tile->tilex != 16) || (tile->tiley != 0)) {
                        // Animation
                        int tiley = tile->tiley + (counter / TILE_ANIM_PERIOD(tile)) % TILE_ANIM_COUNT(tile);

                        image_draw_tile(i, tile->tilex, tiley, x * i->tw - offx, y * i->th - offy);
                    }
                }
            } // loop x
        }
    } // loop y
}



void tilemap_draw_layer_flags(const tilemap_t* t, const image_t* i, int l, int px, int py, int pw, int ph) {
    // see tilemap_draw_layer
    int startx = (px / i->tw);
    int starty = (py / i->th);
    int nx = (pw / i->tw) + 2;
    int ny = (ph / i->th) + 2;

    int offx = px % i->tw;
    int offy = py % i->th;

    tile_t* layer = t->tiles[l];

    int thickness = 2;
    SDL_Rect dst;

    // save current drawing color
    Uint8 or, og, ob, oa;
    SDL_GetRenderDrawColor(i->renderer, &or, &og, &ob, &oa);

    for(int y = 0; y < ny; y++) {
        int drawy = starty + y;
        if((drawy > -1) && (drawy < t->h)) {
            for(int x = 0; x < nx; x++) {
                int drawx = startx + x;
                if((drawx > -1) && (drawx < t->w)) {
                    tile_t* tile = layer + drawy * t->w + drawx;
                    
                    int x0 = x * i->tw - offx;
                    int x1 = x0 + i->tw - thickness;
                    int y0 = y * i->th - offy;
                    int y1 = y0 + i->th - thickness;
                    
                    image_draw_tile(i, tile->tilex, tile->tiley, x * i->tw - offx, y * i->th - offy);

                    // draw map square borders in red to show directional bump flags
                    SDL_SetRenderDrawColor(i->renderer, 255, 0, 0, SDL_ALPHA_OPAQUE);
                    if(tile->flags & TILEMAP_BUMP_EAST_MASK) {
                        dst.x = x1;
                        dst.y = y0;
                        dst.w = thickness;
                        dst.h = i->th;
                        SDL_RenderFillRect(i->renderer, &dst);
                    }
                    if(tile->flags & TILEMAP_BUMP_NORTH_MASK) {
                        dst.x = x0;
                        dst.y = y0;
                        dst.w = i->tw;
                        dst.h = thickness;
                        SDL_RenderFillRect(i->renderer, &dst);
                    }
                    if(tile->flags & TILEMAP_BUMP_WEST_MASK) {
                        dst.x = x0;
                        dst.y = y0;
                        dst.w = thickness;
                        dst.h = i->th;
                        SDL_RenderFillRect(i->renderer, &dst);
                    }
                    if(tile->flags & TILEMAP_BUMP_SOUTH_MASK) {
                        dst.x = x0;
                        dst.y = y1;
                        dst.w = i->tw;
                        dst.h = thickness;
                        SDL_RenderFillRect(i->renderer, &dst);
                    }

                    if(tile->flags & (TILEMAP_BUMP_NORTHWEST_MASK | TILEMAP_BUMP_SOUTHEAST_MASK)) {
                        SDL_RenderDrawLine(i->renderer, x0, y0+i->th, x0+i->tw, y0);
                    }
                    if(tile->flags & (TILEMAP_BUMP_NORTHEAST_MASK | TILEMAP_BUMP_SOUTHWEST_MASK)) {
                        SDL_RenderDrawLine(i->renderer, x0, y0, x0+i->tw, y0+i->th);
                    }
                    
                    // draw a green rectangle in the center of map squares with
                    // the "action" flag set
                    SDL_SetRenderDrawColor(i->renderer, 0, 255, 0, SDL_ALPHA_OPAQUE);
                    if(tile->flags & TILEMAP_ACTION_MASK) {
                        dst.x = x0 + i->tw / 4;
                        dst.y = y0 + i->th / 4;
                        dst.w = i->tw / 2;
                        dst.h = i->th / 2;
                        SDL_RenderFillRect(i->renderer, &dst);
                    }
                }
            }
        }
    }

    // restore original drawing color
    SDL_SetRenderDrawColor(i->renderer, or, og, ob, oa);
}

#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

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

void tilemap_draw_layer_at_camera_object(const tilemap_t* t, const image_t* i, int layer, int pw, int ph, int counter) {
    int px = 0;
    int py = 0;
    tilemap_get_camera_location(t, pw, ph, &px, &py);

    tilemap_draw_layer(t, i, layer, px, py, pw, ph, counter);
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

    /* TODO remove
    // link into the update list
    o->next = t->head;
    t->head = o;
    */
}


void tilemap_remove_object(tilemap_t* t, object_t* o) {
    vec_remove(&(t->objectvec), o->index, 1);
    for(size_t i = o->index; i < t->objectvec.size; i++) {
        object_t* obj = OBJECT_AT(t->objectvec, i);
        obj->index = i;
    }

    /* TODO remove
    // unlink from update list
    if(t->head == o) {
        t->head = o->next;
    } else {
        object_t* prev = t->head;
        while(prev && (prev->next != o))
            prev = prev->next;

        if(prev)
            prev->next = o->next;
    }
    */
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

/*
void tilemap_update_objects_old(tilemap_t* t) {
    
    // TODO store tile size with map!!
    const int tw = 16;
    const int th = 16;

    // Run update callbacks
    for(object_t* object = t->head; object != NULL; object = object->next) {
        // === Run update callback ===
        t->object_update_callback(t->object_callback_data, object);
        if(object->toRemove) {
            tilemap_remove_object(t, object);
            object->toRemove = 0;
        }
    }
    
    for(object_t* o = t->head; o != NULL; o = o->next) {
        // === Update object position ===

        // check for wall bump
        // TODO use real tile size
        if(o->velx || o->vely) {
            // actual motion of object
            int velX = o->velx;
            int velY = o->vely;
 
            int bumpDir = check_wall_bump(t, o); 
           
            // in case of bump, adjust final position to contact with wall
            if(bumpDir & TILEMAP_BUMP_EAST_MASK)
                velX = 0 - ((o->x + o->boundX) % tw);

            if(bumpDir & TILEMAP_BUMP_NORTH_MASK) {
                velY = (0 - (o->y + o->boundY + o->boundH)) % th;
                
                //int ay1 = o->y + o->boundY + o->boundH + o->vely;
                //int npy = ay1 - (ay1 % th);
                //velY = npy - o->boundH - o->y - o->boundY;
            }

            if(bumpDir & TILEMAP_BUMP_WEST_MASK) {
                velX = (0 - (o->x + o->boundX + o->boundW)) % tw;
                
                //int ax1 = o->x + o->boundX + o->boundW + o->velx;
                //int npx = ax1 - (ax1 % tw);
                //velX = npx - o->boundW - o->x - o->boundX;
            }

            if(bumpDir & TILEMAP_BUMP_SOUTH_MASK)
                velY = 0 - ((o->y + o->boundY) % th);

            
            // Move object
            tilemap_move_object_relative(t, o, velX, velY);


            // Run wall bump callback
            if(bumpDir && t->bump_callback) {
                t->bump_callback(t->object_callback_data, o, bumpDir);
                if(o->toRemove) {
                    tilemap_remove_object(t, o);
                    o->toRemove = 0;
                }
            }
        }
    } // for

    // === Run object-object collision callbacks === 
    // Check for collisions between objects
    
    // TODO Warning: This loop calls user-supplied Lua code that may arbitrarily
    // modify t->objectvec. It does not attempt to keep track of which objects
    // have had a collision callback run for this timestep, nor does it keep
    // track of insertions/deletions/permutations to t-objectvec. As a result
    // some objects may be skipped or visited twice. Fixes upcoming.

    // Bounding box collision: must overlap in both x and y
    //fprintf(stderr, "\n");
    for(size_t i = 0; i < t->objectvec.size; i++) {
        object_t* objectA = OBJECT_AT(t->objectvec, i);
        //fprintf(stderr,"%d\n", objectA->y);

        for(size_t j = i + 1; j < t->objectvec.size; j++) {
            object_t* objectB = OBJECT_AT(t->objectvec, j);

            // Check if they overlap in y direction
            if((objectA->y + objectA->boundY + objectA->boundH) > (objectB->y + objectB->boundY)) {

                // Check x
                int ax0 = objectA->x + objectA->boundX;
                int ax1 = ax0 + objectA->boundW;
                int bx0 = objectB->x + objectB->boundX;
                int bx1 = bx0 + objectB->boundW;
                if(((ax0 < bx0) && (ax1 > bx0)) || ((ax0 >= bx0) && (ax0 < bx1))) {
                    // there is overlap
                    t->collision_callback(t->object_callback_data, objectA, objectB);

                    // if both solid, move away
                    if(objectA->mass > objectB->mass) {
                        tilemap_move_object_relative(t, objectB, -objectB->velx, -objectB->vely);
                    } else if(objectA->mass < objectB->mass) {
                        tilemap_move_object_relative(t, objectA, -objectA->velx, -objectA->vely);
                    } else {
                        tilemap_move_object_relative(t, objectA, -objectA->velx, -objectA->vely);
                        tilemap_move_object_relative(t, objectB, -objectB->velx, -objectB->vely);
                    }
                }
            } else {
                // no Y overlap: move to the next objectA
                break;
            }
        }
    }

    // remove objects marked for removal
    for(object_t* object = t->head; object != NULL; object = object->next) {
        if(object->toRemove) {
            tilemap_remove_object(t, object);
            object->toRemove = 0;
        }
    }
}
*/


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
                /*
                double totalMass = objectA->mass + objectB->mass;
                double totalInitX = objectA->mass * objectA->nextVx + objectB->mass * objectB->nextVx;
                double totalInitY = objectA->mass * objectA->nextVy + objectB->mass * objectB->nextVy;
                
                objectA->nextVx = (Cr * objectB->mass * (objectB->nextVx - objectA->nextVx) + totalInitX) / totalMass;
                objectA->nextVy = (Cr * objectB->mass * (objectB->nextVy - objectA->nextVy) + totalInitY) / totalMass;
                objectB->nextVx = (Cr * objectA->mass * (objectA->nextVx - objectB->nextVx) + totalInitX) / totalMass;
                objectB->nextVy = (Cr * objectA->mass * (objectA->nextVy - objectB->nextVy) + totalInitY) / totalMass;

                fprintf(stderr, "%f %f %f %f\n", objectA->nextVx, objectA->nextVy, objectB->nextVx, objectB->nextVy);
                */
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

static void tilemap_draw_layer_rows(const tilemap_t* t, const image_t* img, int layer, int px, int py, int pw, int ph, int y0, int y1, int counter) {
    // draw a few rows
    for(int yy = y0; yy <= y1; yy++) {
        int dy = yy * img->th - py;
        for(int xx = px / img->tw; xx <= (px + pw) / img->tw; xx++) {
            int dx = xx * img->tw - px;
            tile_t* tile = tilemap_get_tile_address(t, layer, xx, yy);
            
            if(tile) {
                if(!((tile->tilex == 16) && (tile->tiley == 0))) {
                    int tiley = tile->tiley + (counter / TILE_ANIM_PERIOD(tile)) % TILE_ANIM_COUNT(tile);
                    image_draw_tile(img, tile->tilex, tiley, dx, dy);
                
                }
            }
        }

    }
}

// draw objects from one map layer
void tilemap_draw_objects_interleaved(const tilemap_t* t, const image_t* img, int layer, int px, int py, int pw, int ph, int counter) {

    // Find range of objects to draw
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
            tilemap_draw_layer_rows(t, img, layer, px, py, pw, ph, lastMapY, bottomMapY, counter);

            lastMapY = bottomMapY;
        }

        if((obj->layer == layer)
                && (obj->x + obj->offX < px + pw)
                && (obj->y + obj->offY < py + ph)
                && (obj->x + obj->offX + obj->tw >= px)
                && (obj->y + obj->offY + obj->th >= py)) {
            object_draw(obj, px, py, counter);
            
            /*
            // TODO remove
            SDL_SetRenderDrawColor(img->renderer, 255, 0, 0, 255);
            SDL_Rect r;
            r.x = obj->x + obj->boundX - px;
            r.y = obj->y + obj->boundY - py;
            r.w = obj->boundW;
            r.h = obj->boundH;
            SDL_RenderDrawRect(img->renderer, &r);
            */
        }
    }

    // Draw remaining rows
    tilemap_draw_layer_rows(t, img, layer, px, py, pw, ph, lastMapY, (py + ph) / img->th, counter);
}
    

void tilemap_draw_objects_at_camera_object(const tilemap_t* t, const image_t* img, int layer, int pw, int ph, int counter) {
    int px = 0;
    int py = 0;
    tilemap_get_camera_location(t, pw, ph, &px, &py);

    tilemap_draw_objects_interleaved(t, img, layer, px, py, pw, ph, counter);
}


/*
int tilemap_insert_object(tilemap_t* t, object_t* o) {
    // Find where the object belongs
    size_t idx;
    //if(t->objectvec_orienation == 0) {
        //idx = tilemap_binary_search_objects(t, o->x, 0, t->objectvec.size - 1);
    //} else if(t->objectvec_orientation == 1) {
        idx = tilemap_binary_search_objects(t, o->y, 0, t->objectvec.size - 1);
    //}

    vec_insert(&(t->objectvec), idx, o);
    return 1;
}
*/


/*
int tilemap_remove_object(tilemap_t* t, object_t* o) {
    // Find the object
    size_t idx;
    if(t->objectvec_orienation == 0) {
        idx = tilemap_binary_search_objects(t, o->x, 0, t->objectvec.size - 1);
    } else if(t->objectvec_orientation == 1) {
        idx = tilemap_binary_search_objects(t, o->y, 0, t->objectvec.size - 1);
    }

    vec_insert(&(t->objectvec), idx, 1);
    return 1;
}
*/


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


int tilemap_read_from_file(tilemap_t * t, const char * path) {
    assert(t);

    // Start with a fresh tilemap_t
    tilemap_init(t, 0, 0, 0);
    
    FILE * f = fopen(path, "rb");
    if(!f)
        return 0;

    // Read map file header (magic(2) + version(2) + nlayers(1) + w(2) + h(2) = 9 bytes)
    char buffer[32];
    int nread = fread(buffer, 9, 1, f);
    if(nread != 1) {
        fclose(f);
        return 0;
    }

    if(!((buffer[0] == (char)0xac) && (buffer[1] == (char)0xc0))) {
        fclose(f);
        return 0;
    }

    //int majversion = buffer[2];
    //int minversion = buffer[3];

    // TODO check version?
    //
    t->nlayers = 0;
    t->w = 0;
    t->h = 0;

    // Get dimensions
    t->nlayers = buffer[4];
    t->w = ((buffer[5] << 8) & 0xff00) | (buffer[6] & 0xff);
    t->h = ((buffer[7] << 8) & 0xff00) | (buffer[8] & 0xff);
    
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
    buffer[3] = 0;

    // number of layers
    buffer[4] = t->nlayers & 0xff;
    
    // width
    buffer[5] = (t->w & 0xff00) >> 8;
    buffer[6] = t->w & 0xff;

    // height
    buffer[7] = (t->h & 0xff00) >> 8;
    buffer[8] = t->h & 0xff;

    if(fwrite(buffer, 9, 1, f) != 1) {
        goto tilemap_write_fail;
    }

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

    // Success
    fclose(f);
    return 1;

tilemap_write_fail:
    fclose(f);
    return 0;
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




