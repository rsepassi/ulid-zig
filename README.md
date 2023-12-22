# `ulid-zig`

Zig implementation of Universally Unique Lexicographically Sortable Identifiers ([ULIDs](https://github.com/ulid/spec)).

---

[![test](https://github.com/rsepassi/ulid-zig/actions/workflows/zig.yml/badge.svg)][ci]

*[Tested][ci] weekly and on push on Windows, Linux, Mac with Zig v0.11.0.
Irregularly tested with Zig master (last verified to work with
0.12.0-dev.1836+dd189a354).*

---

Depend

`build.zig.zon`
```zig
.ulid = .{
  .url = "https://api.github.com/repos/rsepassi/ulid-zig/tarball/v0.4.0",
  .hash = "...",
},
```

`build.zig`
```zig
const ulid = b.dependency("ulid", .{}).module("ulid");
my_lib.addModule("ulid", ulid);
```
---
Usage
```zig
const ulid = @import("ulid");

// Generate id
const id = try ulid.next();

// Access timestamp and random components
_ = id.time;
_ = id.rand;

// base32 encode/decode
const encoded = id.encode();
const decoded = try ulid.Ulid.decode(&encoded);

// binary encode/decode
const bencoded = id.bytes();
const bdecoded = try ulid.Ulid.fromBytes(&bencoded);

// base32 string formatting
std.debug.print("{s}\n", .{id});

// Optionally use an explicit factory
var factory = ulid.Factory{};
const id = try factory.next();
```

---

Build

```bash
zig build

// CLI
alias ulid=$PWD/zig-out/bin/ulid
NEW_ID=$(ulid)
echo $NEW_ID

// C library
ls zig-out/lib/libulid.a
ls zig-out/include/ulid.h

// Example usage of the C library
zig cc ulid.c -Lzig-out/lib -Izig-out/include -lulid -lc -O3 -o ulid
./ulid
```

---

Test
```
zig build test
```
---
Benchmark

```
// On an M1 Mac
zig build benchmark
ids/s=26915455.19
encodes/s=141351087.41
binencodes/s=629838736.09
decodes/s=46610268.24
bindecodes/s=1047668936.62
```
---

Implementation notes

* The `Ulid` struct is packed such that it is trivially bit-castable to `u128` or `[16]u8`.
* Uses inline for loops in encode and decode, and a comptime-constructed lookup table for
  base32 alphabet decoding (thanks to @travisstaloch).
* Uses `std.crypto.random` by default, a cryptographically secure PRNG.
* Implements monotonic sort order (correctly detects and handles the same
  millisecond) per `Factory`.

---

Possible future work, pull requests welcome:

* Explore SIMD encode/decode
* Wrap for SQLite usage ([`sqlite3_create_function`](https://www.sqlite.org/c3ref/create_function.html))


[ci]: https://github.com/rsepassi/ulid-zig/actions/workflows/zig.yml?query=branch%3Amain
