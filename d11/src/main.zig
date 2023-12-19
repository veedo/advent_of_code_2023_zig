const std = @import("std");
const advent = @import("advent.zig");
const readlines = advent.readlines;
const inRange = advent.inRange;
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const fmt = std.fmt;
const Tuple = std.meta.Tuple;
var allocator: std.mem.Allocator = undefined;

pub fn main() !void {
    allocator = advent.allocator_init(heap.page_allocator);
    defer advent.allocator_deinit();
    const stdin_file = io.getStdIn().reader();
    var br = io.bufferedReader(stdin_file);
    const stdin = br.reader();
    const stdout_file = io.getStdOut().writer();
    var bw = io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    _ = stdout;
    var lines = try readlines(stdin);

    _ = try universe_spacing(lines.items, 1_000_000);
    //_ = try part2(lines.items);

    try bw.flush();
}

const Galaxy = struct {
    x: usize,
    y: usize,
};

fn sortFnNullAtEnd(context: void, a: ?usize, b: ?usize) bool {
    _ = context;
    if (a == null) return false;
    if (b == null) return true;
    return a.? < b.?;
}

fn parseMap(lines: [][]u8) !struct { galaxies: []Galaxy, empty_rows: []usize, empty_cols: []usize } {
    var galaxies = std.ArrayList(Galaxy).init(allocator);
    var empty_rows = std.ArrayList(usize).init(allocator);
    var empty_cols = std.ArrayList(?usize).init(allocator);
    defer empty_cols.deinit();

    for (0..lines.len) |i| try empty_cols.append(i);
    var num_empty_cols = lines.len;

    for (lines, 0..) |line, y| {
        var empty_row = true;
        for (line, 0..) |char, x| {
            if (char == '#') {
                if (empty_cols.items[x] != null) {
                    empty_cols.items[x] = null;
                    num_empty_cols -= 1;
                }
                empty_row = false;
                try galaxies.append(Galaxy{ .x = x, .y = y });
            }
        }
        if (empty_row) try empty_rows.append(y);
    }

    std.sort.insertion(?usize, empty_cols.items, {}, sortFnNullAtEnd);
    var empty_cols_return = try allocator.alloc(usize, num_empty_cols);
    for (empty_cols.items[0..num_empty_cols], 0..) |value, i| {
        empty_cols_return[i] = value.?;
    }
    return .{
        .galaxies = galaxies.items,
        .empty_rows = empty_rows.items,
        .empty_cols = empty_cols_return,
    };
}

inline fn absdiff(a: usize, b: usize) usize {
    return if (a > b) a - b else b - a;
}

fn universe_spacing(lines: [][]u8, expansion_rate: usize) !usize {
    var parsed = try parseMap(lines);
    var galaxies = parsed.galaxies;
    var empty_rows = parsed.empty_rows;
    var empty_cols = parsed.empty_cols;

    for (galaxies) |val| {
        std.debug.print("gal:{any}\n", .{val});
    }
    std.debug.print("empty_rows:{any}\n", .{empty_rows});
    std.debug.print("empty_cols:{any}\n", .{empty_cols});

    for (galaxies, 0..) |gal, i| {
        {
            var shift: usize = 0;
            for (empty_rows) |row| {
                if (row < gal.y) shift += expansion_rate - 1;
            }
            galaxies[i].y += shift;
        }
        {
            var shift: usize = 0;
            for (empty_cols) |col| {
                if (col < gal.x) shift += expansion_rate - 1;
            }
            galaxies[i].x += shift;
        }
    }

    std.debug.print("\n", .{});
    for (galaxies) |val| {
        std.debug.print("gal:{any}\n", .{val});
    }
    var sum: usize = 0;
    for (galaxies, 0..) |g1, i| {
        for (galaxies[i + 1 ..]) |g2| {
            if (std.meta.eql(g1, g2)) continue;
            const dist = absdiff(g1.x, g2.x) + absdiff(g1.y, g2.y);
            sum += dist;
        }
    }

    std.debug.print("\nsum:\n  {d}\n", .{sum});
    return sum;
}

test "part1 test" {
    const exampletext =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;

    std.debug.print("\n", .{});
    allocator = advent.allocator_init(heap.page_allocator);
    defer advent.allocator_deinit();

    {
        var readfile = std.ArrayList(u8).init(std.testing.allocator);
        defer readfile.deinit();
        try readfile.writer().writeAll(exampletext);
        var fbs = io.fixedBufferStream(readfile.items);
        var lines = try readlines(fbs.reader());

        var res: usize = try universe_spacing(lines.items, 2);

        try std.testing.expectEqual(@as(@TypeOf(res), 374), res);
    }
}

test "part2 test" {
    const exampletext =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;

    std.debug.print("\n", .{});
    allocator = advent.allocator_init(heap.page_allocator);
    defer advent.allocator_deinit();

    {
        var readfile = std.ArrayList(u8).init(std.testing.allocator);
        defer readfile.deinit();
        try readfile.writer().writeAll(exampletext);
        var fbs = io.fixedBufferStream(readfile.items);
        var lines = try readlines(fbs.reader());

        var res: usize = try universe_spacing(lines.items, 100);

        try std.testing.expectEqual(@as(@TypeOf(res), 8410), res);
    }
}
