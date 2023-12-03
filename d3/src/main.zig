const std = @import("std");
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const Tuple = std.meta.Tuple;
var arena: std.heap.ArenaAllocator = undefined;
var allocator: std.mem.Allocator = undefined;

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

fn readlines(reader: anytype) !std.ArrayList([]u8) {
    var buff: [512]u8 = undefined;
    var lines = std.ArrayList([]u8).init(allocator);
    while (true) {
        const contents = try nextLine(reader, &buff) orelse break;
        const line = try allocator.dupe(u8, contents);
        try lines.append(line);
    }
    return lines;
}

pub fn main() !void {
    arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    allocator = arena.allocator();
    const stdin_file = io.getStdIn().reader();
    var br = io.bufferedReader(stdin_file);
    const stdin = br.reader();
    const stdout_file = io.getStdOut().writer();
    var bw = io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    var lines = try readlines(stdin);
    var grid = lines.items;
    const sum = partNumberSum(grid);
    try stdout.print("\n{d}\n", .{sum});

    try bw.flush();
}

fn isSymbol(char: u8) bool {
    switch (char) {
        '.', '0'...'9' => return false,
        else => return true,
    }
}
fn isNumber(char: u8) bool {
    switch (char) {
        '0'...'9' => return true,
        else => return false,
    }
}

const ExpandoNumbo = struct {
    number: usize,
    xstart: usize,
    xend: usize,
};
fn expandNumber(row: []const u8, x: usize) ExpandoNumbo {
    std.debug.print("{s} - {d}\n", .{ row, x });
    var xstart = x;
    var xend = x;
    var i = x;
    xstart = while (i >= 0) : (i -= 1) {
        //std.debug.print("i={d},r={c},t={any}\n", .{ i, row[i], isNumber(row[i]) });
        const isn = isNumber(row[i]);
        if (i == 0 and !isn) break 1;
        if (i == 0 and isn) break 0;
        if (isn) continue else break i + 1;
    } else 0;
    i = x;
    xend = while (i < row.len) : (i += 1) {
        if (isNumber(row[i])) continue else break i - 1;
    } else row.len - 1;
    const number = std.fmt.parseInt(usize, row[xstart .. xend + 1], 10) catch 0;
    return ExpandoNumbo{ .number = number, .xstart = xstart, .xend = xend };
}

fn partNumberSum(grid: [][]u8) usize {
    var partsum: usize = 0;
    for (grid, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (isSymbol(cell)) {
                const searchxs = [_]usize{ x, (std.math.sub(usize, x, 1) catch x), x + 1 };
                const searchys = [_]usize{ y, (std.math.sub(usize, y, 1) catch y), y + 1 };
                for (searchys) |sy| {
                    for (searchxs) |sx| {
                        if ((!(sx == x and sy == y)) and isNumber(grid[sy][sx])) {
                            //std.debug.print("x{d}y{d}\n", .{ sx, sy });
                            var num: ExpandoNumbo = expandNumber(grid[sy], sx);
                            //std.debug.print("num:{any}\n", .{num});

                            partsum += num.number;
                            @memset(grid[sy][num.xstart .. num.xend + 1], '.');
                        }
                    }
                }
            }
        }
    }
    return partsum;
}

test "expando works" {
    {
        var row = "...1234....";
        var result = expandNumber(row[0..], 5);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 3, .xend = 6 }, result);
        result = expandNumber(row[0..], 3);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 3, .xend = 6 }, result);
        result = expandNumber(row[0..], 6);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 3, .xend = 6 }, result);
    }
    {
        var row = "1234....";
        var result = expandNumber(row[0..], 2);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 0, .xend = 3 }, result);
        result = expandNumber(row[0..], 0);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 0, .xend = 3 }, result);
        result = expandNumber(row[0..], 3);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 0, .xend = 3 }, result);
    }
    {
        var row = ".1234....";
        var result = expandNumber(row[0..], 2);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 1, .xend = 4 }, result);
        result = expandNumber(row[0..], 1);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 1, .xend = 4 }, result);
        result = expandNumber(row[0..], 4);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 1, .xend = 4 }, result);
    }
    {
        var row = ".....1234";
        var result = expandNumber(row[0..], 6);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 5, .xend = 8 }, result);
        result = expandNumber(row[0..], 5);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 5, .xend = 8 }, result);
        result = expandNumber(row[0..], 8);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 5, .xend = 8 }, result);
    }
    {
        var row = ".....1234.";
        var result = expandNumber(row[0..], 6);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 5, .xend = 8 }, result);
        result = expandNumber(row[0..], 5);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 5, .xend = 8 }, result);
        result = expandNumber(row[0..], 8);
        try std.testing.expectEqual(ExpandoNumbo{ .number = 1234, .xstart = 5, .xend = 8 }, result);
    }
}

test "part1 test" {
    const exampletext =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    std.debug.print("\n", .{});
    arena = heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    allocator = arena.allocator();
    var readfile = std.ArrayList(u8).init(std.testing.allocator);
    defer readfile.deinit();
    try readfile.writer().writeAll(exampletext);
    var fbs = io.fixedBufferStream(readfile.items);
    var lines = try readlines(fbs.reader());
    var grid = lines.items;
    const sum = partNumberSum(grid);
    try std.testing.expectEqual(sum, 4361);
}
