# ULID

Zig implementation of [ULID](https://github.com/ulid/spec).

`build.zig.zon`
```
.ulid = .{
  .url = "https://api.github.com/repos/rsepassi/ulid-zig/tarball/8c8789e",
  .hash = "12209ad26e7a3bcc420f86f1533c4462794efbcdbd26f49b7d4db9569d01addb0636",
},
```

```
zig build

// CLI
NEW_ID=$(./zig-out/bin/ulid)
echo $NEW_ID

// C library
ls zig-out/lib/libulid.a
ls zig-out/include/ulid.h
zig cc ulid.c -Lzig-out/lib -Izig-out/include -lulid -lc -O3 -o ulid
./ulid
```

Tests and benchmark:
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

```zig
// ulid_example.zig

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

## Implementation notes

* The `Ulid` struct is packed such that it is trivially bit-castable to `u128` or `[16]u8`.
* Uses inline for loops in encode and decode, and an inline switch for the
  base32 alphabet decoding.
