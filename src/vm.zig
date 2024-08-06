const std = @import("std");
const ArrayList = std.ArrayList;
const Process = @import("process.zig").Process;
const Queue = @import("queue.zig").Queue;
const Allocator = std.mem.Allocator;

pub fn VM(comptime T: type) type {
    return struct {
        const Self = @This();

        ready: Queue(Process(T)),
        count: usize = 0,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return Self{ .ready = Queue(Process(T)).init(allocator), .allocator = allocator };
        }

        pub fn spawn(self: *Self, data: []const T) !void {
            try self.ready.push(try Process(T).init(self.allocator, data, self.count));
            self.count += 1;
        }

        pub fn deinit(self: *Self) void {
            while (!self.ready.is_empty()) {
                var p = self.ready.pop().?;
                p.deinit();
            }
            self.ready.deinit();
        }
    };
}

test "new vm" {
    var vm = VM(u8).init(std.testing.allocator);
    defer vm.deinit();
}

test "spawn process" {
    var vm = VM(u8).init(std.testing.allocator);
    defer vm.deinit();
    try vm.spawn(&[_]u8{ 0x11, 0x00 });
}
