#include <assert.h>
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


int tilemap_get_flags(tilemap_t* t, size_t layer, size_t x, size_t y) {
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
        tileptr->flags |= (mask & 0xffff);
    }
}


void tilemap_clear_flags(tilemap_t* t, size_t layer, size_t x, size_t y, int mask) {
    assert(t);

    // Set the image to be used for this map square
    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        tileptr->flags &= ~(mask & 0xffff);
    }
}


void tilemap_overwrite_flags(tilemap_t* t, size_t layer, size_t x, size_t y, int mask) {
    assert(t);

    // Set the image to be used for this map square
    tile_t* tileptr = tilemap_get_tile_address(t, layer, x, y);
    if(tileptr) {
        tileptr->flags = (mask & 0xffff);
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
    if(q > lastval)
        return last;

    while((last - first) > 1) {
        size_t mid = (first + last) / 2;

        int midval = OBJECT_AT(t->objectvec, mid)->y;

        if(midval > q) {
            last = mid;
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
    for(size_t i = 0; i < t->objectvec.size; i++)
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

    // link into the update list
    o->next = t->head;
    t->head = o;
}


void tilemap_remove_object(tilemap_t* t, object_t* o) {
    vec_remove(&(t->objectvec), o->index, 1);
    for(size_t i = 0; i < t->objectvec.size; i++) {
        object_t* obj = OBJECT_AT(t->objectvec, i);
        obj->index = i;
    }

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
}


void tilemap_move_object_absolute(tilemap_t* t, object_t* o, int x, int y) {
    tilemap_remove_object(t, o);
    o->x = x;
    o->y = y;
    tilemap_add_object(t, o);
}


void tilemap_update_objects(tilemap_t* t) {
    
    // Run update callbacks
    for(object_t* object = t->head; object != NULL; object = object->next) {
        // === Run update callback ===
        t->object_update_callback(t->object_callback_data, object);
        if(object->toRemove) {
            tilemap_remove_object(t, object);
            object->toRemove = 0;
        }
    }
    
    // TODO update sprites as well? (edit 1/19: nvm, should happen in Lua) 
    //for(size_t i = 0; i < t->objectvec.size; i++) {
    for(object_t* object = t->head; object != NULL; ) {
        //object_t* object = OBJECT_AT(t->objectvec, i);

        // === Update object position ===

        // actual motion of object
        int velx = object->velx;
        int vely = object->vely;

        int mapx, mapy;
        object_get_map_location(object, &mapx, &mapy);
        //int mapx2 = (object->x + object->tw) / object->image->tw;
        //int mapy2 = (object->y + object->th) / object->image->th;
        int mapx2 = (object->x + object->boundX + object->boundW) / object->image->tw;
        int mapy2 = (object->y + object->boundY + object->boundH) / object->image->th;
        // TODO should not assume that object tw is same as map tw       


        // TODO begin new wall bump code
        


        // TODO end new bump code

        // === Run wall collision callbacks ===
        // Check if new position would overlap any blocked squares (x direction)
        int newx = object->x + velx;
        int oldvelx = velx;
        int bumpdir = 0;
        if(velx > 0) {
            int newmapx = (newx + object->tw) / object->image->tw;
            if(tilemap_get_flags(t, object->layer, newmapx, mapy) & TILEMAP_BUMP_WEST_MASK)
                velx = 0;
            if(tilemap_get_flags(t, object->layer, newmapx, mapy2) & TILEMAP_BUMP_WEST_MASK)
                velx = 0;

            if(velx != oldvelx)
                bumpdir |= TILEMAP_BUMP_EAST_MASK;

        } else if(velx < 0) {
            int newmapx = newx / object->image->tw;
            if(tilemap_get_flags(t, object->layer, newmapx, mapy) & TILEMAP_BUMP_EAST_MASK)
                velx = 0;
            if(tilemap_get_flags(t, object->layer, newmapx, mapy2) & TILEMAP_BUMP_EAST_MASK)
                velx = 0;
            
            if(velx != oldvelx)
                bumpdir |= TILEMAP_BUMP_WEST_MASK;
        }
        
        // Same thing in the y direction
        int newy = object->y + vely;
        int oldvely = vely;
        if(vely > 0) {
            int newmapy = (newy + object->th) / object->image->th;
            if(tilemap_get_flags(t, object->layer, mapx, newmapy) & TILEMAP_BUMP_NORTH_MASK)
                vely = 0;
            if(tilemap_get_flags(t, object->layer, mapx2, newmapy) & TILEMAP_BUMP_NORTH_MASK)
                vely = 0;
            
            if(vely != oldvely)
                bumpdir |= TILEMAP_BUMP_SOUTH_MASK;
        } else if(vely < 0) {
            int newmapy = newy / object->image->th;
            if(tilemap_get_flags(t, object->layer, mapx, newmapy) & TILEMAP_BUMP_SOUTH_MASK)
                vely = 0;
            if(tilemap_get_flags(t, object->layer, mapx2, newmapy) & TILEMAP_BUMP_SOUTH_MASK)
                vely = 0;
            if(vely != oldvely)
                bumpdir |= TILEMAP_BUMP_NORTH_MASK;
        }

        // Move object
        tilemap_move_object_relative(t, object, velx, vely);
        
        // Run wall bump callback
        if(bumpdir && t->bump_callback) {
            t->bump_callback(t->object_callback_data, object, bumpdir);
            if(object->toRemove) {
                tilemap_remove_object(t, object);
                object->toRemove = 0;
            }
        }

        // Next
        object = object->next;
    }

    // === Run object-object collision callbacks === 
    // Check for collisions between objects
    
    // TODO Warning: This loop calls user-supplied Lua code that may arbitrarily
    // modify t->objectvec. It does not attempt to keep track of which objects
    // have had a collision callback run for this timestep, nor does it keep
    // track of insertions/deletions/permutations to t-objectvec. As a result
    // some objects may be skipped or visited twice. Fixes upcoming.

    // Bounding box collision: must overlap in both x and y
    for(size_t i = 0; i < t->objectvec.size; i++) {
        object_t* objectA = OBJECT_AT(t->objectvec, i);
        
        for(size_t j = i + 1; j < t->objectvec.size; j++) {
            object_t* objectB = OBJECT_AT(t->objectvec, j);

            // Check if they overlap in y direction
            if((objectA->y + objectA->boundY + objectA->boundH) >= (objectB->y + objectB->boundY)) {
                
                // Check x
                int ax0 = objectA->x + objectA->boundX;
                int ax1 = ax0 + objectA->boundW;
                int bx0 = objectB->x + objectB->boundX;
                int bx1 = bx0 + objectB->boundW;
                if(((ax0 < bx0) && (ax1 >= bx1)) || ((ax0 >= bx0) && (ax0 <= bx1))) {
                    // there is overlap
                    t->collision_callback(t->object_callback_data, objectA, objectB);
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


void tilemap_set_camera_object(tilemap_t* t, object_t* o) {
    t->cameraobject = o;
}


// draw objects from one map layer
void tilemap_draw_objects(const tilemap_t* t, int layer, int px, int py, int pw, int ph, int counter) {

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
    

void tilemap_draw_objects_at_camera_object(const tilemap_t* t, int layer, int pw, int ph, int counter) {
    int px = 0;
    int py = 0;
    tilemap_get_camera_location(t, pw, ph, &px, &py);

    tilemap_draw_objects(t, layer, px, py, pw, ph, counter);
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




