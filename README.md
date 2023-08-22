# ULID

Zig implementation of [ULID](https://github.com/ulid/spec).


`build.zig.zon`
```
      .ulid = .{
        .url = "https://api.github.com/repos/rsepassi/ulid/tarball/ea92821",
        .hash = "",
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
```

```
// On an M1 Mac
zig build benchmark
ids/s=26915455.19
encodes/s=141351087.41
binencodes/s=629838736.09
decodes/s=46610268.24
bindecodes/s=1047668936.62
```

```
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

        // Binary encode/decode (simple bitCast)
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
