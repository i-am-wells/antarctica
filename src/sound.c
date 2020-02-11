#include "sound.h"

#include <SDL.h>
#include <SDL_mixer.h>
#include <assert.h>
#include <stdlib.h>

/*
 *
 *
 * channel methods here
 *
 *
 */

int soundchannel_set_volume(int channel, double l, double r) {
  // fprintf(stderr, "vol %f %f\n", l, r);
  // Mix_Pause(channel-1);
  channel--;
  if (!Mix_SetPanning(channel, l * 254, r * 254)) {
    fprintf(stderr, "set stereo volume on channel %d: %s\n", channel,
            Mix_GetError());
    return 0;
  }
  // Mix_Resume(channel-1);
  return 1;
}

void soundchannel_reallocate(int numChannels) {
  fprintf(stderr, "previously: %d\n", Mix_AllocateChannels(-1));
  Mix_AllocateChannels(numChannels);
  fprintf(stderr, "now: %d\n", Mix_AllocateChannels(-1));
}

/*
 *
 *
 * sound_t methods here
 *
 *
 */

int sound_init(sound_t* t, const char* file) {
  assert(t);
  Mix_Chunk* chunk = Mix_LoadWAV(file);
  if (!chunk) {
    return 0;
  }

  t->chunk = chunk;

  int frequency, channels;
  uint16_t format;
  if (!Mix_QuerySpec(&frequency, &format, &channels)) {
    Mix_FreeChunk(chunk);
    return 0;
  }

  int bps = 2;
  if (format == AUDIO_U8 || format == AUDIO_S8) {
    bps = 1;
  }

  t->duration = (chunk->alen / bps) / frequency;

  return 1;
};

void sound_deinit(sound_t* t) {
  if (t) {
    Mix_FreeChunk(t->chunk);
  }
}

int sound_play(const sound_t* s, int channel, int nloops, int duration) {
  if (Mix_PlayChannelTimed(channel - 1, s->chunk, nloops, duration) == -1) {
    fprintf(stderr, "play sound: %s\n", Mix_GetError());
    return 0;
  }

  return 1;
}
