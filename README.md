# ULID

[![test](https://github.com/rsepassi/ulid-zig/actions/workflows/zig.yml/badge.svg)](https://github.com/rsepassi/ulid-zig/actions/workflows/zig.yml)

Zig implementation of Universally Unique Lexicographically Sortable Identifiers ([ULIDs](https://github.com/ulid/spec)).

---

`build.zig.zon`
```
.ulid = .{
  .url = "https://api.github.com/repos/rsepassi/ulid-zig/tarball/v0.2.0",
  .hash = "1220f18ca3266e17936aa33af496849d12beb8050c016eeed7fd43b38a2ab65af99f",
},
```

`build.zig`
```
const ulid = b.dependency("ulid", .{}).module("ulid");
my_lib.addModule("ulid", ulid);
```

---

Build

```
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

Tests and benchmark
```
zig build test

// On an M1 Mac
zig build benchmark
ids/s=26915455.19
encodes/s=141351087.41
binencodes/s=629838736.09
decodes/s=46610268.24
bindecodes/s=1047668936.62
```

[CI](https://github.com/rsepassi/ulid-zig/actions/workflows/zig.yml?query=branch%3Amain)
runs on Mac, Windows, and Linux with Zig v0.11.0.

---

`ulid_example.zig`

```zig

const std = @import("std");
const ulid = @import("ulid");

pub fn main() !void {
    {
        // Generate a ULID. Uses a thread-local factory.
        const id = try ulid.next();

        // Access timestamp and random components
        _ = id.time;
        _ = id.rand;

        // base32 encode/decode
        const encoded = id.encode();
        const decoded = try ulid.Ulid.decode(&encoded);
        if (!id.equals(decoded)) {
            unreachable;
        }
        std.debug.print("{s}\n", .{encoded});

        // Binary encode/decode (trivial bitCast)
        const bytes = id.bytes();
        const decoded_b = try ulid.Ulid.fromBytes(&bytes);
        if (!id.equals(decoded_b)) {
            unreachable;
        }

        // Automatic base32 string formatting
        std.debug.print("{s}\n", .{id});
    }

    // Can also use an explicit factory
    {
        var factory = ulid.Factory{};
        const id = try factory.next();
        _ = id;
    }
}
```

---

Implementation notes:

* The `Ulid` struct is packed such that it is trivially bit-castable to `u128` or `[16]u8`.
* Uses inline for loops in encode and decode, and an inline switch for the
  base32 alphabet decoding.
* Uses `std.crypto.random` by default, a cryptographically secure PRNG.
* Implements monotonic sort order (correctly detects and handles the same
  millisecond) per `Factory`.

---

Possible future work, pull requests welcome:

* Explore SIMD encode/decode
* Wrap for SQLite usage ([`sqlite3_create_function`](https://www.sqlite.org/c3ref/create_function.html))
