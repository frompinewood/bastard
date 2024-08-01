const std = @import("std");
const status = @import("engine.zig").status;
const Engine = @import("engine.zig").Engine;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

pub fn Process(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        stack: ArrayList(T),
        heap: []T = undefined,
        pc: usize = 0,
        id: usize,

        pub fn init(allocator: Allocator, mem: []const T, id: usize) !Self {
            const p = Self{ .allocator = allocator, .stack = ArrayList(T).init(allocator), .heap = try allocator.alloc(T, mem.len), .pc = 0, .id = id };
            @memcpy(p.heap, mem);
            return p;
        }

        pub fn deinit(self: *Self) void {
            self.stack.deinit();
            self.allocator.free(self.heap);
        }

        pub fn next(self: *Self) T {
            if (self.pc >= self.heap.len) {
                self.pc = 0;
            }
            const inst = self.heap[self.pc];
            self.pc += 1;
            return inst;
        }

        pub fn push(self: *Self, val: T) !void {
            try self.stack.append(val);
        }

        pub fn pop(self: *Self) T {
            return self.stack.pop();
        }

        pub fn cycle(self: *Self, engine: anytype) status {
            return engine.step(self);
        }
    };
}

test "process stack" {
    const SmallProc = Process(u8);
    var proc = try SmallProc.init(std.testing.allocator, &[_]u8{}, 0);
    defer proc.deinit();

    try proc.push(1);
    try expect(1 == proc.pop());
}

test "process heap" {
    const some_bytes = [_]u8{ 0xFF, 0xFA, 0xAA };
    var proc = try Process(u8).init(std.testing.allocator, &some_bytes, 0);
    defer proc.deinit();
    try expect(proc.heap[0] == 0xFF);
    try expect(proc.heap[1] == 0xFA);
    try expect(proc.heap[2] == 0xAA);
    try expect(proc.heap.len == 3);
}

test "cycle test" {
    const Type = Process(u8);
    var proc = try Type.init(std.testing.allocator, &[_]u8{ 0x00, 0x00, 0x00 }, 0);
    defer proc.deinit();
    _ = proc.cycle(Engine(u8){});
}
