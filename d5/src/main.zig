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

    _ = try day1(lines.items);

    try bw.flush();
}

const AlmanacMap = std.StringHashMap([]MapLine);
const Almanac = struct {
    seeds: []usize,
    maps: AlmanacMap,
};
const MapLine = struct {
    start_a: usize,
    start_b: usize,
    count: usize,
};
fn parseInput(lines: [][]u8) Almanac {
    const seeds = seeds: {
        const numsstart = (std.mem.indexOf(u8, lines[0], ":") orelse 0) + 1;
        const numsstring = lines[0][numsstart..];
        var numssplit = std.mem.tokenizeAny(u8, numsstring, " ");
        var nums = std.ArrayList(usize).init(allocator);
        while (numssplit.next()) |numstr| {
            nums.append(fmt.parseInt(usize, numstr, 10) catch continue) catch continue;
        }
        break :seeds nums.items;
    };
    var parselines = lines[1..];
    var maps = std.StringHashMap([]MapLine).init(allocator);

    for (0..7) |_| {
        parselines = parselines[1..];
        const key = parselines[0][0 .. std.mem.indexOf(u8, parselines[0], " ") orelse 0];
        //std.debug.print("{s}, key={s}\n", .{ parselines[0], key });
        parselines = parselines[1..];
        var mappings = std.ArrayList(MapLine).init(allocator);
        const lastline = parsenums: for (parselines, 0..) |line, i| {
            //std.debug.print("{s}\n", .{line});
            if (line.len == 0) break :parsenums i;
            var numtoken = std.mem.tokenizeAny(u8, line, " ");
            const start_b = fmt.parseInt(usize, numtoken.next().?, 10) catch unreachable;
            const start_a = fmt.parseInt(usize, numtoken.next().?, 10) catch unreachable;
            const count = fmt.parseInt(usize, numtoken.next().?, 10) catch unreachable;
            mappings.append(MapLine{ .start_a = start_a, .start_b = start_b, .count = count }) catch unreachable;
        } else {
            break :parsenums parselines.len;
        };
        maps.put(key, mappings.items) catch unreachable;
        parselines = parselines[lastline..];
    }

    return Almanac{ .seeds = seeds, .maps = maps };
}

fn translate_almanac_line(lines: []MapLine, a: usize) usize {
    for (lines) |line| {
        if (inRange(usize, a, line.start_a, line.start_a + line.count - 1)) {
            return a - line.start_a + line.start_b;
        }
    }
    return a;
}

fn get_seed_locations(almanac: Almanac) ![]usize {
    var locs = std.ArrayList(usize).init(allocator);
    for (almanac.seeds) |seed| {
        var loc: usize = seed;
        loc = translate_almanac_line(almanac.maps.get("seed-to-soil").?, loc);
        loc = translate_almanac_line(almanac.maps.get("soil-to-fertilizer").?, loc);
        loc = translate_almanac_line(almanac.maps.get("fertilizer-to-water").?, loc);
        loc = translate_almanac_line(almanac.maps.get("water-to-light").?, loc);
        loc = translate_almanac_line(almanac.maps.get("light-to-temperature").?, loc);
        loc = translate_almanac_line(almanac.maps.get("temperature-to-humidity").?, loc);
        loc = translate_almanac_line(almanac.maps.get("humidity-to-location").?, loc);
        try locs.append(loc);
    }

    return locs.items;
}

fn day1(lines: [][]u8) !usize {
    var almanac = parseInput(lines);
    const locs = try get_seed_locations(almanac);

    var minloc: usize = locs[0];
    for (locs[1..]) |loc| {
        minloc = @min(minloc, loc);
    }

    std.debug.print("\n{d}\n", .{minloc});
    return minloc;
}

test "part1 test" {
    const exampletext =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;
    std.debug.print("\n", .{});
    allocator = advent.allocator_init(heap.page_allocator);
    defer advent.allocator_deinit();
    var readfile = std.ArrayList(u8).init(std.testing.allocator);
    defer readfile.deinit();
    try readfile.writer().writeAll(exampletext);
    var fbs = io.fixedBufferStream(readfile.items);
    var lines = try readlines(fbs.reader());

    var minloc: usize = try day1(lines.items);

    try std.testing.expectEqual(@as(@TypeOf(minloc), 35), minloc);
}
