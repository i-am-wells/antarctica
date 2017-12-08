#include <assert.h>
#include <stdlib.h>

#include <SDL.h>
#include <SDL_mixer.h>

#include "sound.h"

int sound_init(sound_t* t, const char* file) {
    assert(t);
    Mix_Chunk* chunk = Mix_LoadWAV(file);
    if(!chunk) {
        return 0;
    }

    t->chunk = chunk;

    int frequency, channels;
    uint16_t format;
    if(!Mix_QuerySpec(&frequency, &format, &channels)) {
        Mix_FreeChunk(chunk);
        return 0;
    }

    int bps = 2;
    if(format == AUDIO_U8 || format == AUDIO_S8) {
        bps = 1;
    }

    t->duration = (chunk->alen / bps) / frequency;

    return 1;
};


void sound_deinit(sound_t* t) {
    if(t) {
        Mix_FreeChunk(t->chunk);
    }
}


sound_t* sound_create(const char* file) {
    sound_t* s = (sound_t*)calloc(1, sizeof(sound_t));
    if(!s) {
        return NULL;
    }

    if(!sound_init(s, file)) {
        free(s);
        return NULL;
    }

    return s;
}


void sound_destroy(sound_t* s) {
    if(s) {
        sound_deinit(s);
        free(s);
    }
}


int sound_play(const sound_t* s, int channel, int nloops) {
    if(Mix_PlayChannel(channel, s->chunk, nloops) == -1) {
        // TODO print error
        return 0;
    }

    return 1;
}

