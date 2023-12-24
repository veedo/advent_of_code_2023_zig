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

pub fn dummydebug(
    comptime format: []const u8,
    args: anytype,
) void {
    _ = args;
    _ = format;
}
//const dbgprint = std.debug.print;
//const dbgprint = std.log.debug;
const dbgprint = dummydebug;

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

    _ = try find_combinations(lines.items, &parse_line2);

    try bw.flush();
}

const Record = std.PackedIntArray(u2, 128);

const ParseLineError = (std.fmt.ParseIntError || mem.Allocator.Error);
const ParseLineReturn = struct { record: []u8, groups: []u8 };
const FnParseLine = *const fn (line: []u8) ParseLineError!ParseLineReturn;
fn parse_line(line: []u8) ParseLineError!ParseLineReturn {
    const splitidx = std.mem.indexOf(u8, line, " ").?;
    const record = line[0..splitidx];
    var groups_tkn = std.mem.tokenize(u8, line[splitidx + 1 ..], ",");
    var groups = std.ArrayList(u8).init(allocator);
    while (groups_tkn.next()) |txt| {
        const grp = try std.fmt.parseInt(u8, txt, 10);
        try groups.append(grp);
    }
    return .{ .record = record, .groups = groups.items };
}

// 1234 ?1234 ?1234 ?1234?1234?
// 1234 51234 51234 5
// 1234 56789 01234 5
fn parse_line2(line: []u8) ParseLineError!ParseLineReturn {
    dbgprint("lin:{s}\n", .{line});
    const splitidx = std.mem.indexOf(u8, line, " ").?;
    const record = line[0..splitidx];
    var unfolded_record = try allocator.alloc(u8, record.len * 5 + 4);
    @memcpy(unfolded_record[0..record.len], record);
    for (0..4) |i| {
        const k = record.len + (record.len + 1) * i;
        unfolded_record[k] = '?';
        @memcpy(unfolded_record[(k + 1)..(k + record.len + 1)], record);
    }

    var groupsread = [_]u8{0} ** 8;
    var groups_tkn = std.mem.tokenize(u8, line[splitidx + 1 ..], ",");
    var gidx: usize = 0;
    while (groups_tkn.next()) |txt| : (gidx += 1) {
        const grp = try std.fmt.parseInt(u8, txt, 10);
        groupsread[gidx] = grp;
    }
    var groups = std.ArrayList(u8).init(allocator);
    for (0..5) |_| {
        for (groupsread[0..gidx]) |grp| {
            try groups.append(grp);
        }
    }
    return .{ .record = unfolded_record, .groups = groups.items };
}

fn min_line_length(groups: []u8) ?u8 {
    if (groups.len == 0) return null;
    var sum: u8 = @intCast(groups.len - 1);
    for (groups) |grp| sum += grp;
    return sum;
}

fn remove_leading_dots(record: *[]u8) bool {
    var changed = false;
    while (record.len > 0) {
        if (record.*[0] == '.') {
            record.* = record.*[1..];
            changed = true;
            dbgprint("rld:{s}\n", .{record.*});
        } else {
            return changed;
        }
    }
    return changed;
}

fn remove_trailing_dots(record: *[]u8) bool {
    var changed = false;
    while (record.len > 0) {
        if (record.*[record.len - 1] == '.') {
            record.* = record.*[0..(record.len - 1)];
            changed = true;
            dbgprint("rtd:{s}\n", .{record.*});
        } else {
            return changed;
        }
    }
    return changed;
}

fn remove_contiguous_dots(record: *[]u8) bool {
    var changed = false;
    var i: usize = 1;
    while (i < (record.len - 1)) {
        if (record.*[i] == '.' and record.*[i + 1] == '.') {
            mem.copyForwards(u8, record.*[i..], record.*[i + 1 ..]);
            record.* = record.*[0..(record.len - 1)];
            changed = true;
            dbgprint("rcd:{s}\n", .{record.*});
            continue;
        }
        i += 1;
    }
    return changed;
}

const RecordMask = u512;
fn set_record(record_mask: RecordMask, startidx: usize, length: usize, fill: u8) RecordMask {
    var msk = record_mask;
    const mfill: RecordMask = @intCast(fill & 0b11);
    for (startidx..(startidx + length)) |i| {
        msk &= ~(@as(RecordMask, 0b11) << @intCast(2 * i));
        msk |= mfill << @intCast(2 * i);
    }
    return msk;
}

fn mask_record(record_mask: RecordMask, length: usize) RecordMask {
    const msk: RecordMask = @as(RecordMask, std.math.maxInt(RecordMask)) >> @intCast(@bitSizeOf(RecordMask) - length * 2);
    const msked: RecordMask = record_mask & (msk);
    return msked;
}

fn reset_record(record_mask: RecordMask, startidx: usize, length: usize) RecordMask {
    var msk = record_mask;
    for (startidx..(startidx + length)) |i| {
        msk &= ~(0b11 << @intCast(2 * i));
    }
    return msk;
}

fn print_record_mask(record_mask: RecordMask) void {
    if (dbgprint == dummydebug) return;
    if (!std.log.logEnabled(std.log.Level.debug, std.log.default_log_scope)) return;
    for (0..32) |i| {
        const v = ((record_mask >> @intCast(2 * i)) & 0b11);
        switch (v) {
            0b00 => dbgprint("?", .{}),
            0b01 => dbgprint(".", .{}),
            0b10 => dbgprint("#", .{}),
            0b11 => dbgprint("!", .{}),
            else => unreachable,
        }
    }
    dbgprint("\n", .{});
}

const MemoKeySize = 256;
const MemoKey = struct {
    memokey: RecordMask,
    len_remaining: usize,
    groups: [16]u5,
};
const MemoMap = std.AutoHashMap(MemoKey, usize);
var memos: MemoMap = undefined;
fn memokey(record_mask: RecordMask, startidx: usize, length: usize, groups: []u8) ?MemoKey {
    const len_remaining = length - startidx;
    if (groups.len > 16) return null;
    if (groups.len < 1) return null;
    if (len_remaining < 1) return null;

    dbgprint("rec:0x{X},stt:{d},len:{d},grp:{any}\n", .{ record_mask, startidx, length, groups });
    const rec = mask_record(record_mask, length) >> @intCast(startidx * 2);
    var key = MemoKey{ .memokey = rec, .len_remaining = len_remaining, .groups = undefined };
    for (groups, 0..) |grp, i| {
        key.groups[i] = @intCast(grp);
    }
    dbgprint("key:{any}\n", .{key});
    return key;
}

fn memoized_solution(record_mask: RecordMask, startidx: usize, length: usize, groups: []u8) ?usize {
    const key = memokey(record_mask, startidx, length, groups) orelse return null;
    const val = memos.get(key) orelse return null;
    dbgprint("memo:0x{X},stt:{d},len:{d},grp:{any},result:{d}\n", .{ record_mask, startidx, length, groups, val });
    return val;
}

fn memoize(record_mask: RecordMask, startidx: usize, length: usize, groups: []u8, result: usize) !void {
    const key = memokey(record_mask, startidx, length, groups) orelse return;
    dbgprint("mem:stt:{d},len:{d},groups:{any},res:{d}\n", .{ startidx, length, groups, result });
    print_record_mask(record_mask);
    try memos.put(key, result);
}

// 0b10 = #
// 0b01 = .
// 0b00 = ?
// 0b11 = invalid
fn fill_record(acc: usize, record_mask: RecordMask, groups: []u8, startidx: usize, length: usize, record: RecordMask) usize {
    const memres = memoized_solution(record, startidx, length, groups);
    if (memres != null) return memres.?;
    var lacc = acc;
    const grp = groups[0];
    const rest = groups[1..];
    var maxidx = length - (min_line_length(rest) orelse 0) - grp + 1;
    var rmsk = set_record(record_mask, startidx, length - startidx, 0b01);
    dbgprint("flr:0x{X:0>4},grp:{d},rst:{any},stt:{d},len:{d},max:{d}\n", .{ rmsk, grp, rest, startidx, length, maxidx });
    for (startidx..maxidx) |i| {
        rmsk = set_record(rmsk, @intCast(i), grp, 0b10);
        const progress_mask = mask_record(record, i + grp);
        const progress = mask_record(rmsk, i + grp);
        dbgprint("rec:", .{});
        print_record_mask(record);
        dbgprint("    ", .{});
        print_record_mask(progress_mask);
        dbgprint("prg:", .{});
        print_record_mask(rmsk);
        dbgprint("    ", .{});
        print_record_mask(progress);
        dbgprint("    ", .{});
        print_record_mask(progress | progress_mask);
        if ((progress | progress_mask) == progress) {
            if (rest.len > 0) {
                const stidx: usize = @intCast(i + grp + 1);
                const res = fill_record(0, rmsk, rest, stidx, length, record);
                lacc += res;
            } else {
                lacc += 1;
                dbgprint("valid! acc={d}\n", .{lacc});
            }
        }
        rmsk = set_record(rmsk, @intCast(i), 1, 0b01);
    }
    memoize(record, startidx, length, groups, lacc) catch unreachable;
    return lacc;
}

fn record_to_mask(record: []u8) RecordMask {
    var rec: RecordMask = 0;
    for (record, 0..) |r, i| {
        const v: u8 = switch (r) {
            '?' => 0b00,
            '.' => 0b01,
            '#' => 0b10,
            '!' => 0b11,
            else => unreachable,
        };
        rec = set_record(rec, @intCast(i), 1, v);
    }
    return rec;
}

fn find_combinations(lines: [][]u8, fn_parser: FnParseLine) !usize {
    memos = MemoMap.init(allocator);
    var combinations: usize = 0;

    var largest_group: u8 = 0;
    var largest_record: usize = 0;

    lineblk: for (lines) |line| {
        var parsed = try fn_parser(line);
        var groups = parsed.groups;
        var record = parsed.record;
        dbgprint("\nrec:{s},grps:{any}\n", .{ record, groups });
        std.debug.print("\nreclen:{d} grplen:{d}\n", .{ record.len, groups.len });
        for (groups) |grp| largest_group = @max(largest_group, grp);
        largest_record = @max(largest_record, record.len);

        _ = remove_leading_dots(&record);
        _ = remove_trailing_dots(&record);
        _ = remove_contiguous_dots(&record);

        std.debug.print("reclen:{d} grplen:{d}\n", .{ record.len, groups.len });
        if (true) continue;

        var something_eliminated = true;
        var reversed = false;
        eliminate_blk: while (something_eliminated) {
            something_eliminated = false;
            something_eliminated = remove_leading_dots(&record) or something_eliminated;

            // Check if record can only fit one combination
            if (groups.len == 0 or record.len <= min_line_length(groups).?) {
                combinations += 1;
                std.debug.print("combos:{d}\n", .{combinations});
                dbgprint("Len match\n", .{});
                continue :lineblk;
            }

            // Eliminate all starting patterns that begin with #
            while (record[0] == '#' or (record[1] == '#' and record[groups[0]] == '.')) {
                // G1 -> #?
                // G2 -> ##? / ?#.
                // G3 -> ###? / ?##.
                // G4 -> ####? / ?###.
                record = record[(groups[0] + 1)..];
                groups = groups[1..];
                something_eliminated = true;
                if (groups.len == 0) continue :eliminate_blk;
                _ = remove_leading_dots(&record);
                if (record.len <= min_line_length(groups).?) continue :eliminate_blk;
                dbgprint("rec:{s},grps:{any}\n", .{ record, groups });
            }

            // Eliminate groups that are fully represented at the start
            if (record[1] == '#' and groups[0] == 1) {
                // G1 -> ?#?
                if (record.len <= 3) {
                    combinations += 1;
                    std.debug.print("combos:{d}\n", .{combinations});
                    dbgprint("Len match\n", .{});
                    continue :lineblk;
                }
                record = record[3..];
                groups = groups[1..];
                something_eliminated = true;
                _ = remove_leading_dots(&record);
                dbgprint("rec:{s},grps:{any}\n", .{ record, groups });
            }

            if (groups.len > 0) {
                // G2 -> ?##? / ??##?
                // G3 -> ?###? / ??###? / ???###?
                // G4 -> ?####? / ??####? / ???####? / ????####?
                // Track first match to handle:
                // G2 -> ?#?#
                // G3 -> ?##?# / ?#?#?#?
                // G4 -> ?####?# / ?#?##?#? / ?#?#?#?#?
                const maxcheck = @min(groups[0] * 2, record.len);
                var num_found: usize = 0;
                var first_match: usize = 0;
                for (record[1..maxcheck], 1..) |ch, i| {
                    if (i >= (first_match + groups[0])) break;
                    if (ch == '#') {
                        if (first_match == 0) first_match = @intCast(i);
                        num_found += 1;
                        if (num_found == groups[0]) {
                            record = record[(i + 2)..];
                            groups = groups[1..];
                            something_eliminated = true;
                            _ = remove_leading_dots(&record);
                            dbgprint("rec:{s},grps:{any}\n", .{ record, groups });
                            break;
                        }
                    } else if (ch == '.' and i < groups[0]) {
                        record = record[(i + 1)..];
                        something_eliminated = true;
                        _ = remove_leading_dots(&record);
                        dbgprint("rec:{s}\n", .{record});
                        break;
                    }
                }
            }

            if ((!something_eliminated) and (!reversed)) {
                dbgprint("Try Reverse\n", .{});
                mem.reverse(u8, record);
                mem.reverse(u8, groups);
                something_eliminated = true;
                reversed = true;
                dbgprint("rec:{s},grps:{any}\n", .{ record, groups });
            }
        }

        dbgprint("rec:{s},grps:{any}\n", .{ record, groups });
        combinations += fill_record(0, 0, groups, 0, @intCast(record.len), record_to_mask(record));
        std.debug.print("combos:{d}\n", .{combinations});
    }
    std.debug.print("\nsum:\n  {d}\n", .{combinations});
    return combinations;
}

test "part1 test" {
    const exampletext =
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
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

        var res: usize = try find_combinations(lines.items, &parse_line);

        try std.testing.expectEqual(@as(@TypeOf(res), 21), res);
    }
}

test "part2 test" {
    const exampletext =
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
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

        var res: usize = try find_combinations(lines.items, &parse_line2);

        try std.testing.expectEqual(@as(@TypeOf(res), 525152), res);
    }
}
