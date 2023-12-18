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

    _ = try part1(lines.items);
    //_ = try part2(lines.items);

    try bw.flush();
}

const Location = struct {
    distance: ?usize = null,
    hasWest: bool = false,
    hasNorth: bool = false,
    hasEast: bool = false,
    hasSouth: bool = false,
};

fn parseChar(char: u8) ?Location {
    return switch (char) {
        'S' => Location{ .distance = 0, .hasWest = true, .hasNorth = true, .hasEast = true, .hasSouth = true },
        '|' => Location{ .hasNorth = true, .hasSouth = true },
        '-' => Location{ .hasWest = true, .hasEast = true },
        'L' => Location{ .hasNorth = true, .hasEast = true },
        'J' => Location{ .hasNorth = true, .hasWest = true },
        '7' => Location{ .hasWest = true, .hasSouth = true },
        'F' => Location{ .hasEast = true, .hasSouth = true },
        else => null,
    };
}

const UpdatedCell = struct { x: usize, y: usize };
fn putDistances(grid: [][]?Location, x: usize, y: usize, current_dist: usize) ![]UpdatedCell {
    _ = current_dist;
    var updatedcells = std.ArrayList(UpdatedCell).init(allocator);
    const current_cell: Location = grid[y][x].?;
    const next_dist = current_cell.distance.? + 1;
    if (x > 0) {
        const new = .{ .x = x - 1, .y = y };
        const west_exists = current_cell.hasWest and grid[new.y][new.x] != null;
        if (west_exists and grid[new.y][new.x].?.distance == null and grid[new.y][new.x].?.hasEast) {
            grid[new.y][new.x].?.distance = next_dist;
            try updatedcells.append(UpdatedCell{ .x = new.x, .y = new.y });
        }
    }
    if (y > 0) {
        const new = .{ .x = x, .y = y - 1 };
        const north_exists = current_cell.hasNorth and grid[new.y][new.x] != null;
        if (north_exists and grid[new.y][new.x].?.distance == null and grid[new.y][new.x].?.hasSouth) {
            grid[new.y][new.x].?.distance = next_dist;
            try updatedcells.append(UpdatedCell{ .x = new.x, .y = new.y });
        }
    }
    if (x < grid[0].len) {
        const new = .{ .x = x + 1, .y = y };
        const east_exists = current_cell.hasEast and grid[new.y][new.x] != null;
        if (east_exists and grid[new.y][new.x].?.distance == null and grid[new.y][new.x].?.hasWest) {
            grid[new.y][new.x].?.distance = next_dist;
            try updatedcells.append(UpdatedCell{ .x = new.x, .y = new.y });
        }
    }
    if (y < grid.len) {
        const new = .{ .x = x, .y = y + 1 };
        const south_exists = current_cell.hasSouth and grid[new.y][new.x] != null;
        if (south_exists and grid[new.y][new.x].?.distance == null and grid[new.y][new.x].?.hasNorth) {
            grid[new.y][new.x].?.distance = next_dist;
            try updatedcells.append(UpdatedCell{ .x = new.x, .y = new.y });
        }
    }
    return updatedcells.items;
}

fn part1(lines: [][]u8) !usize {
    const width = lines[0].len;
    const height = lines.len;

    var grid = try allocator.alloc([]?Location, height);
    var sx: usize = 0;
    var sy: usize = 0;
    for (lines, 0..) |line, y| {
        grid[y] = try allocator.alloc(?Location, width);
        for (line, 0..) |chr, x| {
            grid[y][x] = parseChar(chr);
            if (grid[y][x] != null and grid[y][x].?.distance == 0) {
                sx = x;
                sy = y;
            }
        }
    }

    std.debug.print("\nstartx:{d},y:{d},v:{any}\n\n", .{ sx, sy, grid[sy][sx] });
    //for (grid, 0..) |row, y| {
    //    for (row, 0..) |cell, x| {
    //        std.debug.print("x:{d},y:{d},v:{any}\n", .{ x, y, cell });
    //    }
    //}

    var currx: usize = sx;
    var curry: usize = sy;
    var currdist: usize = 0;
    var all_next_steps = std.ArrayList(UpdatedCell).init(allocator);
    {
        const next_steps = try putDistances(grid, currx, curry, currdist);
        defer allocator.free(next_steps);
        for (next_steps) |stp| {
            try all_next_steps.append(stp);
        }
    }
    while (true) {
        if (all_next_steps.items.len == 0) break;
        currdist += 1;
        var next_next_steps = std.ArrayList(UpdatedCell).init(allocator);
        for (all_next_steps.items) |nstep| {
            const next_steps = try putDistances(grid, nstep.x, nstep.y, currdist);
            defer allocator.free(next_steps);
            for (next_steps) |stp| {
                try next_next_steps.append(stp);
            }
        }
        all_next_steps.deinit();
        all_next_steps = next_next_steps;
    }

    std.debug.print("\ndistance:\n  {d}\n", .{currdist});
    return currdist;
}

fn part2(lines: [][]u8) !usize {
    _ = lines;

    std.debug.print("\nsum:\n  {d}\n", .{0});
    return 0;
}

test "part1 test 1" {
    const exampletext =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
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

        var res: usize = try part1(lines.items);
        try std.testing.expectEqual(@as(@TypeOf(res), 8), res);
    }
}
test "part1 test 2" {
    const exampletext =
        \\-L|F7
        \\7S-7|
        \\L|7||
        \\-L-J|
        \\L|-JF
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

        var res: usize = try part1(lines.items);
        try std.testing.expectEqual(@as(@TypeOf(res), 4), res);
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

        var res: usize = try part2(lines.items);

        try std.testing.expectEqual(@as(@TypeOf(res), 2), res);
    }
}
