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

const Hand = struct {
    cards: [5]u8,
    strength: usize,
    bid: usize,
};

fn cardValue(card: u8) usize {
    return switch (card) {
        '2'...'9' => card - '2',
        'T' => 8,
        'J' => 9,
        'Q' => 10,
        'K' => 11,
        'A' => 12,
        else => unreachable,
    };
}

fn cardStrength(card: u8, index: usize) usize {
    const shift = 8 * (4 - index);
    const value = cardValue(card);
    return value << @intCast(shift);
}

fn cmpGreaterThan(context: void, a: u8, b: u8) bool {
    _ = context;
    return a > b;
}

fn cmpHandStrength(context: void, a: Hand, b: Hand) bool {
    _ = context;
    return a.strength < b.strength;
}

fn handStrength(cards: [5]u8) usize {
    var card_strength: usize = 0;
    var counts: [13]u8 = [_]u8{0} ** 13;
    for (cards, 0..) |card, idx| {
        const cval = cardValue(card);
        card_strength += cardStrength(card, idx);
        counts[cval] += 1;
    }
    std.sort.insertion(u8, &counts, {}, cmpGreaterThan);
    //std.debug.print("counts:{any}\n", .{counts});

    if (counts[0] == 5) {
        card_strength += 6 << (8 * 5);
    } else if (counts[0] == 4) {
        card_strength += 5 << (8 * 5);
    } else if (counts[0] == 3 and counts[1] == 2) {
        card_strength += 4 << (8 * 5);
    } else if (counts[0] == 3) {
        card_strength += 3 << (8 * 5);
    } else if (counts[0] == 2 and counts[1] == 2) {
        card_strength += 2 << (8 * 5);
    } else if (counts[0] == 2) {
        card_strength += 1 << (8 * 5);
    }

    return card_strength;
}

fn parseHand(line: []u8) !Hand {
    const bid: usize = try fmt.parseInt(usize, line[6..], 10);
    //std.debug.print("bid:{d} ", .{bid});
    const cards: [5]u8 = line[0..5].*;
    const hand = Hand{
        .bid = bid,
        .cards = cards,
        .strength = handStrength(cards),
    };
    return hand;
}

fn part1(lines: [][]u8) !usize {
    var hands = try allocator.alloc(Hand, lines.len);
    defer allocator.free(hands);

    for (lines, 0..) |line, i| {
        hands[i] = try parseHand(line);
    }

    var winnings: usize = 0;
    std.sort.insertion(Hand, hands, {}, cmpHandStrength);
    //std.debug.print("hands:{any}\n", .{hands});
    for (hands, 1..) |hand, i| {
        winnings += i * hand.bid;
    }
    std.debug.print("\nwinnings:\n  {d}\n", .{winnings});
    return winnings;
}
fn part2(lines: [][]u8) !usize {
    _ = lines;
    return 0;
}

test "part1 test" {
    const exampletext =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
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

    try std.testing.expectEqual(@as(@TypeOf(minloc), 6440), minloc);
}
test "part2 test" {
    const exampletext =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
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
