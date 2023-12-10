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

const Race = struct {
    time: usize,
    distance: usize,
};

fn parseRaces(lines: [][]u8) ![]Race {
    var races = std.ArrayList(Race).init(allocator);
    const headerlen = "Distance:".len;
    var times = mem.tokenizeAny(u8, lines[0][headerlen..], " ");
    var distances = mem.tokenizeAny(u8, lines[1][headerlen..], " ");
    while (times.next()) |time| {
        const distance = distances.next().?;
        try races.append(Race{
            .time = try fmt.parseInt(usize, time, 10),
            .distance = try fmt.parseInt(usize, distance, 10),
        });
    }
    return races.items;
}

fn parseRaces2(lines: [][]u8) ![]Race {
    var races = std.ArrayList(Race).init(allocator);
    const headerlen = "Distance:".len;
    const timeline = lines[0][headerlen..];
    var time = try allocator.alloc(u8, mem.replacementSize(u8, timeline, " ", ""));
    _ = mem.replace(u8, timeline, " ", "", time);
    const distline = lines[1][headerlen..];
    var distance = try allocator.alloc(u8, mem.replacementSize(u8, distline, " ", ""));
    _ = mem.replace(u8, distline, " ", "", distance);

    try races.append(Race{
        .time = try fmt.parseInt(usize, time, 10),
        .distance = try fmt.parseInt(usize, distance, 10),
    });
    return races.items;
}

fn raceDistance(race_time: usize, held_time: usize) usize {
    return held_time * (race_time - held_time);
}

fn holdTimes(race_time: usize, distance: usize) struct { a: usize, b: usize } {
    const bac = race_time * race_time - 4 * (distance + 1);
    const bacflt: f64 = @floatFromInt(bac);
    const bacsqrt: usize = @intFromFloat(@sqrt(bacflt) / 2);
    std.debug.print("{any}->{any}->{any}\n", .{ bacflt, @sqrt(bacflt), bacsqrt });
    var hta = (race_time) / 2 - bacsqrt;
    var htb = (race_time + 1) / 2 + bacsqrt;
    if (raceDistance(race_time, hta) <= distance) hta += 1;
    if (raceDistance(race_time, htb) <= distance) htb -= 1;
    return .{ .a = hta, .b = htb };
}

fn part1(lines: [][]u8) !usize {
    const races = try parseRaces(lines);
    for (races) |race| std.debug.print("{any}\n", .{race});
    var total_wins: usize = 1;
    for (races) |race| {
        const hts = holdTimes(race.time, race.distance);
        const wins = @max(hts.a, hts.b) - @min(hts.a, hts.b) + 1;
        std.debug.print("hts:{any} wins:{d}\n", .{ hts, wins });
        total_wins *= wins;
    }

    std.debug.print("\n{d}\n", .{total_wins});
    return total_wins;
}
fn part2(lines: [][]u8) !usize {
    const races = try parseRaces2(lines);
    for (races) |race| std.debug.print("{any}\n", .{race});
    var total_wins: usize = 1;
    for (races) |race| {
        const hts = holdTimes(race.time, race.distance);
        const wins = @max(hts.a, hts.b) - @min(hts.a, hts.b) + 1;
        std.debug.print("hts:{any} wins:{d}\n", .{ hts, wins });
        total_wins *= wins;
    }

    std.debug.print("\n{d}\n", .{total_wins});
    return total_wins;
}

test "part1 test" {
    const exampletext =
        \\Time:      7  15   30
        \\Distance:  9  40  200
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

    try std.testing.expectEqual(@as(@TypeOf(minloc), 288), minloc);
}
test "part2 test" {
    const exampletext =
        \\Time:      7  15   30
        \\Distance:  9  40  200
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

    try std.testing.expectEqual(@as(@TypeOf(minloc), 71503), minloc);
}
