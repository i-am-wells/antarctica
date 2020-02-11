#ifndef _VEC_H
#define _VEC_H

#include <stddef.h>

typedef struct vec_t {
  void** data;
  size_t size, cap;
} vec_t;

#define VEC_DEFAULT_CAPACITY 8

int vec_init(vec_t* v, size_t cap);
void vec_deinit(vec_t* v);

vec_t* vec_create(size_t cap);
void vec_destroy(vec_t* v);

int vec_resize(vec_t* v, size_t newcap);

int vec_push(vec_t* v, void* p);
void* vec_pop(vec_t* v);
// ?? int vec_splice(vec_t * dest, const vec_t * src, size_t dest_i, size_t
// src_i, size_t src_n);
int vec_insert(vec_t* v, size_t idx, void* ptr);
void vec_remove(vec_t* v, size_t i, size_t n);

void vec_move(vec_t* v, size_t destidx, size_t srcidx);

void* vec_get(const vec_t* v, size_t idx);
void vec_set(vec_t* v, size_t idx, void* ptr);

#endif
