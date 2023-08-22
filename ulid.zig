// https://github.com/ulid/spec#specification

const std = @import("std");

const Alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
comptime {
    if (Alphabet.len != 32) @compileError("Bad alphabet");
}
pub const binary_length = 16;
pub const text_length = 26;
const text_time_bytes = 10;
const text_rand_bytes = 16;

fn alphaIdx(c: u8) ?u8 {
    return switch (c) {
        // inline 0...47 => null,
        inline '0'...'9' => |i| i - 48,
        // inline 58...64 => null,
        inline 'A'...'H' => |i| i - 65 + 10,
        // inline 'I' => null,
        inline 'J'...'K' => |i| i - 65 + 10 - 1,
        // inline 'L' => null,
        inline 'M'...'N' => |i| i - 65 + 10 - 2,
        // inline 'O' => null,
        inline 'P'...'T' => |i| i - 65 + 10 - 3,
        // inline 'U' => null,
        inline 'V'...'Z' => |i| i - 65 + 10 - 4,
        // inline 91...255 => null,
        inline else => null,
    };
}

const UlidC = extern struct {
    combined: u128,
    fn fromUlid(ulid: Ulid) @This() {
        return @bitCast(ulid);
    }
    fn toUlid(self: @This()) Ulid {
        return @bitCast(self);
    }
};

pub const Ulid = packed struct {
    time: u48,
    rand: u80,

    pub fn bytes(self: @This()) [binary_length]u8 {
        return @bitCast(self);
    }

    pub fn fromBytes(buf: []const u8) !@This() {
        if (buf.len != binary_length) return error.UlidBufWrongSize;
        const bufl = buf[0..binary_length].*;
        return @bitCast(bufl);
    }

    pub fn encode(self: @This()) [text_length]u8 {
        var out: [text_length]u8 = undefined;
        self.encodeBuf(&out) catch unreachable;
        return out;
    }

    pub fn encodeAlloc(self: @This(), allocator: std.mem.Allocator) ![]u8 {
        var out = try allocator.alloc(u8, text_length);
        self.encodeBuf(out) catch unreachable;
        return out;
    }

    pub fn encodeBuf(self: @This(), out: []u8) !void {
        if (out.len != text_length) return error.UlidBufWrongSize;

        // encode time
        {
            const base: u48 = Alphabet.len;
            var trem: u48 = self.time;

            inline for (0..text_time_bytes) |i| {
                const val = @rem(trem, base);
                trem >>= 5;
                out[text_time_bytes - 1 - i] = Alphabet[@intCast(val)];
            }
        }

        // encode rand
        {
            const base: u80 = Alphabet.len;
            var rrem: u80 = self.rand;

            inline for (0..text_rand_bytes) |i| {
                const val = @rem(rrem, base);
                rrem >>= 5;
                out[text_time_bytes + text_rand_bytes - 1 - i] = Alphabet[@intCast(val)];
            }
        }
    }

    pub fn decode(s: []const u8) !@This() {
        if (s.len != text_length) return error.UlidDecodeWrongSize;

        var time: u48 = 0;
        inline for (0..text_time_bytes) |i| {
            const maybe_idx = alphaIdx(s[i]);
            if (maybe_idx) |idx| {
                time |= @as(u48, @intCast(idx)) << @as(u48, @intCast(5 * (text_time_bytes - 1 - i)));
            } else {
                return error.UlidDecodeBadChar;
            }
        }

        var rand: u80 = 0;
        inline for (0..text_rand_bytes) |i| {
            const maybe_idx = alphaIdx(s[text_time_bytes + i]);
            if (maybe_idx) |idx| {
                rand |= @as(u80, @intCast(idx)) << @as(u80, @intCast(5 * (text_rand_bytes - 1 - i)));
            } else {
                return error.UlidDecodeBadChar;
            }
        }

        return .{ .time = time, .rand = rand };
    }

    pub fn equals(self: @This(), other: @This()) bool {
        const s = @as(u128, @bitCast(self));
        const o = @as(u128, @bitCast(other));
        return s == o;
    }

    pub fn format(value: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        _ = try writer.write(&value.encode());
    }
};

pub const Factory = struct {
    r: std.rand.Random = std.crypto.random,
    last: Ulid = .{ .time = 0, .rand = 0 },

    pub fn next(self: *@This()) !Ulid {
        const ms = std.time.milliTimestamp();
        if (ms < 0) return error.UlidTimeTooOld;
        if (ms > std.math.maxInt(u48)) return error.UlidTimeOverflow;
        const ms48: u48 = @intCast(ms);

        if (ms48 == self.last.time) {
            if (self.last.rand == std.math.maxInt(u80)) return error.UlidRandomOverflow;
            self.last.rand += 1;
        } else {
            self.last.time = ms48;
            self.last.rand = self.r.int(u80);
        }

        return self.last;
    }
};

export fn ulid_factory() ?*anyopaque {
    var factory = std.heap.c_allocator.create(Factory) catch {
        return null;
    };
    factory.* = Factory{};
    return factory;
}

export fn ulid_next(factoryv: *anyopaque) UlidC {
    const factory: *Factory = @ptrCast(@alignCast(factoryv));
    const ulid = factory.next() catch {
        return .{ .combined = 0 };
    };
    return UlidC.fromUlid(ulid);
}

threadlocal var tls_factory: ?*Factory = null;

pub fn next() !Ulid {
    if (tls_factory == null) {
        tls_factory = std.heap.c_allocator.create(Factory) catch unreachable;
        tls_factory.?.* = .{};
    }
    return tls_factory.?.next();
}

fn ulid_raw() callconv(.C) UlidC {
    const ulid = next() catch {
        return .{ .combined = 0 };
    };
    return UlidC.fromUlid(ulid);
}
comptime {
    @export(ulid_raw, .{ .name = "ulid" });
}

export fn ulid_encode(ulidc: UlidC, buf: [*]u8) void {
    const ulid = ulidc.toUlid();
    const bufl = buf[0..text_length];
    bufl.* = ulid.encode();
}

export fn ulid_equals(ulid0: UlidC, ulid1: UlidC) bool {
    return ulid0.combined == ulid1.combined;
}

export fn ulid_decode(buf: [*]const u8) UlidC {
    const ulid = Ulid.decode(buf[0..text_length]) catch {
        return .{ .combined = 0 };
    };
    return UlidC.fromUlid(ulid);
}

export fn ulid_timestamp_ms(ulid: UlidC) i64 {
    return ulid.toUlid().time;
}

test "c" {
    var factory = ulid_factory().?;
    const id0 = ulid_next(factory);
    var buf = try std.testing.allocator.alloc(u8, text_length);
    defer std.testing.allocator.free(buf);
    var buf_ptr: [*]u8 = @ptrCast(buf);
    ulid_encode(id0, buf_ptr);
    try std.testing.expectEqual(ulid_decode(buf_ptr), id0);
}

test "ulid" {
    var factory = Factory{};

    _ = try factory.next();
    const id0 = try factory.next();
    const id1 = try factory.next();

    // timestamp 48 bits
    try std.testing.expectEqual(@bitSizeOf(@TypeOf(id0.time)), 48);
    // randomness 80 bits
    try std.testing.expectEqual(@bitSizeOf(@TypeOf(id0.rand)), 80);
    // timestamp is milliseconds since unix epoch
    try std.testing.expect((std.time.milliTimestamp() - id0.time) < 10);

    // uses crockford base32 alphabet
    const str = id0.encode();
    try std.testing.expectEqual(str.len, text_length);
    for (0..str.len) |i| {
        try std.testing.expect(std.mem.indexOf(u8, Alphabet, str[i .. i + 1]) != null);
    }
    try std.testing.expectEqualDeep(try Ulid.decode(&str), id0);
    const str_alloc = try id0.encodeAlloc(std.testing.allocator);
    defer std.testing.allocator.free(str_alloc);
    try std.testing.expect(std.mem.eql(u8, str_alloc, &str));

    // monotonic in the same millisecond
    try std.testing.expectEqual(id0.time, id1.time);
    try std.testing.expect(id0.rand != id1.rand);
    try std.testing.expectEqual(id0.rand + 1, id1.rand);

    // binary encodable
    const bytes = id0.bytes();
    const time_bytes = bytes[0..6].*;
    const rand_bytes = bytes[6..].*;
    try std.testing.expectEqual(@as(u48, @bitCast(time_bytes)), id0.time);
    try std.testing.expectEqual(@as(u80, @bitCast(rand_bytes)), id0.rand);
    try std.testing.expect((try Ulid.fromBytes(&bytes)).equals(id0));
}
