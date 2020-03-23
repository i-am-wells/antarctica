#include "engine.h"

#include <SDL.h>
#include <SDL_mixer.h>
#include <assert.h>
#include <lua.h>
#include <stdio.h>
#include <stdlib.h>

#include "lua_helpers.h"

int engine_init(engine_t* e,
                char* wtitle,
                int x,
                int y,
                int w,
                int h,
                int wflags,
                int ridx,
                int rflags) {
  assert(e);

  // Create window and renderer
  e->window = SDL_CreateWindow(wtitle, x, y, w, h, wflags);
  if (!e->window)
    goto engine_init_fail;

  // SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
  e->renderer = SDL_CreateRenderer(e->window, ridx, rflags);
  if (!e->renderer)
    goto engine_init_fail;

  SDL_RendererInfo rinfo;
  if (SDL_GetRendererInfo(e->renderer, &rinfo) == -1) {
    fprintf(stderr, "warning: failed to get renderer info\n");
  } else {
    /*
      printf("Renderer name: %s\n", rinfo.name);
      printf("Max texture dimensions: %dx%d\n", rinfo.max_texture_width,
      rinfo.max_texture_height); if(rinfo.flags & SDL_RENDERER_SOFTWARE)
          printf("Software renderer\n");
      if(rinfo.flags & SDL_RENDERER_ACCELERATED)
          printf("Hardware accelerated renderer\n");
      if(rinfo.flags & SDL_RENDERER_PRESENTVSYNC)
          printf("Vsync enabled\n");
      if(rinfo.flags & SDL_RENDERER_TARGETTEXTURE)
          printf("Rendering to texture supported\n");
    */
  }

  // TODO allow setting with lua
  SDL_SetRenderDrawBlendMode(e->renderer, SDL_BLENDMODE_BLEND);

  // Clear screen
  SDL_SetRenderDrawColor(e->renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
  SDL_RenderClear(e->renderer);
  SDL_RenderPresent(e->renderer);

  // not running yet
  e->running_depth = 0;
  e->targetfps = 60;

  // Set up audio
  if (Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 1024) == -1) {
    fprintf(stderr, "failed to open audio device: %s\n", Mix_GetError());
    return 1;
  }

  // Success
  return 1;

engine_init_fail:
  engine_deinit(e);
  return 0;
}

void engine_deinit(engine_t* e) {
  if (e) {
    Mix_CloseAudio();

    // Destroy the window and the renderer
    if (e->renderer) {
      SDL_DestroyRenderer(e->renderer);
      e->renderer = NULL;
    }

    if (e->window) {
      SDL_DestroyWindow(e->window);
      e->window = NULL;
    }
  }
}

// Retrieve an event handler associated with key
static int get_event_handler(lua_State* L, int key) {
  lua_pushinteger(L, key);

  // We assume the handler table is on the top of the stack
  if (lua_gettable(L, -2) == LUA_TNIL) {
    lua_pop(L, 1);
    return 0;
  }

  return 1;
}

void engine_set_scale(engine_t* e, float scaleX, float scaleY) {
  SDL_RenderSetScale(e->renderer, scaleX, scaleY);
}

void engine_draw_point(engine_t* e, int x, int y) {
  SDL_RenderDrawPoint(e->renderer, x, y);
}

void engine_draw_line(engine_t* e, int x0, int y0, int x1, int y1) {
  SDL_RenderDrawLine(e->renderer, x0, y0, x1, y1);
}

void engine_draw_rect(engine_t* e, int x, int y, int w, int h) {
  SDL_Rect r;
  r.x = x;
  r.y = y;
  r.w = w;
  r.h = h;
  SDL_RenderDrawRect(e->renderer, &r);
}

void engine_fill_rect(engine_t* e, int x, int y, int w, int h) {
  SDL_Rect r;
  r.x = x;
  r.y = y;
  r.w = w;
  r.h = h;
  SDL_RenderFillRect(e->renderer, &r);
}

void engine_set_draw_color(engine_t* e,
                           uint8_t r,
                           uint8_t g,
                           uint8_t b,
                           uint8_t a) {
  SDL_SetRenderDrawColor(e->renderer, r, g, b, a);
}

void engine_get_draw_color(engine_t* e,
                           uint8_t* r,
                           uint8_t* g,
                           uint8_t* b,
                           uint8_t* a) {
  SDL_GetRenderDrawColor(e->renderer, r, g, b, a);
}

void engine_clear(engine_t* e) {
  SDL_RenderClear(e->renderer);
}

void engine_set_render_logical_size(engine_t* e, int w, int h) {
  SDL_RenderSetLogicalSize(e->renderer, w, h);
}

void engine_get_render_logical_size(const engine_t* e, int* w, int* h) {
  SDL_RenderGetLogicalSize(e->renderer, w, h);
}

void engine_get_render_size(const engine_t* e, int* w, int* h) {
  SDL_GetRendererOutputSize(e->renderer, w, h);
}

// For each event received by SDL, check if a handler exists and run it.
// Returns SDL_QUIT if a quit event was received, or 0 otherwise.
static int engine_run_event_handlers(engine_t* e, lua_State* L) {
  SDL_Event ev;
  while (SDL_PollEvent(&ev)) {
    if (ev.type == SDL_WINDOWEVENT &&
        get_event_handler(L, ev.type | ev.window.event)) {
      switch (ev.window.event) {
        // Window events with windowID and timestamp only
        case SDL_WINDOWEVENT_SHOWN:
        case SDL_WINDOWEVENT_HIDDEN:
        case SDL_WINDOWEVENT_EXPOSED:
        case SDL_WINDOWEVENT_MINIMIZED:
        case SDL_WINDOWEVENT_MAXIMIZED:
        case SDL_WINDOWEVENT_RESTORED:
        case SDL_WINDOWEVENT_ENTER:
        case SDL_WINDOWEVENT_LEAVE:
        case SDL_WINDOWEVENT_FOCUS_GAINED:
        case SDL_WINDOWEVENT_FOCUS_LOST:
        case SDL_WINDOWEVENT_CLOSE:
          lua_pushinteger(L, ev.window.windowID);
          lua_pushinteger(L, ev.window.timestamp);
          lua_call(L, 2, 0);
          break;

        // Window events with size or position
        case SDL_WINDOWEVENT_MOVED:
        case SDL_WINDOWEVENT_RESIZED:
        case SDL_WINDOWEVENT_SIZE_CHANGED:
          lua_pushinteger(L, ev.window.data1);
          lua_pushinteger(L, ev.window.data2);
          lua_pushinteger(L, ev.window.windowID);
          lua_pushinteger(L, ev.window.timestamp);
          lua_call(L, 4, 0);
          break;

        default:
          lua_pop(L, 1);
          break;
      }
    } else if (ev.type == SDL_KEYDOWN && get_event_handler(L, ev.type)) {
      // Key press event
      lua_pushstring(L, SDL_GetKeyName(ev.key.keysym.sym));
      lua_pushinteger(L, ev.key.keysym.mod);
      lua_pushinteger(L, ev.key.repeat);
      lua_pushinteger(L, ev.key.state);
      lua_pushinteger(L, ev.key.windowID);
      lua_pushinteger(L, ev.key.timestamp);
      lua_call(L, 6, 0);
    } else if (ev.type == SDL_KEYUP && get_event_handler(L, ev.type)) {
      // Key release event
      lua_pushstring(L, SDL_GetKeyName(ev.key.keysym.sym));
      lua_pushinteger(L, ev.key.keysym.mod);
      lua_pushinteger(L, ev.key.repeat);
      lua_pushinteger(L, ev.key.state);
      lua_pushinteger(L, ev.key.windowID);
      lua_pushinteger(L, ev.key.timestamp);
      lua_call(L, 6, 0);
    } else if (ev.type == SDL_MOUSEMOTION && get_event_handler(L, ev.type)) {
      // Mouse motion event
      lua_pushinteger(L, ev.motion.x);
      lua_pushinteger(L, ev.motion.y);
      lua_pushinteger(L, ev.motion.xrel);
      lua_pushinteger(L, ev.motion.yrel);
      lua_pushinteger(L, ev.motion.state);
      lua_pushinteger(L, ev.motion.which);
      lua_pushinteger(L, ev.motion.windowID);
      lua_pushinteger(L, ev.motion.timestamp);
      lua_call(L, 8, 0);
    } else if (ev.type == SDL_MOUSEBUTTONDOWN &&
               get_event_handler(L, ev.type)) {
      // Mouse button down event
      lua_pushinteger(L, ev.button.x);
      lua_pushinteger(L, ev.button.y);
      lua_pushinteger(L, ev.button.button);
      lua_pushinteger(L, ev.button.clicks);
      lua_pushinteger(L, ev.button.state);
      lua_pushinteger(L, ev.button.which);
      lua_pushinteger(L, ev.button.windowID);
      lua_pushinteger(L, ev.button.timestamp);
      lua_call(L, 8, 0);
    } else if (ev.type == SDL_MOUSEBUTTONUP && get_event_handler(L, ev.type)) {
      // Mouse button up event
      lua_pushinteger(L, ev.button.x);
      lua_pushinteger(L, ev.button.y);
      lua_pushinteger(L, ev.button.button);
      lua_pushinteger(L, ev.button.which);
      lua_pushinteger(L, ev.button.windowID);
      lua_pushinteger(L, ev.button.timestamp);
      lua_call(L, 6, 0);
    } else if (ev.type == SDL_MOUSEWHEEL && get_event_handler(L, ev.type)) {
      // Mouse wheel event
      lua_pushinteger(L, ev.wheel.x);
      lua_pushinteger(L, ev.wheel.y);
      lua_pushinteger(L, ev.wheel.direction);
      lua_pushinteger(L, ev.wheel.which);
      lua_pushinteger(L, ev.wheel.windowID);
      lua_pushinteger(L, ev.wheel.timestamp);
      lua_call(L, 6, 0);
    } else if (ev.type == SDL_TEXTINPUT && get_event_handler(L, ev.type)) {
      lua_pushstring(L, ev.text.text);
      lua_pushinteger(L, ev.text.windowID);
      lua_pushinteger(L, ev.text.timestamp);
      lua_call(L, 3, 0);
    } else if (ev.type == SDL_TEXTEDITING && get_event_handler(L, ev.type)) {
      lua_pushstring(L, ev.edit.text);
      lua_pushinteger(L, ev.edit.start);
      lua_pushinteger(L, ev.edit.length);
      lua_pushinteger(L, ev.edit.windowID);
      lua_pushinteger(L, ev.edit.timestamp);
      lua_call(L, 5, 0);
    } else if (ev.type == SDL_QUIT) {
      // Quit event (alt-f4 or window close or ctrl-C)
      if (get_event_handler(L, ev.type)) {
        lua_pushinteger(L, ev.quit.timestamp);
        lua_call(L, 1, 0);
      } else {
        return SDL_QUIT;
      }
    }
    // TODO more
  }

  return 0;
}

//////////////

void engine_run(engine_t* e, lua_State* L) {
  assert(e);

  // Push event handler table and draw function
  lua_pushlightuserdata(L, e);
  lua_gettable(L, LUA_REGISTRYINDEX);

  int prev_depth = e->running_depth;
  e->running_depth++;
  uint32_t tick1 = 0, elapsed = 1;
  uint32_t targetframetime = 1000 / e->targetfps;

  int counter = 0;

  // Event loop
  while (e->running_depth > prev_depth) {
    // Clear the renderer every time we redraw (necessary because of some
    // double-buffering implementations)
    // SDL_RenderClear(e->renderer);

    // push redraw callback
    lua_pushlightuserdata(L, e + 1);
    lua_gettable(L, LUA_REGISTRYINDEX);
    lua_pushinteger(L, tick1);
    lua_pushinteger(L, elapsed);
    lua_pushinteger(L, counter);
    lua_call(L, 3, 0);

    // Show the buffer
    SDL_RenderPresent(e->renderer);

    // Run event handlers
    if (engine_run_event_handlers(e, L) == SDL_QUIT)
      e->running_depth--;

    // TODO run async callbacks

    // Time to roughly 60 fps
    elapsed = SDL_GetTicks() - tick1;
    // fprintf(stderr, "%u\n", elapsed);
    if (elapsed < targetframetime)
      SDL_Delay(targetframetime - elapsed);
    // tick0 = tick1;
    tick1 = SDL_GetTicks();

    counter++;
    if (counter == 256)
      counter = 0;
  }

  // Pop event handler table and redrawer
  lua_pop(L, 2);
}
