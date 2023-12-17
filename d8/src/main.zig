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
fn stepidx(steps: []u8, idx: usize) usize {
    return idx % steps.len;
}
fn direction(steps: []u8, idx: usize) Dir {
    if (steps[stepidx(steps, idx)] == 'L') return Dir.Left else return Dir.Right;
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

fn all_nodes_end_in_Z(nodes: []*Node) bool {
    for (nodes) |node| {
        if (node.name[2] == 'Z') continue else return false;
    }
    return true;
}
const NodeStep = struct {
    node: *Node,
    stepidx: usize,
    stepnum: usize = 0,
};
fn nodeInList(haystack: []NodeStep, needle: NodeStep) ?usize {
    for (haystack) |nd| if ((nd.node == needle.node) and (nd.stepidx == needle.stepidx)) return nd.stepnum;
    return null;
}
fn nodeInL(haystack: []NodeStep, needle: NodeStep) bool {
    for (haystack) |nd| if ((nd.node == needle.node) and (nd.stepidx == needle.stepidx)) return true;
    return false;
}
const StraightZs = struct {
    nodes: []NodeStep,
    terminator: ?NodeStep = null,
    startidx: usize,
    length: usize,
    modulus: usize,
};

fn getValue(runs: []StraightZs, cycles: []StraightZs, ghost: usize, index: usize) usize {
    const run = runs[ghost];
    const cycle = cycles[ghost];
    var idx = index;
    if (idx < run.nodes.len) {
        return run.nodes[idx].stepnum;
    } else {
        var numcycles: usize = 0;
        idx -= run.nodes.len;
        while (idx >= cycle.nodes.len) {
            numcycles += 1;
            idx -= cycle.nodes.len;
        }
        return cycle.nodes[idx].stepnum + numcycles * cycle.length;
    }
}

test "getValue returns stepnum for runs and for cycles" {
    var fknd = Node{};
    var runnodes = [3]NodeStep{
        .{ .stepnum = 3, .stepidx = 3, .node = &fknd },
        .{ .stepnum = 7, .stepidx = 7, .node = &fknd },
        .{ .stepnum = 10, .stepidx = 10, .node = &fknd },
    };
    var cyclenodes = [2]NodeStep{
        .{ .stepnum = 14, .stepidx = 14, .node = &fknd },
        .{ .stepnum = 23, .stepidx = 23, .node = &fknd },
    };
    var runs = [1]StraightZs{.{
        .length = 14,
        .startidx = 0,
        .nodes = runnodes[0..],
        .terminator = cyclenodes[0],
    }};
    var cycles = [1]StraightZs{.{
        .length = 19,
        .startidx = 14,
        .nodes = cyclenodes[0..],
    }};

    const steps = [_]usize{ 3, 7, 10, 14, 23, 33, 42, 52, 61, 71 };
    for (steps, 0..) |stepnum, i| {
        const res = getValue(runs[0..], cycles[0..], 0, i);
        try std.testing.expectEqual(@as(@TypeOf(res), stepnum), res);
    }
}

fn findStraightZs(startnode: *Node, startidx: usize, steps: []u8) !StraightZs {
    var k = startidx;
    var ends_in_z = std.ArrayList(NodeStep).init(allocator);
    var run = std.ArrayList(NodeStep).init(allocator);
    defer run.deinit();

    var node = NodeStep{ .node = startnode, .stepidx = stepidx(steps, k), .stepnum = k };
    while (nodeInList(run.items, node) == null) {
        const dir = direction(steps, k);
        //std.debug.print("\n{any}:{s}\n", .{ dir, node.node.name });
        try run.append(node);
        if (node.node.name[2] == 'Z') {
            try ends_in_z.append(node);
        }

        k += 1;

        const nd = if (dir == Dir.Left)
            node.node.left.?
        else
            node.node.right.?;

        node = NodeStep{ .node = nd, .stepidx = stepidx(steps, k), .stepnum = k };
    }
    return StraightZs{
        .nodes = ends_in_z.items,
        .startidx = startidx,
        .length = k - startidx,
        .terminator = node,
        .modulus = k - nodeInList(run.items, node).?,
    };
}

test "findStraightZs can return the straight and the cycle" {
    const exampletext =
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    ;
    allocator = advent.allocator_init(heap.page_allocator);
    defer advent.allocator_deinit();
    var readfile = std.ArrayList(u8).init(std.testing.allocator);
    defer readfile.deinit();
    try readfile.writer().writeAll(exampletext);
    var fbs = io.fixedBufferStream(readfile.items);
    var lines = try readlines(fbs.reader());

    const steps = lines.items[0];
    const tree = try parseTree(lines.items[2..]);
    const ghosts = try ghostsFromTree(tree);
    const run = try findStraightZs(ghosts[0], 0, steps);
    try std.testing.expectEqual(@as(usize, 2), run.nodes[0].stepnum);
    try std.testing.expectEqual(@as(usize, 0), run.startidx);
    try std.testing.expectEqual(@as(usize, 3), run.length);
    const cycle = try findStraightZs(run.terminator.?.node, run.length, steps);
    try std.testing.expectEqual(@as(usize, 4), cycle.nodes[0].stepnum);
    try std.testing.expectEqual(@as(usize, 3), cycle.startidx);
    try std.testing.expectEqual(@as(usize, 2), cycle.length);
}

fn ghostsFromTree(tree: NodeMap) ![]*Node {
    var nodelist = std.ArrayList(*Node).init(allocator);
    var ki = tree.keyIterator();
    while (ki.next()) |key| {
        //std.debug.print("key:{s}\n", .{key.*});
        if (key.*[2] == 'A') {
            try nodelist.append(tree.getPtr(key.*).?);
        }
    }
    return nodelist.items;
}

fn findCommon(ghostruns: []StraightZs, ghostcycles: []StraightZs) usize {
    var lastidx = allocator.alloc(usize, ghostruns.len) catch unreachable;
    @memset(lastidx, 0);
    defer allocator.free(lastidx);
    var maxstepnum: usize = 0;
    //std.debug.print("ghosts:{d}\n", .{ghostruns.len});
    while (true) {
        var ghosts_at_max: usize = 0;
        for (0..ghostruns.len) |ghost| {
            var stepnum = getValue(ghostruns, ghostcycles, ghost, lastidx[ghost]);
            //std.debug.print("stepnum{d}:{d}\n", .{ ghost, stepnum });
            if (stepnum < maxstepnum) {
                lastidx[ghost] += 1;
            } else if (stepnum > maxstepnum) {
                maxstepnum = stepnum;
            } else {
                ghosts_at_max += 1;
            }
        }
        //std.debug.print("stepnum:{d}, ghosts_at_max:{d}\n", .{ maxstepnum, ghosts_at_max });
        if (ghosts_at_max == ghostruns.len) return maxstepnum;
    }
}

fn allKeyNodesContain(keynodes: []StraightZs, stepnum: usize) bool {
    for (keynodes) |kn| {
        for (kn.nodes) |np| {
            if (np.stepnum == stepnum) break;
        } else return false;
    }
    return true;
}

fn sortFnDescending(a: usize, b: usize) bool {
    return a > b;
}
fn lcm(a: usize, b: usize) usize {
    if (a == 0) return b;
    if (b == 0) return a;
    const gcd = std.math.gcd(a, b);
    return a * b / gcd;
}
fn lcms(values: []usize) usize {
    //std.sort.insertion(usize, values, {}, sortFnDescending);
    var lcmacc: usize = lcm(values[0], values[1]);
    for (values[2..]) |val| {
        lcmacc = lcm(lcmacc, val);
    }
    return lcmacc;
}

fn part2(lines: [][]u8) !usize {
    const steps = lines[0];
    const tree = try parseTree(lines[2..]);
    const ghosts = try ghostsFromTree(tree);
    //for (ghosts) |nd| std.debug.print("nd:{any}\n", .{nd.*});

    var ghostruns = std.ArrayList(StraightZs).init(allocator);

    var lcmacc: usize = 0;
    for (ghosts) |nd| {
        const run = try findStraightZs(nd, 0, steps);
        try ghostruns.append(run);
        lcmacc = lcm(lcmacc, run.modulus);

        std.debug.print("\nRun len:{d}\n", .{run.length});
        std.debug.print("Run modulus:{d}\n", .{run.modulus});
        std.debug.print("Run lcm:{d}\n", .{lcmacc});
        std.debug.print("ends_in_z_run:{any}\n", .{run.nodes});
    }

    // std.debug.print("\n:\n", .{});
    // std.debug.print("runs:   {any}\n", .{ghostruns.items});
    // std.debug.print("cycles: {any}\n", .{ghostcycles.items});

    var numsteps: usize = 0;
    std.debug.print("\nnumsteps:\n  {d}\n", .{numsteps});
    return numsteps;
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
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
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

    try std.testing.expectEqual(@as(@TypeOf(minloc), 6), minloc);
}
