const std = @import("std");
const VM = @import("vm.zig").VM;

pub fn main() !void {
    var vm = VM(u16).init(std.heap.page_allocator);
    defer vm.deinit();
}
