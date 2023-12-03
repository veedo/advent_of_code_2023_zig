const std = @import("std");

var arena: std.heap.ArenaAllocator = undefined;
var allocator: std.mem.Allocator = undefined;

pub fn main() !void {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    allocator = arena.allocator();

    const stdin_file = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_file);
    const stdin = br.reader();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var lines = try readlines(stdin);
    var sum: u32 = 0;
    for (lines.items) |line| {
        const digits = try get_wrapping_digits(line);
        sum += (digits[0] orelse 0) * 10 + (digits[1] orelse 0);
    }

    try stdout.print("{d}\n", .{sum});
    try bw.flush();
}

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
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
    var buff: [100]u8 = undefined;
    var lines = std.ArrayList([]u8).init(allocator);
    while (true) {
        const contents = try nextLine(reader, &buff) orelse break;
        std.debug.print("contents: {s}\n", .{contents});
        const line = try allocator.dupe(u8, contents);
        try lines.append(line);
    }
    return lines;
}

pub fn get_word_number(string: []u8) ?u8 {
    switch (string[0]) {
        'z' => if (std.mem.eql(u8, "zero", string[0..@min(4, string.len)]))
            return 0,
        'o' => if (std.mem.eql(u8, "one", string[0..@min(3, string.len)]))
            return 1,
        't' => if (std.mem.eql(u8, "two", string[0..@min(3, string.len)]))
            return 2
        else if (std.mem.eql(u8, "three", string[0..@min(5, string.len)]))
            return 3,
        'f' => if (std.mem.eql(u8, "four", string[0..@min(4, string.len)]))
            return 4
        else if (std.mem.eql(u8, "five", string[0..@min(4, string.len)]))
            return 5,
        's' => if (std.mem.eql(u8, "six", string[0..@min(3, string.len)]))
            return 6
        else if (std.mem.eql(u8, "seven", string[0..@min(5, string.len)]))
            return 7,
        'e' => if (std.mem.eql(u8, "eight", string[0..@min(5, string.len)]))
            return 8,
        'n' => if (std.mem.eql(u8, "nine", string[0..@min(4, string.len)]))
            return 9,
        else => return null,
    }
    return null;
}

const Tuple = std.meta.Tuple;
pub fn get_wrapping_digits(string: []u8) !Tuple(&.{ ?u8, ?u8 }) {
    const first_digit: ?u8 = outer: for (string, 0..) |char, i| {
        const k: usize = @intCast(i);
        switch (char) {
            '0'...'9' => break :outer char - '0',
            else => break :outer get_word_number(string[k..]) orelse continue,
        }
    } else null;

    var i: isize = @intCast(string.len - 1);
    const last_digit: ?u8 = outer: while (i >= 0) : (i -= 1) {
        const k: usize = @intCast(i);
        const char = string[k];
        switch (char) {
            '0'...'9' => break :outer char - '0',
            else => break :outer get_word_number(string[k..]) orelse continue,
        }
    } else null;

    return .{ first_digit, last_digit };
}

test "parse test" {
    const exampletext =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    allocator = arena.allocator();

    var readfile = std.ArrayList(u8).init(std.testing.allocator);
    defer readfile.deinit();

    try readfile.writer().writeAll(exampletext);
    var fbs = std.io.fixedBufferStream(readfile.items);
    var lines = try readlines(fbs.reader());
    std.debug.print("lines: {any}\n", .{lines.items});
    var sum: u32 = 0;
    for (lines.items) |line| {
        std.debug.print("item: {s}\n", .{line});
        const digits = try get_wrapping_digits(line);
        std.debug.print("lines: {any}\n", .{digits});
        sum += (digits[0] orelse 0) * 10 + (digits[1] orelse 0);
    }

    try std.testing.expect(sum == 142);
}

test "parse part two" {
    const exampletext =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    allocator = arena.allocator();

    var readfile = std.ArrayList(u8).init(std.testing.allocator);
    defer readfile.deinit();

    try readfile.writer().writeAll(exampletext);
    var fbs = std.io.fixedBufferStream(readfile.items);
    var lines = try readlines(fbs.reader());
    std.debug.print("lines: {any}\n", .{lines.items});
    var sum: u32 = 0;
    for (lines.items) |line| {
        std.debug.print("item: {s}\n", .{line});
        const digits = try get_wrapping_digits(line);
        std.debug.print("lines: {any}\n", .{digits});
        sum += (digits[0] orelse 0) * 10 + (digits[1] orelse 0);
    }

    try std.testing.expectEqual(sum, 281);
}
