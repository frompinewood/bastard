const std = @import("std");
const util = @import("util.zig");
const VM = @import("vm.zig").VM;
const allocator = std.heap.page_allocator;

const MAXSIZE = 0x10000;

pub fn main() !void {
    var args = std.process.args();
    const bin_name = args.next(); // ignore the name of the program
    const maybe_filename = args.next();
    if (maybe_filename) |filename| {
        const bytes = std.fs.cwd().readFileAlloc(allocator, filename, MAXSIZE) catch |err| {
            switch (err) {
                error.FileNotFound => std.debug.print("File not found: {s}\n", .{filename}),
                else => std.debug.print("Something bad.\n", .{}),
            }
            std.process.exit(1);
        };
        var vm = VM(u16).init(allocator);
        defer vm.deinit();
        const new_bytes = try util.repack(allocator, u16, u8, bytes);
        if (new_bytes) |b| {
            defer allocator.free(b);
            try vm.spawn(b);
        } else {
            std.debug.print("Failed to repackage bytes\n", .{});
            std.process.exit(1);
        }
    } else {
        std.debug.print("usage: {s} <filename>\n", .{bin_name.?});
    }
}
