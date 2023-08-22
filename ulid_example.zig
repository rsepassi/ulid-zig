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
