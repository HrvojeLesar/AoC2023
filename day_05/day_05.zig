const std = @import("std");

const Range = struct {
    destination: u64,
    source: u64,
    range_length: u64,

    pub fn new(range_stringified: []const u8) anyerror!Range {
        var range = Range{ .source = 0, .destination = 0, .range_length = 0 };

        var range_iter = std.mem.split(u8, range_stringified, " ");

        range.destination = try std.fmt.parseInt(u64, range_iter.next().?, 10);
        range.source = try std.fmt.parseInt(u64, range_iter.next().?, 10);
        range.range_length = try std.fmt.parseInt(u64, range_iter.next().?, 10);

        return range;
    }

    pub fn transform(self: *const Range, num: *u64) bool {
        if (num.* >= self.source and num.* <= self.source + self.range_length) {
            var distance = num.* - self.source;
            num.* = self.destination + distance;
            return true;
        }
        return false;
    }

    pub fn canTransform(self: *const Range, num: u64) bool {
        if (num >= self.source and num <= self.source + self.range_length) {
            return true;
        }
        return false;
    }

    pub fn rangeFilterCount(self: *const Range, seed_start: u64, seed_end: u64) u64 {
        var range_max = self.range_length
        return range_end - num;
    }
};

const Map = enum(u8) {
    seed_to_soil = 0,
    soil_to_fertilizer = 1,
    fertilizer_to_water = 2,
    water_to_light = 3,
    light_to_temperature = 4,
    temperature_to_humidity = 5,
    humidity_to_location = 6,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var map_map = std.ArrayList(std.ArrayList(Range)).init(allocator);
    var seeds = std.ArrayList(u64).init(allocator);

    while (true) {
        var line = std.ArrayList(u8).init(allocator);
        defer line.deinit();
        in_stream.streamUntilDelimiter(line.writer(), '\n', null) catch break;
        if (line.items.len == 0) {
            continue;
        }
        if (std.mem.indexOf(u8, line.items, "seeds:") == 0) {
            var seed_iter = std.mem.split(u8, line.items, " ");
            _ = seed_iter.next();
            while (seed_iter.next()) |seed| {
                try seeds.append(try std.fmt.parseInt(u64, seed, 10));
            }
        } else if (line.items[0] >= 'a' and line.items[0] <= 'z') {
            try map_map.append(std.ArrayList(Range).init(allocator));
        } else {
            var last_map = &map_map.items[map_map.items.len - 1];
            try last_map.append(try Range.new(line.items));
        }
    }

    var lowest_location: ?u64 = null;
    for (seeds.items) |seed| {
        var current_num: u64 = seed;
        for (0..7) |i| {
            var transform = &map_map.items[i];
            for (transform.items) |range| {
                if (range.transform(&current_num)) {
                    break;
                }
            }
        }
        if (lowest_location == null or current_num < lowest_location.?) {
            lowest_location = current_num;
        }
    }

    std.debug.print("Part 1: {d}\n", .{lowest_location.?});

    var idx: usize = 0;
    lowest_location = null;
    while (idx < seeds.items.len) {
        var seed: usize = @intCast(seeds.items[idx]);
        var seed_range_end: usize = @intCast(seeds.items[idx + 1]);

        while (seed < seed_range_end) {
            var current_num: u64 = seed;
            var loc = std.ArrayList(u64).init(allocator);
            defer loc.deinit();
            for (0..7) |i| {
                try loc.append(current_num);
                var transform = &map_map.items[i];
                for (transform.items) |range| {
                    if (range.transform(current_num)) {
                        if (range.)
                        break;
                    }
                }
            }
            if (lowest_location == null or current_num < lowest_location.?) {
                lowest_location = current_num;
            }
        }
        idx += 2;
    }

    // 0−9776277
    std.debug.print("Part 2: {d}\n", .{lowest_location.?});
}
