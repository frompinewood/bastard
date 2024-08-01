const std = @import("std");
const Process = @import("process.zig").Process;
const expect = std.testing.expect;

pub const status = enum { ok, dead };

pub fn Engine(comptime T: type) type {
    return struct {
        const Self = @This();

        pub fn step(_: Self, process: *Process(T)) status {
            const inst = process.next();
            std.debug.print("PID: {d} 0x{X}\n", .{ process.id, inst });
            return switch (inst) {
                0xFF => .dead,
                else => .ok,
            };
        }
    };
}
