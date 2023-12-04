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

    var sum: u128 = 0;
    for (lines.items) |line| {
        const parts = getCardParts(line);
        const nums0 = getNumbers(parts[0]);
        const nums1 = getNumbers(parts[1]);
        const both = nums0 & nums1;
        const score = getCardScore(both);
        sum += score;
    }

    try stdout.print("\n{d}\n", .{sum});

    try bw.flush();
}

fn getCardParts(string: []const u8) Tuple(&.{ []const u8, []const u8 }) {
    const startidx: usize = (std.mem.indexOf(u8, string, ":") orelse 0) + 1;
    const mididx: usize = std.mem.indexOf(u8, string, "|") orelse 0;
    return .{ string[startidx..(mididx - 1)], string[(mididx + 1)..] };
}

fn getNumbers(string: []const u8) u100 {
    var tokens = std.mem.tokenizeAny(u8, string, " ");
    var nums: u100 = 0;
    while (tokens.next()) |numst| {
        const num: u7 = std.fmt.parseInt(u7, numst, 10) catch {
            std.debug.print("Error while parsing '{s}'", .{numst});
            continue;
        };
        nums |= @as(u100, 1) << num;
    }
    return nums;
}

fn getCardScore(both: u100) u128 {
    if (both == 0) return 0;
    var cnt: usize = 0;
    for (0..100) |i| {
        if (both & @as(u100, 1) << @intCast(i) != 0) cnt += 1;
    }
    return @as(u128, 1) << @intCast(cnt - 1);
}

test "part1 test" {
    const exampletext =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
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

    var sum: u128 = 0;
    for (lines.items) |line| {
        const parts = getCardParts(line);
        const nums0 = getNumbers(parts[0]);
        const nums1 = getNumbers(parts[1]);
        std.debug.print("{s},{s}\n", .{ parts[0], parts[1] });
        const both = nums0 & nums1;
        const score = getCardScore(both);
        std.debug.print("{b}={d}\n", .{ both, score });
        sum += score;
    }

    try std.testing.expectEqual(@as(u128, 13), sum);
}
