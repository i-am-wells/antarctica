/**
 *  \file engine.h
 */

#ifndef _ENGINE_H
#define _ENGINE_H

#include <SDL.h>
#include <lua.h>

/**
 *  \struct engine_t
 */
typedef struct engine_t {
  SDL_Window* window;
  SDL_Renderer* renderer;
  int running_depth;
  int targetfps;
} engine_t;

/**
 *  Destroy an engine's window and renderer
 *
 *  \param e Pointer to engine to clean up
 */
void engine_deinit(engine_t* e);

/**
 *  Create a window and renderer for an engine. See SDL documentation for
 *  special values for window and renderer creation arguments.
 *
 *  \param e        Engine pointer
 *  \param wtitle   Title of the window to be created
 *  \param x        left x position of window
 *  \param y        top y position of window
 *  \param w        window width
 *  \param h        window height
 *  \param wflags   SDL window creation flag mask
 *  \param ridx     SDL renderer index
 *  \param rflags   SDL renderer creation flags
 *
 *  \return     0 if window or renderer creation failed, 1 otherwise
 */
int engine_init(engine_t* e,
                char* wtitle,
                int x,
                int y,
                int w,
                int h,
                int wflags,
                int ridx,
                int rflags);

/**
 *  Starts the engine's event loop. The loop will exit when the engine's
 *  "running" field is set to 0.
 *
 *  \param e    Engine pointer
 *  \param L    Lua state pointer, used for calling Lua event handlers
 */
void engine_run(engine_t* e, lua_State* L);

/**
 *  Draw a point in the renderer at (x, y), or does nothing if (x, y) is outside
 *  the renderer's boundaries.
 *
 *  \param e    Engine pointer
 *  \param x    x coordinate
 *  \param y    y coordinate
 */
void engine_draw_point(engine_t* e, int x, int y);

/**
 *  Draw a line from (x0, y0) to (x1, y1). Each point may be outside the
 *  renderer's boundaries.
 *
 *  \param e    Engine pointer
 *  \param x0   first x coordinate
 *  \param y0   first y coordinate
 *  \param x1   second x coordinate
 *  \param y1   second y coordinate
 */
void engine_draw_line(engine_t* e, int x0, int y0, int x1, int y1);

/**
 *  Draw an empty rectangle at (x, y) with width w and height h.
 *
 *  \param e    Engine pointer
 *  \param x    x coordinate
 *  \param y    y coordinate
 *  \param w    width
 *  \param h    height
 */
void engine_draw_rect(engine_t* e, int x, int y, int w, int h);

/**
 *  Draw a filled-in rectangle at (x, y) with width w and height h.
 *
 *  \param e    Engine pointer
 *  \param x    x coordinate
 *  \param y    y coordinate
 *  \param w    width
 *  \param h    height
 */
void engine_fill_rect(engine_t* e, int x, int y, int w, int h);

/**
 *  Set the drawing color.
 *
 *  \param e    Engine pointer
 *  \param r    Red value (0-255)
 *  \param g    Green value (0-255)
 *  \param b    Blue value (0-255)
 *  \param a    Alpha (0-255, or SDL_ALPHA_OPAQUE)
 */
void engine_set_draw_color(engine_t* e,
                           uint8_t r,
                           uint8_t g,
                           uint8_t b,
                           uint8_t a);

/**
 *  Get the renderer's current drawing color.
 *
 *  \param e    Engine pointer
 *  \param r    Pointer to red value
 *  \param g    Pointer to green value
 *  \param b    Pointer to blue value
 *  \param a    Pointer to alpha value
 */
void engine_get_draw_color(engine_t* e,
                           uint8_t* r,
                           uint8_t* g,
                           uint8_t* b,
                           uint8_t* a);

/**
 *  Clear the renderer (by setting every pixel to the current drawing color)
 *
 *  \param e    Engine pointer
 */
void engine_clear(engine_t* e);

void engine_set_render_logical_size(engine_t* e, int w, int h);
void engine_get_render_logical_size(const engine_t* e, int* w, int* h);
void engine_get_render_size(const engine_t* e, int* w, int* h);

void engine_set_scale(engine_t* e, float scaleX, float scaleY);

#endif
