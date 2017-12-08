#ifndef _SOUND_H
#define _SOUND_H

#include <SDL_mixer.h>

typedef struct sound_t {
    Mix_Chunk* chunk;
    double duration;
} sound_t;


int sound_init(sound_t* t, const char* file);
void sound_deinit(sound_t* t);
sound_t* sound_create(const char* file);
void sound_destroy(sound_t* s);
int sound_play(const sound_t* s, int channel, int nloops);

#endif

