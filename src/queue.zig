const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const expect = testing.expect;

pub fn Queue(comptime T: type) type {
    return struct {
        const Node = struct { value: T, next: ?*@This() };
        const Self = @This();

        allocator: Allocator,
        head: ?*Node,
        tail: ?*Node,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .allocator = allocator,
                .head = null,
                .tail = null,
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.head != null) {
                const node = self.head.?.next;
                self.allocator.destroy(self.head.?);
                self.head = node;
            }
        }

        pub fn is_empty(self: Self) bool {
            return self.head == null;
        }

        pub fn push(self: *Self, value: T) !void {
            var node = try self.allocator.create(Node);
            node.value = value;
            node.next = null;

            if (self.tail == null) {
                self.tail = node;
                self.head = node;
            } else {
                self.tail.?.next = node;
                self.tail = node;
            }
        }

        pub fn pop(self: *Self) !T {
            if (self.head != null) {
                const node = self.head;
                const value = node.?.value;
                self.head = self.head.?.next;
                self.allocator.destroy(node.?);
                if (self.head == null) self.tail = null;
                return value;
            } else {
                return error.EmptyQueue;
            }
        }
    };
}

test "is_empty" {
    var queue = Queue(u8).init(testing.allocator);
    defer queue.deinit();
    try expect(queue.is_empty());
}

test "not is_empty" {
    var queue = Queue(u8).init(testing.allocator);
    defer queue.deinit();
    try queue.push(1);
    try expect(!queue.is_empty());
}

test "push" {
    var queue = Queue(u8).init(testing.allocator);
    defer queue.deinit();
    try queue.push(1);
    try queue.push(2);
}

test "pop" {
    var queue = Queue(u8).init(testing.allocator);
    // not using deinit because we're manually popping each item off the list
    try queue.push(1);
    try queue.push(2);
    try expect(1 == try queue.pop());
    try expect(2 == try queue.pop());
}
