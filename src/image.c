#include "image.h"

#include <SDL.h>
#include <SDL_image.h>
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>

#include "engine.h"

int image_load(image_t* i,
               engine_t* e,
               const char* filename,
               int keep_surface) {
  i->surface = IMG_Load(filename);
  if (!i->surface)
    return 0;

  SDL_Texture* tex = SDL_CreateTextureFromSurface(e->renderer, i->surface);
  if (!tex) {
    return 0;
  }

  i->texture = tex;
  i->texturewidth = i->surface->w;
  i->textureheight = i->surface->h;
  i->renderer = e->renderer;

  if (i->scaled_texture)
    SDL_DestroyTexture(i->scaled_texture);

  i->scaled_texture = i->texture;

  if (!keep_surface) {
    SDL_FreeSurface(i->surface);
    i->surface = NULL;
  }
  return 1;
}

int image_init(image_t* i,
               engine_t* e,
               const char* filename,
               int tw,
               int th,
               int keep_surface) {
  assert(i);

  i->tw = tw;
  i->th = th;
  i->orig_tw = tw;
  i->orig_th = th;
  i->scaled_texture = NULL;
  i->surface = NULL;
  i->texture = NULL;

  i->scale = 1.0;

  return image_load(i, e, filename, keep_surface);
}

int image_init_blank(image_t* i, engine_t* e, int w, int h, int tw, int th) {
  assert(i);

  // Learn about renderer
  SDL_RendererInfo info;
  if (SDL_GetRendererInfo(e->renderer, &info) < 0) {
    fprintf(stderr, "init image: %s\n", SDL_GetError());
    return 0;
  }

  // Try first texture format
  Uint32 texformat = info.texture_formats[0];
  SDL_Texture* tex =
      SDL_CreateTexture(e->renderer, texformat, SDL_TEXTUREACCESS_TARGET, w, h);
  if (!tex) {
    fprintf(stderr, "init blank image: %s\n", SDL_GetError());
    return 0;
  }

  SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);

  i->texture = tex;
  i->renderer = e->renderer;
  i->texturewidth = w;
  i->textureheight = h;
  i->tw = tw;
  i->th = th;
  i->pixel_format = texformat;
  i->surface = NULL;

  // Target new texture
  SDL_SetRenderTarget(i->renderer, tex);

  // Clear the new texture (transparent black)
  Uint8 origR, origG, origB, origA;
  SDL_GetRenderDrawColor(i->renderer, &origR, &origG, &origB, &origA);
  SDL_SetRenderDrawColor(i->renderer, 0, 0, 0, 0);
  SDL_RenderClear(i->renderer);
  SDL_SetRenderDrawColor(i->renderer, origR, origG, origB, origA);

  // Target the screen
  SDL_SetRenderTarget(i->renderer, NULL);

  i->scaled_texture = i->texture;
  return 1;
}

void image_deinit(image_t* i) {
  if (i) {
    if (i->texture == i->scaled_texture) {
      if (i->texture)
        SDL_DestroyTexture(i->texture);
    } else {
      if (i->texture)
        SDL_DestroyTexture(i->texture);

      if (i->scaled_texture)
        SDL_DestroyTexture(i->scaled_texture);
    }

    if (i->surface)
      SDL_FreeSurface(i->surface);
  }
}

int image_color_mod(image_t* i, uint8_t r, uint8_t g, uint8_t b) {
  assert(i);
  assert(i->texture);

  if (SDL_SetTextureColorMod(i->texture, r, g, b) < 0) {
    fprintf(stderr, "color mod failed: %s\n", SDL_GetError());
    return 0;
  }

  return 1;
}

int image_alpha_mod(image_t* i, uint8_t a) {
  assert(i);
  assert(i->texture);

  if (SDL_SetTextureAlphaMod(i->texture, a) < 0) {
    fprintf(stderr, "alpha mod failed: %s\n", SDL_GetError());
    return 0;
  }

  return 1;
}

void image_draw(const image_t* i,
                int sx,
                int sy,
                int sw,
                int sh,
                int dx,
                int dy,
                int dw,
                int dh) {
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
  while (*text) {
    image_draw_ascii_char(i, *text, dx, dy);
    dx += i->tw;
    text++;
  }
}

void image_draw_text_word(const image_t* i,
                          const char* text,
                          size_t n,
                          int dx,
                          int dy) {
  for (size_t j = 0; j < n; j++) {
    image_draw_ascii_char(i, text[j], j * i->tw + dx, dy);
  }
}

static void image_draw_text_internal(const image_t* i,
                                     const char* text,
                                     int dx,
                                     int dy,
                                     int wrap_width,
                                     int dry_run,
                                     int* w,
                                     int* h) {
  int max_w = 0;

  int linec = wrap_width / i->tw;

  int firstword = 1;
  int drawx = dx;
  int linepos = 0;

  // for each line:
  do {
    // seek to end of word
    char* wordend = (char*)text;
    while (*wordend && (*wordend != ' '))
      wordend++;

    size_t wordlen = wordend - text;

    if (wordlen + linepos > linec) {
      if (firstword) {
        // draw word, advance line
        if (!dry_run)
          image_draw_text_word(i, text, wordlen, drawx, dy);
        if (drawx + wordlen * i->tw > max_w)
          max_w = drawx + wordlen * i->tw;
        drawx = dx;
        dy += i->th;
        linepos = 0;

      } else {
        // advance line, draw word
        drawx = dx;
        dy += i->th;
        linepos = wordlen + 1;
        if (!dry_run)
          image_draw_text_word(i, text, wordlen, drawx, dy);
        firstword = 0;
        drawx += i->tw * (wordlen + 1);

        if (drawx - dx > max_w)
          max_w = drawx - dx;
      }
    } else {
      // draw word, move forward
      if (!dry_run)
        image_draw_text_word(i, text, wordlen, drawx, dy);
      linepos += wordlen;
      drawx += i->tw * wordlen;
      if (firstword)
        firstword = 0;

      // space
      linepos++;
      drawx += i->tw;

      if (drawx - dx > max_w)
        max_w = drawx - dx;
    }

    if (*wordend) {
      text = wordend + 1;
    } else {
      text = wordend;
    }
  } while (*text);

  if (w)
    *w = max_w;

  if (h)
    *h = dy + i->th;
}

void image_draw_text(const image_t* i,
                     const char* text,
                     int dx,
                     int dy,
                     int wrap_width) {
  image_draw_text_internal(i, text, dx, dy, wrap_width, /*dry_run=*/0,
                           /*w=*/NULL, /*h=*/NULL);
}

void image_calculate_text_size(const image_t* i,
                               const char* text,
                               int wrap_width,
                               int* w,
                               int* h) {
  image_draw_text_internal(i, text, /*dx=*/0, /*dy=*/0, wrap_width,
                           /*dry_run=*/1, w, h);
}

void image_get_size(const image_t* i, int* w, int* h) {
  SDL_QueryTexture(i->scaled_texture, NULL, NULL, w, h);
}

int image_target_image(image_t* i, image_t* j) {
  SDL_Texture* target = NULL;
  if (j)
    target = j->texture;

  if (SDL_SetRenderTarget(i->renderer, target) < 0) {
    fprintf(stderr, "target image: %s\n", SDL_GetError());
    return 0;
  }

  return 1;
}

// TODO: make this work
int image_save_as_png(image_t* i, const char* filename) {
  SDL_Texture* original_target = SDL_GetRenderTarget(i->renderer);
  SDL_PixelFormat* fmt = NULL;
  uint8_t* pixels = NULL;
  SDL_Surface* surface = NULL;
  
  int w, h;
  uint32_t pixelformat;
  if (SDL_QueryTexture(i->texture, &pixelformat, NULL, &w, &h) == -1)
    goto image_save_as_png_fail;

  // Create a copy of |i|'s texture with SDL_TEXUREACCESS_TARGET which is needed
  // for SDL_RenderReadPixels().
  SDL_Texture* copy = NULL;
  copy = SDL_CreateTexture(i->renderer, pixelformat, SDL_TEXTUREACCESS_TARGET, w, h);
  if (!copy)
    return 0;

  if (SDL_SetRenderTarget(i->renderer, copy) != 0)
    goto image_save_as_png_fail;

  if (SDL_RenderCopy(i->renderer, i->texture, NULL, NULL) != 0)
    goto image_save_as_png_fail;

  SDL_RenderPresent(i->renderer);

  // Get pixels from |copy|.
  fmt = SDL_AllocFormat(pixelformat);
  if (!fmt)
    goto image_save_as_png_fail;

  pixels = (uint8_t*)malloc(w * h * fmt->BytesPerPixel);
  if (!pixels)
    goto image_save_as_png_fail;
 
  int pitch = w * fmt->BytesPerPixel;
  if (SDL_RenderReadPixels(i->renderer, NULL, 0, pixels, pitch) != 0)
    goto image_save_as_png_fail;

  if (SDL_SetRenderTarget(i->renderer, original_target) != 0)
    goto image_save_as_png_fail;

  SDL_DestroyTexture(copy);
  copy = NULL;

  surface = SDL_CreateRGBSurfaceWithFormatFrom(
      pixels, w, h, fmt->BitsPerPixel, pitch, pixelformat);
  SDL_FreeFormat(fmt);
  fmt = NULL;

  if (!surface)
    goto image_save_as_png_fail;

  int res = IMG_SavePNG(surface, filename);
  SDL_FreeSurface(surface);
  free(pixels);
  return res == 0;

image_save_as_png_fail:
  SDL_SetRenderTarget(i->renderer, original_target);

  if (pixels)
    free(pixels);

  if (fmt)
    SDL_FreeFormat(fmt);

  if (copy)
    SDL_DestroyTexture(copy);

  fprintf(stderr, "image_save_as_png: %s\n", SDL_GetError());
  return 0;
}

int image_scale(image_t* i, double scale) {
  assert(i);
  assert(scale);

  if (i->texture != i->scaled_texture) {
    if (i->scaled_texture)
      SDL_DestroyTexture(i->scaled_texture);
  }

  Uint32 pixelformat;
  int origW, origH;
  if (SDL_QueryTexture(i->texture, &pixelformat, NULL, &origW, &origH) == -1)
    return 0;

  SDL_Texture* tex =
      SDL_CreateTexture(i->renderer, pixelformat, SDL_TEXTUREACCESS_TARGET,
                        origW * scale, origH * scale);
  if (!tex) {
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
  // SDL_RenderPresent(i->renderer);

  // Target the screen
  SDL_SetRenderTarget(i->renderer, NULL);

  i->scaled_texture = tex;

  return 1;
}
