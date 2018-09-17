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

    if(i->scaled_texture)
        SDL_DestroyTexture(i->scaled_texture);

    i->scaled_texture = i->texture;

    SDL_FreeSurface(surf);
    return 1;
}


int image_init(image_t* i, engine_t* e, const char* filename, int tw, int th) {
    assert(i);

    i->tw = tw;
    i->th = th;
    i->orig_tw = tw;
    i->orig_th = th;
    i->scaled_texture = NULL;

    i->scale = 1.0;

    return image_load(i, e, filename);
}


void image_deinit(image_t* i) {
    if(i) {
        if(i->texture == i->scaled_texture) {
            if(i->texture)
                SDL_DestroyTexture(i->texture);
        } else {
            if(i->texture)
                SDL_DestroyTexture(i->texture);

            if(i->scaled_texture)
                SDL_DestroyTexture(i->scaled_texture);
        }
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
    SDL_RenderCopy(i->renderer, i->scaled_texture, &src, &dest);
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

    SDL_RenderCopy(i->renderer, i->scaled_texture, &src, &dest);
}

void image_draw_whole(const image_t* i, int dx, int dy) {
    SDL_Rect dest;
    dest.x = dx;
    dest.y = dy;
    dest.w = i->texturewidth;
    dest.h = i->textureheight;
    SDL_RenderCopy(i->renderer, i->scaled_texture, NULL, &dest);
}


void image_draw_ascii_char(const image_t* i, char c, int dx, int dy) {
    image_draw_tile(i, c % 16, c / 16, dx, dy);
}


void image_draw_text_line(const image_t* i, const char* text, int dx, int dy) {
    while(*text) {
        image_draw_ascii_char(i, *text, dx, dy);
        dx += i->tw;
        text++;
    }
}


void image_draw_text_word(const image_t* i, const char* text, size_t n, int dx, int dy) {
    for(size_t j = 0; j < n; j++) {
        image_draw_ascii_char(i, text[j], j * i->tw + dx, dy);
    }
}


void image_draw_text(const image_t* i, const char* text, int dx, int dy, int wrapw) {
    int linec = wrapw / i->tw;

    int firstword = 1;
    int drawx = dx;
    int linepos = 0;

    // for each line:
    do { 
        // seek to end of word
        char* wordend = (char*)text;
        while(*wordend && (*wordend != ' '))
            wordend++;

        size_t wordlen = wordend - text;

        if(wordlen + linepos > linec) {
            if(firstword) {
                // draw word, advance line
                image_draw_text_word(i, text, wordlen, drawx, dy);
                drawx = dx;
                dy += i->th;
                linepos = 0;
            } else {
                // advance line, draw word
                drawx = dx;
                dy += i->th;
                linepos = 0;
                image_draw_text_word(i, text, wordlen, drawx, dy);
                firstword = 0;
                drawx += i->tw * (wordlen + 1);
            }
        } else {
            // TODO draw word, move forward
            image_draw_text_word(i, text, wordlen, drawx, dy);
            linepos += wordlen;
            drawx += i->tw * wordlen;
            if(firstword)
                firstword = 0;

            linepos++;
            drawx += i->tw;
        }

        if(*wordend) {
            text = wordend + 1;
        } else {
            text = wordend;
        }
    } while(*text);
}


void image_get_size(const image_t* i, int* w, int* h) {
    SDL_QueryTexture(i->scaled_texture, NULL, NULL, w, h);
}

int image_scale(image_t* i, double scale) {
    assert(i);
    assert(scale);

    if(i->texture != i->scaled_texture) {
        if(i->scaled_texture)
            SDL_DestroyTexture(i->scaled_texture);
    }
    
    Uint32 pixelformat;
    int origW, origH;
    if(SDL_QueryTexture(i->texture, &pixelformat, NULL, &origW, &origH) == -1)
        return 0;

    SDL_Texture* tex = SDL_CreateTexture(
            i->renderer, 
            pixelformat, 
            SDL_TEXTUREACCESS_TARGET,
            origW * scale,
            origH * scale
        );
    if(!tex) {
        fprintf(stderr, "failed to scale image: %s\n", SDL_GetError());
        return 0;
    }

    SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);
    

    i->texturewidth = origW * scale;
    i->textureheight = origH * scale;
    i->tw = i->orig_tw * scale;
    i->th = i->orig_th * scale;

    // Target new texture
    SDL_SetRenderTarget(i->renderer, tex);

    // Clear the new texture (transparent black)
    Uint8 origR, origG, origB, origA;
    SDL_GetRenderDrawColor(i->renderer, &origR, &origG, &origB, &origA);
    SDL_SetRenderDrawColor(i->renderer, 0, 0, 0, 0);
    SDL_RenderClear(i->renderer);
    SDL_SetRenderDrawColor(i->renderer, origR, origG, origB, origA);

    // Copy/scale texture
    SDL_RenderCopy(i->renderer, i->texture, NULL, NULL);
    //SDL_RenderPresent(i->renderer);

    // Target the screen
    SDL_SetRenderTarget(i->renderer, NULL);

    i->scaled_texture = tex;

    return 1;
}
