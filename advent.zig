const std = @import("std");
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const fmt = std.fmt;
const Tuple = std.meta.Tuple;
var arena: heap.ArenaAllocator = undefined;
var allocator: mem.Allocator = undefined;

pub fn allocator_init(child: std.mem.Allocator) mem.Allocator {
    arena = heap.ArenaAllocator.init(child);
    allocator = arena.allocator();
    return allocator;
}

pub fn allocator_deinit() void {
    arena.deinit();
}

pub fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(
        buffer,
        '\n',
    )) orelse return null;
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}

pub fn readlines(reader: anytype) !std.ArrayList([]u8) {
    var buff: [512]u8 = undefined;
    var lines = std.ArrayList([]u8).init(allocator);
    while (true) {
        const contents = try nextLine(reader, &buff) orelse break;
        const line = try allocator.dupe(u8, contents);
        try lines.append(line);
    }
    return lines;
}

pub fn inRange(comptime T: type, n: T, min: T, max: T) bool {
    return n >= min and n <= max;
}
