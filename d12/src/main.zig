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

    try bw.flush();
}

fn parse_line(line: []u8) !struct { record: []u8, groups: []u8 } {
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
            std.log.debug("rld:{s}\n", .{record.*});
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
            std.log.debug("rtd:{s}\n", .{record.*});
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
            std.log.debug("rcd:{s}\n", .{record.*});
            continue;
        }
        i += 1;
    }
    return changed;
}

fn set_record(record_mask: u64, startidx: u8, length: u8, fill: u8) u64 {
    var msk = record_mask;
    const mfill: u64 = @intCast(fill & 0b11);
    for (startidx..(startidx + length)) |i| {
        msk &= ~(@as(u64, 0b11) << @intCast(2 * i));
        msk |= mfill << @intCast(2 * i);
    }
    return msk;
}

fn reset_record(record_mask: u64, startidx: u8, length: u8) u64 {
    var msk = record_mask;
    for (startidx..(startidx + length)) |i| {
        msk &= ~(0b11 << @intCast(2 * i));
    }
    return msk;
}

fn print_record_mask(record_mask: u64) void {
    if (!std.log.logEnabled(std.log.Level.debug, std.log.default_log_scope)) return;
    for (0..32) |i| {
        const v = ((record_mask >> @intCast(2 * i)) & 0b11);
        switch (v) {
            0b00 => std.debug.print("?", .{}),
            0b01 => std.debug.print(".", .{}),
            0b10 => std.debug.print("#", .{}),
            0b11 => std.debug.print("!", .{}),
            else => unreachable,
        }
    }
    std.debug.print("\n", .{});
}

fn valid_record_mask(record_mask: u64) bool {
    for (0..32) |i| {
        const v = ((record_mask >> @intCast(2 * i)) & 0b11);
        if (v == 0b11) return false;
    }
    return true;
}

// 0b10 = #
// 0b01 = .
// 0b00 = ?
// 0b11 = invalid
fn fill_record(acc: usize, record_mask: u64, groups: []u8, startidx: u8, length: u8, record: u64) usize {
    var lacc = acc;
    const grp = groups[0];
    const rest = groups[1..];
    var maxidx = length - (min_line_length(rest) orelse 0) - grp + 1;
    var rmsk = set_record(record_mask, startidx, length - startidx, 0b01);
    std.log.debug("flr:0x{X:0>4},grp:{d},rst:{any},stt:{d},len:{d},max:{d}\n", .{ rmsk, grp, rest, startidx, length, maxidx });
    for (startidx..maxidx) |i| {
        rmsk = set_record(rmsk, @intCast(i), grp, 0b10);
        if (rest.len > 0) {
            lacc = fill_record(lacc, rmsk, rest, @intCast(i + grp + 1), length, record);
        } else {
            //std.log.debug("rec:", .{});
            //print_record_mask(record);
            //std.log.debug("flr:", .{});
            //print_record_mask(rmsk);
            const comp = rmsk | record;
            //std.log.debug("cmp:", .{});
            //print_record_mask(comp);
            if (valid_record_mask(comp)) {
                lacc += 1;
                std.log.debug("valid! acc={d}\n", .{lacc});
            }
        }
        rmsk = set_record(rmsk, @intCast(i), 1, 0b01);
    }
    return lacc;
}

fn record_to_mask(record: []u8) u64 {
    var rec: u64 = 0;
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

fn part1(lines: [][]u8) !usize {
    var combinations: usize = 0;
    lineblk: for (lines) |line| {
        var parsed = try parse_line(line);
        var groups = parsed.groups;
        var record = parsed.record;
        std.log.debug("\nrec:{s},grps:{any}\n", .{ record, groups });

        _ = remove_leading_dots(&record);
        _ = remove_trailing_dots(&record);
        _ = remove_contiguous_dots(&record);

        var something_eliminated = true;
        var reversed = false;
        eliminate_blk: while (something_eliminated) {
            something_eliminated = false;
            something_eliminated = remove_leading_dots(&record) or something_eliminated;

            // Check if record can only fit one combination
            if (groups.len == 0 or record.len <= min_line_length(groups).?) {
                combinations += 1;
                std.log.debug("Len match\n", .{});
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
                std.log.debug("rec:{s},grps:{any}\n", .{ record, groups });
            }

            // Eliminate groups that are fully represented at the start
            if (record[1] == '#' and groups[0] == 1) {
                // G1 -> ?#?
                if (record.len <= 3) {
                    combinations += 1;
                    std.log.debug("Len match\n", .{});
                    continue :lineblk;
                }
                record = record[3..];
                groups = groups[1..];
                something_eliminated = true;
                _ = remove_leading_dots(&record);
                std.log.debug("rec:{s},grps:{any}\n", .{ record, groups });
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
                            std.log.debug("rec:{s},grps:{any}\n", .{ record, groups });
                            break;
                        }
                    } else if (ch == '.' and i < groups[0]) {
                        record = record[(i + 1)..];
                        something_eliminated = true;
                        _ = remove_leading_dots(&record);
                        std.log.debug("rec:{s}\n", .{record});
                        break;
                    }
                }
            }

            if ((!something_eliminated) and (!reversed)) {
                std.log.debug("Try Reverse\n", .{});
                mem.reverse(u8, record);
                mem.reverse(u8, groups);
                something_eliminated = true;
                reversed = true;
                std.log.debug("rec:{s},grps:{any}\n", .{ record, groups });
            }
        }

        std.log.debug("rec:{s},grps:{any}\n", .{ record, groups });
        combinations += fill_record(0, 0, groups, 0, @intCast(record.len), record_to_mask(record));
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

        var res: usize = try part1(lines.items);

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

        var res: usize = try part1(lines.items);

        try std.testing.expectEqual(@as(@TypeOf(res), 21), res);
    }
}
