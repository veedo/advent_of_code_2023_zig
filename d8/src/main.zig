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

const Node = struct {
    name: []u8,
    left: ?*Node = null,
    right: ?*Node = null,
};
const NodeMap = std.StringHashMap(Node);
fn parseTree(lines: [][]u8) !NodeMap {
    var nm = NodeMap.init(allocator);
    for (lines) |line| {
        const nodename = line[0..3];
        try nm.put(nodename, Node{ .name = nodename });
    }
    for (lines) |line| {
        const nodename = line[0..3];
        const left = line[7..10];
        const right = line[12..15];
        const ln = nm.getPtr(left).?;
        const rn = nm.getPtr(right).?;
        const nn = nm.getPtr(nodename).?;
        nn.left = ln;
        nn.right = rn;
    }
    return nm;
}

const Dir = enum {
    Left,
    Right,
};
fn direction(steps: []u8, idx: usize) Dir {
    const ridx = idx % steps.len;
    if (steps[ridx] == 'L') return Dir.Left else return Dir.Right;
}

fn part1(lines: [][]u8) !usize {
    const steps = lines[0];
    const tree = try parseTree(lines[2..]);
    //std.debug.print("{any}\n", .{tree});
    var node = tree.getPtr("AAA").?;
    var numsteps: usize = 0;
    while (!mem.eql(u8, node.name, "ZZZ")) {
        if (direction(steps, numsteps) == Dir.Left) {
            //std.debug.print("L: {s}L{s}\n", .{ node.name, node.left.?.name });
            node = node.left.?;
        } else {
            //std.debug.print("R: {s}R{s}\n", .{ node.name, node.right.?.name });
            node = node.right.?;
        }

        numsteps += 1;
    }

    std.debug.print("\nnumsteps:\n  {d}\n", .{numsteps});
    return numsteps;
}
fn part2(lines: [][]u8) !usize {
    _ = lines;
    return 0;
}

test "part1 test" {
    const exampletext1 =
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    const exampletext2 =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;

    std.debug.print("\n", .{});
    allocator = advent.allocator_init(heap.page_allocator);
    defer advent.allocator_deinit();

    {
        var readfile = std.ArrayList(u8).init(std.testing.allocator);
        defer readfile.deinit();
        try readfile.writer().writeAll(exampletext1);
        var fbs = io.fixedBufferStream(readfile.items);
        var lines = try readlines(fbs.reader());

        var res: usize = try part1(lines.items);

        try std.testing.expectEqual(@as(@TypeOf(res), 2), res);
    }
    {
        var readfile = std.ArrayList(u8).init(std.testing.allocator);
        defer readfile.deinit();
        try readfile.writer().writeAll(exampletext2);
        var fbs = io.fixedBufferStream(readfile.items);
        var lines = try readlines(fbs.reader());

        var res: usize = try part1(lines.items);

        try std.testing.expectEqual(@as(@TypeOf(res), 6), res);
    }
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

    try std.testing.expectEqual(@as(@TypeOf(minloc), 5905), minloc);
}
