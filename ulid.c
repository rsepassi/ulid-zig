#include "ulid.h"

#include <stdio.h>

int main() {
  // Generate
  UlidFactory factory = ulid_factory();
  Ulid u = ulid_next(factory);

  // Encode
  uint8_t encoded[ULID_TEXT_LENGTH + 1] = {0};
  encoded[26] = 0;
  ulid_encode(u, encoded);

#ifndef TEST
  printf("%s", encoded);
#endif

  // Test
#ifdef TEST
#define ASSERT(cond) if (!(cond)) { printf("bad\n"); return 1; }
  Ulid decoded = ulid_decode(encoded);
  ASSERT(ulid_equals(u, decoded));
  ASSERT(ulid_equals(u, u));
  ASSERT(!ulid_equals(ulid(), decoded) && !ulid_equals(ulid(), ulid()));
  int64_t ts = ulid_timestamp_ms(u);
  ASSERT(ts >= 0);
#endif

  return 0;
}
