const std = @import("std");

pub fn main() !void {
    try solve();
}

fn solve() anyerror!void {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var sum: i64 = 0;

    var current_card_idx: i64 = 0;
    var multipliers = try std.ArrayList(i64).initCapacity(allocator, 223);
    for (0..223) |_| {
        try multipliers.append(1);
    }

    while (true) {
        var line = std.ArrayList(u8).init(allocator);
        in_stream.streamUntilDelimiter(line.writer(), '\n', null) catch break;
        var iter = std.mem.splitSequence(u8, line.items, " | ");
        var winning_numbers_side = iter.next().?;
        var my_numbers_string = iter.next().?;

        var wns_iter = std.mem.splitSequence(u8, winning_numbers_side, ": ");
        _ = wns_iter.next();
        var winning_numbers_string = wns_iter.next().?;

        var win_iter = std.mem.splitSequence(u8, winning_numbers_string, " ");
        var my_numbers_iter = std.mem.splitSequence(u8, my_numbers_string, " ");

        var thunder: i64 = 0;
        var winning_count: i64 = 0;
        while (my_numbers_iter.next()) |m| {
            if (m.len == 0) {
                continue;
            }
            var my_number: i64 = try std.fmt.parseInt(i64, std.mem.trim(u8, m, " "), 10);
            while (win_iter.next()) |win| {
                if (win.len == 0) {
                    continue;
                }
                var winning_number: i64 = try std.fmt.parseInt(i64, std.mem.trim(u8, win, " "), 10);
                if (winning_number == my_number) {
                    winning_count += 1;
                    if (thunder == 0) {
                        thunder = 1;
                    } else {
                        thunder *= 2;
                    }
                }
            }
            win_iter.reset();
        }
        sum += thunder;

        var curr: usize = @intCast(current_card_idx);
        var from: usize = @intCast(current_card_idx + 1);
        var to: usize = @intCast(current_card_idx + 1 + winning_count);
        for (from..to) |i| {
            multipliers.items[i] += 1 * multipliers.items[curr];
        }
        current_card_idx += 1;
    }

    std.debug.print("Part 1: {d}\n", .{sum});

    var sum_2: i64 = 0;
    for (multipliers.items) |m| {
        sum_2 += m;
    }
    std.debug.print("Part 2: {d}\n", .{sum_2});
}
