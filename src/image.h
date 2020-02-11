/**
 *  \file image.h
 */

#ifndef _IMAGE_H
#define _IMAGE_H

#include <SDL.h>

#include "engine.h"

/**
 *  \struct image_t
 *
 *  The image_t struct includes an image's SDL texture data and a pointer to the
 *  the renderer that owns the texture. Note that an SDL texture can only be
 *  used by the renderer it was created with.
 */
typedef struct image_t {
  SDL_Renderer* renderer; /**< SDL rendering context */
  SDL_Texture* texture;   /**< SDL texture data */
  SDL_Surface* surface;   // optional software surface

  int texturewidth, textureheight; /**< Pixel width and height of the texture */

  int tw, th; /**< Pixel width and height used to divide the image into tiles */
  int orig_tw, orig_th;
  uint32_t pixel_format;

  SDL_Texture* scaled_texture;
  double scale;
} image_t;

/**
 *  Loads an image from a file (png, jpg, bmp).
 *
 *  \param i    image pointer
 *  \param e    engine pointer -- the engine's renderer will own this image
 *  \param filename Path to image file to be loaded
 *
 *  \return 1 on success, 0 on failure
 */
int image_load(image_t* i, engine_t* e, const char* filename, int keep_surface);

/**
 *  Initializes an image_t by loading an image file and setting tile dimensions.
 *
 *  \param i    image pointer
 *  \param e    engine pointer (see image_load)
 *  \param filename path to image file
 *  \param tw   pixel width of tiles
 *  \param th   pixel height of tiles
 *
 *  \return 1 on success, 0 on failure
 */
int image_init(image_t* i,
               engine_t* e,
               const char* filename,
               int tw,
               int th,
               int keep_surface);

/**
 *  Frees image data by destroying the SDL texture.
 *
 *  \param i    image pointer
 */
void image_deinit(image_t* i);

int image_color_mod(image_t* i, uint8_t r, uint8_t g, uint8_t b);
int image_alpha_mod(image_t* i, uint8_t a);

/**
 *  Copies image pixels from the source rect into the destination rect in the
 *  renderer (scaling as needed).
 *
 *  \param i    image pointer
 *  \param sx   source x
 *  \param sy   source y
 *  \param sw   source width
 *  \param sh   source height
 *  \param dx   destination x
 *  \param dy   destination y
 *  \param dw   destination width
 *  \param dh   destination height
 */
void image_draw(const image_t* i,
                int sx,
                int sy,
                int sw,
                int sh,
                int dx,
                int dy,
                int dw,
                int dh);

/**
 *  Copies the image tile from tile coordinates (tx, ty) to renderer pixel
 *  location (dx, dy) with no scaling. Equivalent to
 *
 *      image_draw(i, tx * i->tw, ty * i->th, i->tw, i->th, dx, dy, i->tw,
 * i->th);
 *
 *  \param i    image pointer
 *  \param tx   tile x (unit: tile width)
 *  \param ty   tile y (unit: tile height)
 *  \param dx   destination x (pixels)
 *  \param dy   destination y (pixels)
 */
void image_draw_tile(const image_t* i, int tx, int ty, int dx, int dy);

/**
 *  Copies the entire image into the renderer without scaling.
 *
 *  \param i    image pointer
 *  \param dx   destination x (pixels)
 *  \param dy   destination y (pixels)
 */
void image_draw_whole(const image_t* i, int dx, int dy);

/**
 *  Sets *w and *h to the pixel width and height of the image texture,
 *  respectively.
 *
 *  TODO remove?
 *
 *  \param i    image pointer
 *  \param w    pointer to width to be filled in
 *  \param h    pointer to height to be filled in
 */
void image_get_size(const image_t* i, int* w, int* h);

void image_draw_text(const image_t* i,
                     const char* text,
                     int dx,
                     int dy,
                     int wrapw);

int image_scale(image_t* i, double scaleBy);

int image_target_image(image_t* i, image_t* j);
int image_init_blank(image_t* i, engine_t* e, int w, int h, int tw, int th);

#endif
