const std = @import("std");
const ulid = @import("ulid");

pub fn main() !void {
    var factory = ulid.Factory{};
    const allocator = std.heap.page_allocator;
    const num = 1_000_000;

    var ulids = try allocator.alloc(ulid.Ulid, num);
    {
        var timer = try std.time.Timer.start();
        for (0..num) |i| {
            ulids[i] = try factory.next();
        }
        const dur = timer.read();
        std.debug.print("ids/s={d:.2}\n", .{@as(f64, @floatFromInt(num)) * std.time.ns_per_s / @as(f64, @floatFromInt(dur))});
    }

    var strs = try allocator.alloc([ulid.text_length]u8, num);
    {
        var timer = try std.time.Timer.start();
        timer.reset();
        for (0..num) |i| {
            ulids[i].encodeBuf(&strs[i]) catch unreachable;
        }
        const dur = timer.read();
        std.debug.print("encodes/s={d:.2}\n", .{@as(f64, @floatFromInt(num)) * std.time.ns_per_s / @as(f64, @floatFromInt(dur))});
    }

    var bytes = try allocator.alloc([ulid.binary_length]u8, num);
    {
        var timer = try std.time.Timer.start();
        timer.reset();
        for (0..num) |i| {
            bytes[i] = ulids[i].bytes();
        }
        const dur = timer.read();
        std.debug.print("binencodes/s={d:.2}\n", .{@as(f64, @floatFromInt(num)) * std.time.ns_per_s / @as(f64, @floatFromInt(dur))});
    }

    {
        var timer = try std.time.Timer.start();
        timer.reset();
        for (0..num) |i| {
            ulids[i] = try ulid.Ulid.decode(&strs[i]);
        }
        const dur = timer.read();
        std.debug.print("decodes/s={d:.2}\n", .{@as(f64, @floatFromInt(num)) * std.time.ns_per_s / @as(f64, @floatFromInt(dur))});
    }

    {
        var timer = try std.time.Timer.start();
        timer.reset();
        for (0..num) |i| {
            ulids[i] = try ulid.Ulid.fromBytes(&bytes[i]);
        }
        const dur = timer.read();
        std.debug.print("bindecodes/s={d:.2}\n", .{@as(f64, @floatFromInt(num)) * std.time.ns_per_s / @as(f64, @floatFromInt(dur))});
    }
}
