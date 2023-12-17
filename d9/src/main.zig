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

    //_ = try part1(lines.items);
    _ = try part2(lines.items);

    try bw.flush();
}

fn parseline(line: []u8) ![]isize {
    var nums = std.ArrayList(isize).init(allocator);
    var numstrs = mem.tokenizeAny(u8, line, " ");

    while (numstrs.next()) |numstr| {
        try nums.append(try fmt.parseInt(isize, numstr, 10));
    }

    return nums.items;
}

fn all_zero(series: []isize) bool {
    for (series) |value| {
        if (value != 0) return false;
    }
    return true;
}

fn diffrow(series: []isize) []isize {
    var row = allocator.alloc(isize, series.len - 1) catch unreachable;
    for (1..series.len) |i| {
        row[i - 1] = series[i] - series[i - 1];
    }
    return row;
}

fn extrapolate_series(series: []isize) isize {
    var rows = std.ArrayList([]isize).init(allocator);
    defer rows.deinit();

    var row = series;
    rows.append(series) catch unreachable;
    while (!all_zero(row)) {
        row = diffrow(row);
        rows.append(row) catch unreachable;
    }
    var sum: isize = 0;
    for (rows.items) |rw| {
        sum += rw[rw.len - 1];
    }
    return sum;
}
fn extrapolate_series_past(series: []isize) isize {
    var rows = std.ArrayList([]isize).init(allocator);
    defer rows.deinit();

    var row = series;
    rows.append(series) catch unreachable;
    while (!all_zero(row)) {
        row = diffrow(row);
        rows.append(row) catch unreachable;
    }

    var last_value: isize = 0;
    for (0..rows.items.len) |i| {
        const k = rows.items.len - i - 1;
        const newval = rows.items[k][0] - last_value;
        last_value = newval;
    }

    return last_value;
}

fn part1(lines: [][]u8) !isize {
    var sum: isize = 0;
    for (lines) |line| {
        const nums = try parseline(line);
        const newval = extrapolate_series(nums);
        sum += newval;
    }

    std.debug.print("\nsum:\n  {d}\n", .{sum});
    return sum;
}

fn part2(lines: [][]u8) !isize {
    var sum: isize = 0;
    for (lines) |line| {
        const nums = try parseline(line);
        const newval = extrapolate_series_past(nums);
        sum += newval;
    }

    std.debug.print("\nsum:\n  {d}\n", .{sum});
    return sum;
}

test "part1 test" {
    const exampletext =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
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

        var res: isize = try part1(lines.items);

        try std.testing.expectEqual(@as(@TypeOf(res), 114), res);
    }
}

test "part2 test" {
    const exampletext =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
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

        var res: isize = try part2(lines.items);

        try std.testing.expectEqual(@as(@TypeOf(res), 2), res);
    }
}
