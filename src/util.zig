const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

pub fn repack(allocator: Allocator, comptime NewSize: type, comptime OldSize: type, input: []const OldSize) ![]NewSize {
    comptime assert(@sizeOf(NewSize) % @sizeOf(OldSize) == 0);
    const factor = @sizeOf(NewSize) / @sizeOf(OldSize);
    comptime assert(factor >= 1);
    const length = input.len / factor;

    var array = try allocator.alloc(NewSize, length);
    errdefer allocator.free(array); // if a runtime error occurs free this guy

    // enumerate over the length of the newly calcuated array
    for (0..length) |i| {
        // create a slice representing the bytes to convert to the new type
        const int_array = input[(i * factor) .. (i * factor) + factor];
        array[i] = 0;
        // for each item of the slice, left shift the new bytes to the new alignment
        // and bit-or with the existing bytes
        for (int_array, 1..) |a, j| {
            const wide: NewSize = @as(NewSize, @intCast(a)) << @intCast(@bitSizeOf(NewSize) - (j * @bitSizeOf(OldSize)));
            array[i] |= wide;
        }
    }

    return array;
}

test "repack test" {
    const in = [_]u8{ 0xAA, 0xBB, 0xCC, 0xDD };
    inline for ([_]type{ u8, u16, u32 }) |t| {
        const out = try repack(std.testing.allocator, t, u8, &in);
        defer std.testing.allocator.free(out);
        try switch (t) {
            u8 => expect(out[0] == 0xAA),
            u16 => expect(out[0] == 0xAABB),
            u32 => expect(out[0] == 0xAABBCCDD),
            else => unreachable,
        };
    }
}
