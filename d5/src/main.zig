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

    _ = try part2(lines.items);

    try bw.flush();
}

const MapLine = struct {
    start_a: usize,
    start_b: usize,
    count: usize,
};
const Almanac = std.StringHashMap([]MapLine);

const SeedRange = struct {
    start: usize,
    len: usize,
};

fn parseSeedsAsNums(line: []u8) []SeedRange {
    const numsstart = (std.mem.indexOf(u8, line, ":") orelse 0) + 1;
    const numsstring = line[numsstart..];
    var numssplit = std.mem.tokenizeAny(u8, numsstring, " ");
    var nums = std.ArrayList(SeedRange).init(allocator);
    while (numssplit.next()) |numstr| {
        const start = fmt.parseInt(usize, numstr, 10) catch continue;
        nums.append(SeedRange{ .start = start, .len = 1 }) catch continue;
    }
    return nums.items;
}

fn parseSeedsAsRange(line: []u8) []SeedRange {
    const numsstart = (std.mem.indexOf(u8, line, ":") orelse 0) + 1;
    const numsstring = line[numsstart..];
    var numssplit = std.mem.tokenizeAny(u8, numsstring, " ");
    var nums = std.ArrayList(SeedRange).init(allocator);
    while (numssplit.next()) |numstr| {
        const start = fmt.parseInt(usize, numstr, 10) catch continue;
        const len = fmt.parseInt(usize, numssplit.next().?, 10) catch continue;
        nums.append(SeedRange{ .start = start, .len = len }) catch unreachable;
    }

    return nums.items;
}

fn parseAlmanac(lines: [][]u8) Almanac {
    var parselines = lines[0..];
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

    return maps;
}

fn rangeIntersectsRange(comptime T: type, astart: T, alen: T, bstart: T, blen: T) bool {
    const aend = astart + alen - 1;
    const bend = bstart + blen - 1;
    return (astart <= bend) and (aend >= bstart);
}

test "rangeIntersectRange works" {
    try std.testing.expect(!rangeIntersectsRange(usize, 10, 10, 20, 10));
    try std.testing.expect(!rangeIntersectsRange(usize, 20, 10, 10, 10));
    try std.testing.expect(!rangeIntersectsRange(usize, 20, 10, 10, 1));
    try std.testing.expect(!rangeIntersectsRange(usize, 20, 10, 30, 1));
    try std.testing.expect(rangeIntersectsRange(usize, 10, 10, 11, 10));
    try std.testing.expect(rangeIntersectsRange(usize, 10, 10, 19, 10));
    try std.testing.expect(rangeIntersectsRange(usize, 11, 10, 10, 10));
    try std.testing.expect(rangeIntersectsRange(usize, 19, 10, 10, 10));
    try std.testing.expect(rangeIntersectsRange(usize, 10, 10, 11, 1));
    try std.testing.expect(rangeIntersectsRange(usize, 10, 10, 11, 2));
    try std.testing.expect(rangeIntersectsRange(usize, 11, 1, 10, 10));
    try std.testing.expect(rangeIntersectsRange(usize, 11, 2, 10, 10));
}

fn seedInsideLine(line: MapLine, a: SeedRange) bool {
    const aend = a.start + a.len - 1;
    const lineend = line.start_a + line.count - 1;
    return (a.start >= line.start_a) and (aend <= lineend);
}

fn lineInsideSeed(line: MapLine, a: SeedRange) bool {
    const aend = a.start + a.len - 1;
    const lineend = line.start_a + line.count - 1;
    return (a.start <= line.start_a) and (aend >= lineend);
}

fn subtractRanges(a: SeedRange, b: SeedRange) []SeedRange {
    var newranges = std.ArrayList(SeedRange).init(allocator);
    const aend = a.start + a.len - 1;
    const bend = b.start + b.len - 1;
    const ainb = (a.start >= b.start) and (aend <= bend);
    if (ainb) return newranges.items;
    const aintersectb = (a.start <= bend) and (aend >= b.start);
    if (!aintersectb) {
        newranges.append(a) catch unreachable;
        return newranges.items;
    }
    if (a.start < b.start) {
        const llen = (b.start - a.start);
        const l = SeedRange{ .start = a.start, .len = llen };
        newranges.append(l) catch unreachable;
    }
    if (aend > bend) {
        const rlen = (aend - bend);
        const r = SeedRange{ .start = b.start + b.len, .len = rlen };
        newranges.append(r) catch unreachable;
    }
    return newranges.items;
}

fn translate_almanac_line(lines: []MapLine, a: SeedRange) []SeedRange {
    var newranges = std.ArrayList(SeedRange).init(allocator);
    var unhandled_ranges = std.ArrayList(SeedRange).init(allocator);
    unhandled_ranges.append(a) catch unreachable;
    for (lines) |line| {
        std.debug.print("seed: {any}, line: {any}\n", .{ a, line });
        const seedend = a.start + a.len - 1;
        const lineend = line.start_a + line.count - 1;
        if (seedInsideLine(line, a)) {
            const b = SeedRange{ .start = a.start - line.start_a + line.start_b, .len = a.len };
            newranges.append(b) catch unreachable;
            unhandled_ranges.deinit();
            unhandled_ranges = std.ArrayList(SeedRange).init(allocator);
            break;
        } else if (rangeIntersectsRange(usize, a.start, a.len, line.start_a, line.count)) {
            if (lineInsideSeed(line, a)) {
                // IDX:  12345678901234
                // Line: -----....-----
                // Seed: --**********--
                // Segm: --lllccccrrr--
                const c = SeedRange{ .start = line.start_b, .len = line.count };
                newranges.append(c) catch unreachable;
                const h = SeedRange{ .start = line.start_a, .len = line.count };

                var unhandled = std.ArrayList(SeedRange).init(allocator);
                for (unhandled_ranges.items) |unh| {
                    const newunhs = subtractRanges(unh, h);
                    for (newunhs) |newunh| {
                        unhandled.append(newunh) catch unreachable;
                    }
                }
                unhandled_ranges.deinit();
                unhandled_ranges = unhandled;
                continue;
            } else if (a.start < line.start_a) {
                // IDX:  12345678901234
                // Line: -----....-----
                // Seed: --*****-------
                // Segm: --lllcc-------
                const c = SeedRange{ .start = line.start_b, .len = seedend - line.start_a };
                newranges.append(c) catch unreachable;
                const h = SeedRange{ .start = line.start_a, .len = seedend - line.start_a };
                var unhandled = std.ArrayList(SeedRange).init(allocator);
                for (unhandled_ranges.items) |unh| {
                    const newunhs = subtractRanges(unh, h);
                    for (newunhs) |newunh| {
                        unhandled.append(newunh) catch unreachable;
                    }
                }
                unhandled_ranges.deinit();
                unhandled_ranges = unhandled;
                continue;
            } else {
                // IDX:  12345678901234
                // Line: -----....-----
                // Seed: -------*****--
                // Segm: -------CCRRR--
                const c = SeedRange{ .start = a.start - line.start_a + line.start_b, .len = (lineend - a.start) };
                newranges.append(c) catch unreachable;
                const h = SeedRange{ .start = a.start, .len = (lineend - a.start) };
                var unhandled = std.ArrayList(SeedRange).init(allocator);
                for (unhandled_ranges.items) |unh| {
                    const newunhs = subtractRanges(unh, h);
                    for (newunhs) |newunh| {
                        unhandled.append(newunh) catch unreachable;
                    }
                }
                unhandled_ranges.deinit();
                unhandled_ranges = unhandled;
                continue;
            }
        }
    }
    std.debug.print("newranges: {any}\n\n", .{newranges.items});
    for (unhandled_ranges.items) |unh| {
        newranges.append(unh) catch unreachable;
    }
    return newranges.items;
}

fn get_seed_locations(almanac: Almanac, seeds: []SeedRange) ![]usize {
    var locs = std.ArrayList(usize).init(allocator);
    for (seeds) |seed| {
        var soils = translate_almanac_line(almanac.get("seed-to-soil").?, seed);
        for (soils) |soil| {
            var ferts = translate_almanac_line(almanac.get("soil-to-fertilizer").?, soil);
            for (ferts) |fert| {
                var waters = translate_almanac_line(almanac.get("fertilizer-to-water").?, fert);
                for (waters) |water| {
                    var lights = translate_almanac_line(almanac.get("water-to-light").?, water);
                    for (lights) |light| {
                        var temps = translate_almanac_line(almanac.get("light-to-temperature").?, light);
                        for (temps) |temp| {
                            var humids = translate_almanac_line(almanac.get("temperature-to-humidity").?, temp);
                            for (humids) |humid| {
                                var locations = translate_almanac_line(almanac.get("humidity-to-location").?, humid);
                                for (locations) |loc| {
                                    try locs.append(loc.start);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return locs.items;
}

fn part1(lines: [][]u8) !usize {
    const seeds = parseSeedsAsNums(lines[0]);
    var almanac = parseAlmanac(lines[1..]);
    const locs = try get_seed_locations(almanac, seeds);

    var minloc: usize = locs[0];
    for (locs[1..]) |loc| {
        minloc = @min(minloc, loc);
    }

    std.debug.print("\n{d}\n", .{minloc});
    return minloc;
}
fn part2(lines: [][]u8) !usize {
    const seeds = parseSeedsAsRange(lines[0]);
    var almanac = parseAlmanac(lines[1..]);
    const locs = try get_seed_locations(almanac, seeds);

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

    var minloc: usize = try part1(lines.items);

    try std.testing.expectEqual(@as(@TypeOf(minloc), 35), minloc);
}
test "part2 test" {
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

    var minloc: usize = try part2(lines.items);

    try std.testing.expectEqual(@as(@TypeOf(minloc), 46), minloc);
}
