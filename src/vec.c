#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "vec.h"


vec_t * vec_create(size_t cap) {
    vec_t * v = (vec_t*)calloc(1, sizeof(vec_t));
    if(!v)
        return NULL;

    if(!vec_init(v, cap)) {
        free(v);
        return NULL;
    }

    return v;
}


int vec_init(vec_t * v, size_t cap) {
    assert(v);
    if(cap == 0)
        cap = VEC_DEFAULT_CAPACITY;

    v->data = (void**)malloc(cap * sizeof(void*));
    if(!v->data)
        return 0;

    v->size = 0;
    v->cap = cap;
    return 1;
}


void vec_deinit(vec_t* v) {
    if(v) {
        if(v->data)
            free(v->data);
    }
}


void vec_destroy(vec_t * v) {
    if(v) {
        vec_deinit(v);
        free(v);
    }
}


int vec_resize(vec_t * v, size_t newcap) {
    assert(v);
    
    void** data = (void**)realloc(v->data, newcap * sizeof(void*));
    if(!data)
        return 0;

    v->data = data;
    v->cap = newcap;
    return 1;
}

int vec_extend_if_needed(vec_t * v) {
    if(v->size == v->cap) {
        if(!vec_resize(v, v->cap * 2))
            return 0;
    }

    return 1;
}


void vec_contract_if_needed(vec_t * v) {
    if(v->size <= (v->cap / 4)) {
        vec_resize(v, v->cap / 2);
    }
}


int vec_push(vec_t * v, void * p) {
    assert(v);
    if(!vec_extend_if_needed(v))
        return 0;

    v->data[v->size] = p;
    v->size++;
    return 1;
}


void * vec_pop(vec_t * v) {
    assert(v);
    if(v->size == 0) {
        return NULL;
    }

    void * ret = v->data[v->size - 1];
    v->size--;
    vec_contract_if_needed(v);

    return ret;
}


/* what was this for?
int vec_splice(vec_t * dest, const vec_t * src, size_t dest_i, size_t src_i, size_t src_n) {
    assert(dest);
    assert(src);
    
    size_t newsize = dest->size + src_n;
    size_t newcap = dest->cap;
    if(newsize > dest->cap) {
        while(newcap < newsize)
            newcap *= 2;
        if(!vec_resize(dest, newcap))
            return 0;
    }

    // Shift dest elements up
    memmove(dest->data + dest_i + src_n, src_i->data, src_n);
    
    dest->size = newsize;
    dest->cap  = newcap;
    return 1;
}
*/


void vec_remove(vec_t * v, size_t i, size_t n) {
    assert(v);
    assert(i < v->size);

    memmove(v->data + i, v->data + i + n, n);

    v->size -= n;

    vec_contract_if_needed(v);
}


int vec_insert(vec_t* v, size_t idx, void* ptr) {
    if(idx == v->size) {
        vec_push(v, ptr);
        return 1;
    } else if(idx < v->size) {
        if(!vec_extend_if_needed(v))
            return 0;

        memmove(v->data + idx + 1, v->data + idx, sizeof(void*));
        vec_set(v, idx, ptr);
        
        return 1;
    }

    return 0;
}


void* vec_get(const vec_t* v, size_t idx) {
    if(idx >= v->size)
        return NULL;

    return v->data[idx];
}


void vec_set(vec_t* v, size_t idx, void* ptr) {
    if(idx == v->size) {
        vec_push(v, ptr);
    } else {
        v->data[idx] = ptr;
    }
}


void vec_move(vec_t* v, size_t destidx, size_t srcidx) {
    assert(destidx < v->size);
    assert(srcidx < v->size);

    if(srcidx == destidx)
        return;

    void* tmp = v->data[srcidx];
    if(srcidx < destidx) {
        size_t numitems = destidx - srcidx;
        memmove(v->data + srcidx, v->data + srcidx + 1, numitems * sizeof(void*));
    } else if(destidx < srcidx) {
        size_t numitems = srcidx - destidx;
        memmove(v->data + destidx + 1, v->data + destidx, numitems + sizeof(void*));
    }
    v->data[destidx] = tmp;
}


void vec_swap(vec_t* v, size_t idxa, size_t idxb) {
    assert(idxa < v->size);
    assert(idxb < v->size);

    void* tmp = v->data[idxa];
    v->data[idxa] = v->data[idxb];
    v->data[idxb] = tmp;
}


