#include <stdint.h>
#include <stdbool.h>

typedef struct Ulid {
  uint8_t combined[16];
} Ulid;

// Produces new Ulids using a thread-local UlidFactory
Ulid ulid();

// Produces new Ulids using an explicit factory
typedef void* UlidFactory;
UlidFactory ulid_factory();
Ulid ulid_next(UlidFactory);

#define ULID_TEXT_LENGTH 26

// base32-encodes Ulid into the provided buffer
// The first ULID_TEXT_LENGTH bytes will be filled in
void ulid_encode(Ulid, uint8_t*);

// Decodes base32-encoded string
// The first ULID_TEXT_LENGTH will be decoded
Ulid ulid_decode(uint8_t*);

// Are the 2 Ulids equal to one another?
bool ulid_equals(Ulid, Ulid);

// Extracts the timestamp from the Ulid
int64_t ulid_timestamp_ms(Ulid);
