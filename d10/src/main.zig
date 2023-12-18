const std = @import("std");
const advent = @import("advent.zig");
const part1z = @import("part1.zig");
const part1 = part1z.part1;
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
    part1z.allocator = allocator;
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

const Direction = enum {
    W,
    N,
    E,
    S,
};

const Tile = enum {
    Pipe,
    Outside,
    Inside,
};

const Location = struct {
    tile: ?Tile = null,
    hasWest: bool = false,
    hasNorth: bool = false,
    hasEast: bool = false,
    hasSouth: bool = false,
    visited: bool = false,
};

fn parseChar(char: u8) ?Location {
    return switch (char) {
        'S' => Location{ .tile = Tile.Pipe, .hasWest = true, .hasNorth = true, .hasEast = true, .hasSouth = true },
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
fn putPipe(grid: [][]?Location, x: usize, y: usize) ![]UpdatedCell {
    var updatedcells = std.ArrayList(UpdatedCell).init(allocator);
    const current_cell: Location = grid[y][x].?;
    if (x > 0) {
        const new = .{ .x = x - 1, .y = y };
        const west_exists = current_cell.hasWest and grid[new.y][new.x] != null;
        if (west_exists and grid[new.y][new.x].?.tile == null and grid[new.y][new.x].?.hasEast) {
            grid[new.y][new.x].?.tile = Tile.Pipe;
            try updatedcells.append(UpdatedCell{ .x = new.x, .y = new.y });
        }
    }
    if (y > 0) {
        const new = .{ .x = x, .y = y - 1 };
        const north_exists = current_cell.hasNorth and grid[new.y][new.x] != null;
        if (north_exists and grid[new.y][new.x].?.tile == null and grid[new.y][new.x].?.hasSouth) {
            grid[new.y][new.x].?.tile = Tile.Pipe;
            try updatedcells.append(UpdatedCell{ .x = new.x, .y = new.y });
        }
    }
    if (x < grid[0].len) {
        const new = .{ .x = x + 1, .y = y };
        const east_exists = current_cell.hasEast and grid[new.y][new.x] != null;
        if (east_exists and grid[new.y][new.x].?.tile == null and grid[new.y][new.x].?.hasWest) {
            grid[new.y][new.x].?.tile = Tile.Pipe;
            try updatedcells.append(UpdatedCell{ .x = new.x, .y = new.y });
        }
    }
    if (y < grid.len) {
        const new = .{ .x = x, .y = y + 1 };
        const south_exists = current_cell.hasSouth and grid[new.y][new.x] != null;
        if (south_exists and grid[new.y][new.x].?.tile == null and grid[new.y][new.x].?.hasNorth) {
            grid[new.y][new.x].?.tile = Tile.Pipe;
            try updatedcells.append(UpdatedCell{ .x = new.x, .y = new.y });
        }
    }
    return updatedcells.items;
}

fn part2(lines: [][]u8) !usize {
    const width = lines[0].len;
    const height = lines.len;

    var grid = try allocator.alloc([]?Location, height);
    var sx: usize = 0;
    var sy: usize = 0;
    for (lines, 0..) |line, y| {
        grid[y] = try allocator.alloc(?Location, width);
        for (line, 0..) |chr, x| {
            grid[y][x] = parseChar(chr);
            if (grid[y][x] != null and grid[y][x].?.tile == Tile.Pipe) {
                sx = x;
                sy = y;
            }
        }
    }

    var all_next_steps = std.ArrayList(UpdatedCell).init(allocator);
    {
        const next_steps = try putPipe(grid, sx, sy);
        defer allocator.free(next_steps);
        for (next_steps) |stp| {
            try all_next_steps.append(stp);
        }
    }
    var miny: usize = sy;
    while (true) {
        if (all_next_steps.items.len == 0) break;
        var next_next_steps = std.ArrayList(UpdatedCell).init(allocator);
        for (all_next_steps.items) |nstep| {
            const next_steps = try putPipe(grid, nstep.x, nstep.y);
            defer allocator.free(next_steps);
            for (next_steps) |stp| {
                miny = @min(miny, stp.y);
                try next_next_steps.append(stp);
            }
        }
        all_next_steps.deinit();
        all_next_steps = next_next_steps;
    }

    grid[sy][sx].?.hasWest = if (grid[sy][sx - 1]) |cell| cell.hasEast else false;
    grid[sy][sx].?.hasNorth = if (grid[sy - 1][sx]) |cell| cell.hasSouth else false;
    grid[sy][sx].?.hasEast = if (grid[sy][sx + 1]) |cell| cell.hasEast else false;
    grid[sy][sx].?.hasSouth = if (grid[sy + 1][sx]) |cell| cell.hasNorth else false;
    std.debug.print("start:{any}\n", .{grid[sy][sx].?});

    const starty = miny;
    var startx = blk: {
        for (grid[starty], 0..) |cell, x| {
            if (cell) |cl| if (cl.tile == Tile.Pipe) break :blk x;
        }
        unreachable;
    };
    walk(grid, startx, starty, Direction.S);

    var sum: usize = 0;
    for (grid) |row| {
        for (row) |cell| {
            if (cell) |cl| {
                if (cl.tile) |tl| {
                    if (tl == Tile.Inside) sum += 1;
                }
            }
        }
    }

    std.debug.print("\nInside Tiles:\n  {d}\n", .{sum});
    return sum;
}

const directions = [_]Direction{ Direction.W, Direction.N, Direction.E, Direction.S };
fn getnextdir(loc: Location, from: Direction) Direction {
    for (directions) |todir| {
        if (todir != from) {
            switch (todir) {
                Direction.W => if (loc.hasWest) return todir,
                Direction.N => if (loc.hasNorth) return todir,
                Direction.E => if (loc.hasEast) return todir,
                Direction.S => if (loc.hasSouth) return todir,
            }
        }
    }
    unreachable;
}

const Coordinate = struct { x: usize, y: usize };
fn flood(grid: [][]?Location, x: usize, y: usize) void {
    if (grid[y][x]) |cell| if (cell.tile) |tl| if (tl == Tile.Pipe or tl == Tile.Inside) return;
    grid[y][x] = Location{ .tile = Tile.Inside };
    for ((y - 1)..(y + 1)) |ny| {
        for ((x - 1)..(x + 1)) |nx| {
            if (nx == x and ny == y) continue;
            flood(grid, nx, ny);
        }
    }
}
fn walk(grid: [][]?Location, x: usize, y: usize, from: Direction) void {
    if (grid[y][x].?.visited) return;
    const to = getnextdir(grid[y][x].?, from);
    //std.debug.print("walk:{d},{d},from:{any},to:{any}\n", .{ x, y, from, to });
    var extra: ?Coordinate = null;
    const rightside: ?Coordinate = blk: {
        break :blk if (std.meta.eql(.{ from, to }, .{ Direction.W, Direction.E }))
            .{ .x = x, .y = y + 1 }
        else if (std.meta.eql(.{ from, to }, .{ Direction.E, Direction.W }))
            .{ .x = x, .y = y - 1 }
        else if (std.meta.eql(.{ from, to }, .{ Direction.N, Direction.S }))
            .{ .x = x - 1, .y = y }
        else if (std.meta.eql(.{ from, to }, .{ Direction.S, Direction.N }))
            .{ .x = x + 1, .y = y }
        else if (std.meta.eql(.{ from, to }, .{ Direction.W, Direction.N })) {
            extra = .{ .x = x, .y = y + 1 };
            break :blk .{ .x = x + 1, .y = y };
        } else if (std.meta.eql(.{ from, to }, .{ Direction.W, Direction.S }))
            null
        else if (std.meta.eql(.{ from, to }, .{ Direction.E, Direction.N }))
            null
        else if (std.meta.eql(.{ from, to }, .{ Direction.E, Direction.S })) {
            extra = .{ .x = x, .y = y - 1 };
            break :blk .{ .x = x - 1, .y = y };
        } else if (std.meta.eql(.{ from, to }, .{ Direction.N, Direction.W }))
            null
        else if (std.meta.eql(.{ from, to }, .{ Direction.N, Direction.E })) {
            extra = .{ .x = x, .y = y + 1 };
            break :blk .{ .x = x - 1, .y = y };
        } else if (std.meta.eql(.{ from, to }, .{ Direction.S, Direction.E }))
            null
        else if (std.meta.eql(.{ from, to }, .{ Direction.S, Direction.W })) {
            extra = .{ .x = x, .y = y - 1 };
            break :blk .{ .x = x + 1, .y = y };
        } else null;
    };
    if (rightside) |rs| flood(grid, rs.x, rs.y);
    if (extra) |rs| flood(grid, rs.x, rs.y);

    const nextx = switch (to) {
        Direction.W => x - 1,
        Direction.E => x + 1,
        else => x,
    };
    const nexty = switch (to) {
        Direction.N => y - 1,
        Direction.S => y + 1,
        else => y,
    };
    const nextfrom = switch (to) {
        Direction.W => Direction.E,
        Direction.N => Direction.S,
        Direction.E => Direction.W,
        Direction.S => Direction.N,
    };
    grid[y][x].?.visited = true;
    walk(grid, nextx, nexty, nextfrom);
}

test "part2 test 1" {
    const exampletext =
        \\...........
        \\.S-------7.
        \\.|F-----7|.
        \\.||OOOOO||.
        \\.||OOOOO||.
        \\.|L-7OF-J|.
        \\.|II|O|II|.
        \\.L--JOL--J.
        \\.....O.....
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
        try std.testing.expectEqual(@as(@TypeOf(res), 4), res);
    }
}

test "part2 test 2" {
    const exampletext =
        \\..........
        \\.S------7.
        \\.|F----7|.
        \\.||OOOO||.
        \\.||OOOO||.
        \\.|L-7F-J|.
        \\.|II||II|.
        \\.L--JL--J.
        \\..........
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
        try std.testing.expectEqual(@as(@TypeOf(res), 4), res);
    }
}

test "part2 test 3" {
    const exampletext =
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
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
        try std.testing.expectEqual(@as(@TypeOf(res), 8), res);
    }
}

test "part2 test 4" {
    const exampletext =
        \\..........
        \\.S------7.
        \\.|F----7|.
        \\.||OOOO||.
        \\.||OOOO||.
        \\.|L-7F-JL7
        \\.|II||III|
        \\.L--J|III|
        \\.....|III|
        \\.....L---J
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
        try std.testing.expectEqual(@as(@TypeOf(res), 11), res);
    }
}
