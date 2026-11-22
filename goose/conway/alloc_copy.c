/* goose -> python wrapper
*/

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>


// generic goose slice T[:]
typedef struct {
  void *data;
  int64_t len;
} gs_slice;

// copy anytype slice to a c allocated buffer and return pointer as u64
// malloc + memcpy

uint64_t gs_alloc_copy(gs_slice src, size_t element_size) {
  if (src.data == NULL || src.len == 0)
    return 0;

  size_t bytes = src.len * element_size;
  void *dst = malloc(bytes);
  if (!dst)
    return 0;

  memcpy(dst, src.data, bytes);
  return (uint64_t)(uintptr_t)dst;
}

void gs_free(uint64_t ptr) {
  if (ptr != 0)
    free((void *)(uintptr_t)ptr);
}