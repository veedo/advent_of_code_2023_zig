const std = @import("std");
const heap = std.heap;
const io = std.io;
const Tuple = std.meta.Tuple;
var arena: std.heap.ArenaAllocator = undefined;
var allocator: std.mem.Allocator = undefined;

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

    //var lines = try readlines(stdin);
    //var conds = std.AutoHashMap(DiceColour, u8).init(allocator);
    //try conds.put(DiceColour.red, 12);
    //try conds.put(DiceColour.green, 13);
    //try conds.put(DiceColour.blue, 14);
    //var sum: usize = 0;
    //for (lines.items) |line| {
    //    //std.debug.print("line: {s}\n", .{line});
    //    const game = try parseGame(line);
    //    //std.debug.print("line: {any}\n", .{game});
    //    if (isValidGame(game, conds)) sum += game.id;
    //}
    //try stdout.print("{d}\n", .{sum});

    var lines = try readlines(stdin);
    var powersum: u64 = 0;
    for (lines.items) |line| {
        const game = try parseGame(line);
        powersum += @intCast(gamePower(game));
    }
    try stdout.print("{d}\n", .{powersum});

    try bw.flush();
}

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

const DiceColour = enum {
    blue,
    red,
    green,
};

const Dice = union(DiceColour) {
    blue: u8,
    red: u8,
    green: u8,
};

const Game = struct {
    id: u8,
    rounds: std.ArrayList(std.ArrayList(Dice)),
};

fn parseDice(text: []const u8) ?Dice {
    const spaceidx = std.mem.indexOf(u8, text, " ") orelse return null;
    const numdice = std.fmt.parseInt(u8, text[0..spaceidx], 10) catch return null;
    if (std.mem.eql(u8, text[spaceidx + 1 ..], "blue"))
        return Dice{ .blue = numdice }
    else if (std.mem.eql(u8, text[spaceidx + 1 ..], "red"))
        return Dice{ .red = numdice }
    else if (std.mem.eql(u8, text[spaceidx + 1 ..], "green"))
        return Dice{ .green = numdice }
    else
        return null;
}

fn parseGame(line: []u8) !Game {
    var pline = line;
    //std.debug.print("\nline: {s}, {d}, {d}\n", .{ line, (std.mem.indexOf(u8, pline, " ") orelse 0), (std.mem.indexOf(u8, pline, ":") orelse 0) });
    pline = pline[((std.mem.indexOf(u8, pline, " ") orelse 0) + 1)..];
    //std.debug.print("pline: {s}\n", .{pline});
    const numend = std.mem.indexOf(u8, pline, ":") orelse 0;
    //std.debug.print("num: {s}\n", .{pline[0..(numend)]});
    const id = try std.fmt.parseInt(u8, pline[0..(numend)], 10);
    //std.debug.print("id: {d}\n", .{id});
    pline = pline[(numend + 2)..];
    //std.debug.print("pline: {s}\n", .{pline});
    var rounds = std.ArrayList(std.ArrayList(Dice)).init(allocator);
    var roundstrings = std.mem.splitSequence(u8, pline, "; ");
    while (roundstrings.next()) |roundstring| {
        //std.debug.print("newround\n", .{});
        var round = std.ArrayList(Dice).init(allocator);
        var dicestrings = std.mem.splitSequence(u8, roundstring, ", ");
        while (dicestrings.next()) |dicestring| {
            const dice = parseDice(dicestring);
            //            std.debug.print("dicestring: {s} - {any}\n", .{ dicestring, dice });
            try round.append(dice orelse continue);
        }
        try rounds.append(round);
    }

    return Game{
        .id = id,
        .rounds = rounds,
    };
}

fn isValidGame(game: Game, conditions: std.AutoHashMap(DiceColour, u8)) bool {
    for (game.rounds.items) |round| {
        for (round.items) |dice| {
            switch (dice) {
                .green => |v| if (v > conditions.get(DiceColour.green) orelse 0) return false,
                .red => |v| if (v > conditions.get(DiceColour.red) orelse 0) return false,
                .blue => |v| if (v > conditions.get(DiceColour.blue) orelse 0) return false,
            }
        }
    }
    return true;
}

fn gamePower(game: Game) u32 {
    var maxred: u32 = 0;
    var maxgreen: u32 = 0;
    var maxblue: u32 = 0;

    for (game.rounds.items) |round| {
        for (round.items) |dice| {
            switch (dice) {
                .green => |v| maxgreen = @max(maxgreen, v),
                .red => |v| maxred = @max(maxred, v),
                .blue => |v| maxblue = @max(maxblue, v),
            }
        }
    }
    return maxred * maxgreen * maxblue;
}

test "parse test" {
    const exampletext =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
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
    var conds = std.AutoHashMap(DiceColour, u8).init(allocator);
    try conds.put(DiceColour.red, 12);
    try conds.put(DiceColour.green, 13);
    try conds.put(DiceColour.blue, 14);
    var sum: usize = 0;
    for (lines.items) |line| {
        //std.debug.print("line: {s}\n", .{line});
        const game = try parseGame(line);
        //std.debug.print("line: {any}\n", .{game});
        if (isValidGame(game, conds)) sum += game.id;
    }

    try std.testing.expect(sum == 8);
}
test "parse part two test" {
    const exampletext =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
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
    var powersum: u64 = 0;
    for (lines.items) |line| {
        //std.debug.print("line: {s}\n", .{line});
        const game = try parseGame(line);
        std.debug.print("sum: {d}\n", .{powersum});
        powersum += @intCast(gamePower(game));
    }

    try std.testing.expectEqual(powersum, 2286);
}
