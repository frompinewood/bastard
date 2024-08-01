const std = @import("std");
const ArrayList = std.ArrayList;
const Process = @import("process.zig").Process;
const Engine = @import("engine.zig").Engine;
const Allocator = std.mem.Allocator;

pub fn VM(comptime T: type) type {
    return struct {
        const Self = @This();

        ready: ArrayList(Process(T)),
        engine: Engine(T),
        count: usize = 0,
        allocator: Allocator = undefined,

        pub fn init(allocator: Allocator) Self {
            return Self{ .ready = ArrayList(Process(T)).init(allocator), .engine = Engine(T){}, .allocator = allocator };
        }

        pub fn spawn(self: *Self, data: []const T) !void {
            try self.ready.append(try Process(T).init(self.allocator, data, self.count));
            self.count += 1;
        }

        pub fn deinit(self: *Self) void {
            for (self.ready.items) |*p| {
                p.deinit();
            }
            self.ready.deinit();
        }

        pub fn step(self: *Self) !void {
            if (self.ready.items.len > 0) {
                var proc = self.ready.pop();
                switch (proc.cycle(self.engine)) {
                    .ok => try self.ready.insert(0, proc),
                    else => proc.deinit(),
                }
            }
        }
    };
}

test "new vm" {
    var vm = VM(u8).init(std.testing.allocator);
    defer vm.deinit();
}

test "add process" {
    var vm = VM(u8).init(std.testing.allocator);
    defer vm.deinit();
    try vm.spawn(&[_]u8{ 0x11, 0x00 });
}

test "step" {
    var vm = VM(u8).init(std.testing.allocator);
    defer vm.deinit();
    try vm.spawn(&[_]u8{ 0x0F, 0x00, 0xAF, 0xFF });
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step(); // out of steps but BREAK occurred in test engine
}

test "multi step" {
    var vm = VM(u8).init(std.testing.allocator);
    defer vm.deinit();
    try vm.spawn(&[_]u8{ 0xBF, 0x00, 0xAF, 0xFF });
    try vm.spawn(&[_]u8{ 0xAA, 0xCA, 0xFF });
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
}
