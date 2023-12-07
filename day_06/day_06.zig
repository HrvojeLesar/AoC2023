const std = @import("std");

const Race = struct {
    time: u64,
    distance: u64,

    pub fn waysToBeat(self: *const Race) u64 {
        var n: u64 = 0;
        for (1..self.time) |time_held| {
            var distance_traveled = time_held * (self.time - time_held);
            if (distance_traveled > self.distance) {
                n += 1;
            }
        }
        return n;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var times_distances = std.ArrayList(u64).init(allocator);
    var p2 = std.ArrayList(u8).init(allocator);
    var p2_race = Race{ .distance = 0, .time = 0 };
    var is_first = true;
    while (true) {
        var line = std.ArrayList(u8).init(allocator);
        defer line.deinit();
        in_stream.streamUntilDelimiter(line.writer(), '\n', null) catch break;
        var line_iter = std.mem.splitSequence(u8, line.items, " ");
        _ = line_iter.next();
        while (line_iter.next()) |line_char| {
            if (line_char.len == 0) {
                continue;
            }
            var number = try std.fmt.parseInt(u64, line_char, 10);
            try times_distances.append(number);
        }
        line_iter.reset();
        _ = line_iter.next();
        while (line_iter.next()) |line_char| {
            if (line_char.len == 0) {
                continue;
            }
            for (line_char) |char| {
                try p2.append(char);
            }
        }
        if (is_first) {
            p2_race.time = try std.fmt.parseInt(u64, p2.items, 10);
            is_first = false;
            p2.clearRetainingCapacity();
        } else {
            p2_race.distance = try std.fmt.parseInt(u64, p2.items, 10);
        }
    }

    var races = std.ArrayList(Race).init(allocator);
    for (0..times_distances.items.len / 2) |i| {
        var j = i + times_distances.items.len / 2;
        try races.append(Race{ .time = times_distances.items[i], .distance = times_distances.items[j] });
    }
    times_distances.deinit();

    var res: u64 = 0;
    for (races.items) |race| {
        if (res == 0) {
            res = race.waysToBeat();
        } else {
            res *= race.waysToBeat();
        }
    }
    std.debug.print("P1: {d}\n", .{res});
    std.debug.print("P2: {d}\n", .{p2_race.waysToBeat()});
}
