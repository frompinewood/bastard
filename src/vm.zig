const std = @import("std");
const ArrayList = std.ArrayList;
const Process = @import("process.zig").Process;
const Engine = @import("engine.zig").Engine;
const Allocator = std.mem.Allocator;

const Config = struct {
    field_size: type,
    allocator: Allocator,
};

pub fn VM(comptime config: Config) type {
    return struct {
        const T = config.field_size;
        const Self = @This();
        const allocator = config.allocator;

        ready: ArrayList(Process(T)),
        engine: Engine(T),
        proc_count: usize = 0,

        pub fn init() Self {
            return Self{ .ready = ArrayList(Process(config.field_size)).init(allocator), .engine = Engine(T){} };
        }

        pub fn spawn(self: *Self, data: []const T) !void {
            try self.ready.append(try Process(T).init(allocator, data, self.proc_count));
            self.proc_count += 1;
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
    var vm = VM(Config{ .field_size = u8, .allocator = std.testing.allocator }).init();
    defer vm.deinit();
}

test "add process" {
    var vm = VM(Config{ .field_size = u8, .allocator = std.testing.allocator }).init();
    defer vm.deinit();
    try vm.spawn(&[_]u8{ 0x11, 0x00 });
}

test "step" {
    var vm = VM(Config{ .field_size = u8, .allocator = std.testing.allocator }).init();
    defer vm.deinit();
    try vm.spawn(&[_]u8{ 0x0F, 0x00, 0xAF, 0xFF });
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step(); // out of steps but BREAK occurred in test engine
}

test "multi step" {
    var vm = VM(Config{ .field_size = u8, .allocator = std.testing.allocator }).init();
    defer vm.deinit();
    try vm.spawn(&[_]u8{ 0xBF, 0x00, 0xAF, 0xFF });
    try vm.spawn(&[_]u8{ 0xAA, 0xCA, 0xFF });
    std.debug.print("start\n", .{});
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    try vm.step();
    std.debug.print("end\n", .{});
}
