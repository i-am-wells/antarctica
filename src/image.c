#include <assert.h>
#include <stdlib.h>

#include <SDL.h>
#include <SDL_image.h>

#include "engine.h"
#include "image.h"


int image_load(image_t* i, engine_t* e, const char* filename) {
    SDL_Surface* surf = IMG_Load(filename);
    if(!surf)
        return 0;

    SDL_Texture* tex = SDL_CreateTextureFromSurface(e->renderer, surf);
    if(!tex) {
        SDL_FreeSurface(surf);
        return 0;
    }

    i->texture = tex;
    i->texturewidth = surf->w;
    i->textureheight = surf->h;
    i->renderer = e->renderer;

    SDL_FreeSurface(surf);
    return 1;
}


int image_init(image_t* i, engine_t* e, const char* filename, int tw, int th) {
    assert(i);
    
    i->tw = tw;
    i->th = th;

    return image_load(i, e, filename);
}


void image_deinit(image_t* i) {
    if(i) {
        if(i->texture)
            SDL_DestroyTexture(i->texture);
    }
}


image_t* image_create(engine_t* e, const char* filename, int tw, int th) {
    image_t* i = (image_t*)calloc(1, sizeof(image_t));
    if(!i)
        return NULL;

    if(!image_init(i, e, filename, tw, th)) {
        free(i);
        return NULL;
    }

    return i;
}


void image_destroy(image_t* i) {
    if(i) {
        image_deinit(i);
        free(i);
    }
}


void image_draw(const image_t* i, int sx, int sy, int sw, int sh, int dx, int dy, int dw, int dh) {
    SDL_Rect src, dest;
    src.x = sx;
    src.y = sy;
    src.w = sw;
    src.h = sh;
    dest.x = dx;
    dest.y = dy;
    dest.w = dw;
    dest.h = dh;
    SDL_RenderCopy(i->renderer, i->texture, &src, &dest);
}


void image_draw_tile(const image_t* i, int tx, int ty, int dx, int dy) {
    SDL_Rect src, dest;
    dest.x = dx;
    dest.y = dy;
    dest.w = i->tw;
    dest.h = i->th;

    src.x = i->tw * tx;
    src.y = i->th * ty;
    src.w = i->tw;
    src.h = i->th;

    SDL_RenderCopy(i->renderer, i->texture, &src, &dest);
}

void image_draw_whole(const image_t* i, int dx, int dy) {
    SDL_Rect dest;
    dest.x = dx;
    dest.y = dy;
    dest.w = i->texturewidth;
    dest.h = i->textureheight;
    SDL_RenderCopy(i->renderer, i->texture, NULL, &dest);
}


void image_get_size(const image_t* i, int* w, int* h) {
    SDL_QueryTexture(i->texture, NULL, NULL, w, h);
}

