const std = @import("std");
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

        pub fn push(self: *Self, val: T) !void {
            try self.stack.append(val);
        }

        pub fn pop(self: *Self) T {
            return self.stack.pop();
        }

        // increments the program counter and returns the next instruction
        // loops on heap overflow
        pub fn step(self: *Self) T {
            const inst = self.heap[self.pc];
            self.pc += 1;
            if (self.pc == self.heap.len) self.pc = 0;
            return inst;
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

test "step" {
    var proc = try Process(u8).init(std.testing.allocator, &[_]u8{ 0x10, 0x11, 0x12, 0x13 }, 0);
    defer proc.deinit();
    try expect(proc.step() == 0x10);
    try expect(proc.step() == 0x11);
    try expect(proc.step() == 0x12);
    try expect(proc.step() == 0x13);
}
test "step overflow" {
    var proc = try Process(u8).init(std.testing.allocator, &[_]u8{ 0x10, 0x11, 0x12, 0x13 }, 0);
    defer proc.deinit();
    try expect(proc.step() == 0x10);
    try expect(proc.step() == 0x11);
    try expect(proc.step() == 0x12);
    try expect(proc.step() == 0x13);
    try expect(proc.step() == 0x10);
}
