
#include "vec.h"

#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))


typedef struct rect_t {
    int x, y, w, h;
} rect_t;


typedef struct object_t {
    // TODO others
    //
    image_t* image;

    rect_t bound;
    int* collision_mask;
}


int object_init(object_t* o, image_t* image, int perpixelcollision, SDL_Surface* surf) {
    o->image = image;

    o->bound.x = 0;
    o->bound.y = 0;
    o->bound.w = image->tw;
    o->bound.h = image->th;

    if(perpixelcollision && surf) {

        int* mask = (int*)malloc((o->bound.h + 1) * ((o->bound.w / (8 * sizeof(int))) + 1) * sizeof(int));
        if(!mask)
            return 0;

        // Make mask based on image
        SDL_LockSurface(surf);

        SDL_PixelFormat* fmt = surf->format;

        int nbits = 8 * sizeof(int);
        int w = o->bound.w;
        int h = o->bound.h;
        for(int y = 0; y < h; y++) {
            for(int x = 0; x < w; x++) {
                int pixel = (int)(surf->pixels[fmt->BytesPerPixel * (y * w + x)]);
                if(pixel & fmt->Amask) {
                    int bits = 0xc0000000 >> (x % nbits);
                    mask[y * (w / nbits + 1) + (x / nbits)] |= bits;
                    mask[(y + 1) * (w / nbits + 1) + (x / nbits)] |= bits;
                }
            }
        }

        SDL_UnlockSurface(surf);


    } else {
        o->collision_mask = NULL;
    }

    return 1;
}


void object_deinit(object_t* o) {
    if(o) {
        if(o->collision_mask)
            free(o->collision_mask);
    }
}


object_t* object_create(image_t* image, int perpixelcollision, SDL_Surface* surf) {
    object_t* o = (object_t*)calloc(1, sizeof(object_t));
    if(!o)
        return NULL;

    if(!object_init(o, image, perpixelcollision, surf)) {
        object_deinit(o);
        return NULL;
    }
 
    return o;
}


void object_destroy(object_t* o) {
    object_deinit(o);
    free(o);
}


int is_pixel_overlap(const object_t* object0, const object_t* object1) {
    int* mask0 = object0->collision_mask;
    int* mask1 = object1->collision_mask;
    rect_t* rect0 = &(object0->bound);
    rect_t* rect1 = &(object1->bound);
    
    if(!rect0 || !rect1) {
        // If an object doesn't have a bounding rect, it can't collide with
        // anything
        return 0;
    }
    
    int xdiff = rect1->x - rect0->x;
    int ydiff = rect1->y - rect0->y;

    // Check first to see if bounding boxes overlap
    if((xdiff >= rect0->w)
            || ((0 - xdiff) >= rect1->w)
            || (ydiff >= rect0->h)
            || ((0 - ydiff) >= rect1->h)) {
        return 0;
    }

    if(!mask0 || !mask1) {
        // If either one is missing the per-pixel collision detection mask,
        // fall back to bounding box collision
        return 1;
    }
    
    // Masks are stored as rows of bits where a pixel is represented by one
    // bit. Here we make sure that rect0 is the leftmost box to simplify the 
    // bitwise comparison below.
    if(xdiff < 0) {
        xdiff = 0 - xdiff;
        rect_t* tmp = rect1;
        rect1 = rect0;
        rect0 = tmp;
    }

    // We will most likely need to shift each word in the left mask
    int nbits = 8 * sizeof(int);
    int xshift = xdiff % nbits;

    // The lengths of the rows of ints
    int col0 = rect0->w / nbits + 1;
    int col1 = rect1->w / nbits + 1;
    
    // Iterate over the overlapping region of the masks
    int ystart = MAX(rect0->y, rect1->y);
    int yend = MIN(rect0->y + rect0->h, rect1->y + rect1->h);

    int xstart = MAX(rect0->x, rect1->x);
    int xend = MIN(rect0->x + rect0->w, rect1->x + rect1->w);
    
    
    int iy0, iy1, ix0, ix1;
    for(int y = ystart; y < yend; y++) {
        // mask-local y
        iy0 = y - rect0->y;
        iy1 = y - rect1->y;

        for(int x = xstart; x < xend; x += nbits) {
            // mask-local x
            ix0 = x - rect0->x;
            ix1 = x - rect1->x;

            // the bits from mask1
            char byte1 = mask1[iy1 * col1 + ix1 / nbits];

            int idx0 = iy0 * col0 + ix0 / nbits;

            // first shift and compare the "left" word from mask0
            char byte0a = mask0[idx0];
            if(byte1 & (byte0 << xshift))
                return 1;

            // if we aren't at the end of the row, shift and compare the "right"
            // word
            if((x + nbits) < rect0->w) {
                char byte0b = mask0[idx0 + 1];
                if(byte1 & (byte0b >> (nbits - xshift)))
                    return 1;
            }
        }
    }

    // If the loop finished, no overlapping pixels were found
    return 0;
}


// Return the index of the next highest (0 for x, 1 for y)
size_t binary_search_for_object(const vec_t* v, int q, int which, int pref) {
    size_t first = 0;
    size_t end = v->size;

    size_t mid;
    while(first != end) {
        mid = first + (end - first) / 2;
        
        object_t* o = (object_t*)vec_get(v, mid);

        int a;
        if(which == 0) {
            a = o->x;
        } else {
            a = o->y;
        }

        if(q == a) {
            if(pref < 0) {
                end = mid + 1;
            } else if(prev > 0) {
                first = mid;
            } else {
                first = mid;
                end = mid;
            }
        } else if(q > a) {
            first = mid + 1;
        } else {
            end = mid + 1;
        }
    }

    return first;
}


void run_collision_callback(const vec_t* xv, const rect_t* view, int which) {
    if(!xv->size)
        return;
    
    size_t x0 = 0;
    size_t x1 = xv->size - 1;
    
    if(which & 1) {
        // Get range sorted by x
        x0 = binary_search_for_object(xv, view->x, 0, -1);
        x1 = binary_search_for_object(xv, view->x + view->w, 0, 1);
    }
    
    /*
    size_t y0 = 0;
    size_t y1 = yv->size - 1;
    
    if(which & 2) {
        // Get range sorted by x
        y0 = binary_search_for_object(yv, view->y, 0, -1);
        y1 = binary_search_for_object(yv, view->y + view->h, 0, 1);
    }
    */

    for(size_t ix = x0; ix < x1; ix++) {
        object_t* o = (object_t*)vec_get(xv, ix);
        object_t* next = (object_t*)vec_get(xv, ix + 1);

        if(is_pixel_overlap(o, next)) {
            // TODO run collision callbacks
        }
    }
}


