const std = @import("std");

const Colour = enum {
    blue,
    red,
    green,

    pub fn fromString(str: []const u8) Colour {
        if (std.mem.eql(u8, str, "blue")) {
            return Colour.blue;
        }
        if (std.mem.eql(u8, str, "red")) {
            return Colour.red;
        }
        return Colour.green;
    }
};

const Set = struct {
    blue: i64,
    red: i64,
    green: i64,

    pub fn init() Set {
        return Set{
            .blue = 0,
            .red = 0,
            .green = 0,
        };
    }

    pub fn setColourValue(self: *Set, colour: Colour, value: i64) void {
        switch (colour) {
            Colour.blue => {
                if (self.blue < value) {
                    self.blue = value;
                }
            },
            Colour.red => {
                if (self.red < value) {
                    self.red = value;
                }
            },
            Colour.green => {
                if (self.green < value) {
                    self.green = value;
                }
            },
        }
    }
};

const Game = struct {
    id: i64,
    sets: std.ArrayList(Set),
    max_dice_values: Set,

    pub fn init(id: i64) Game {
        const allocator = std.heap.page_allocator;
        var game = Game{ .id = id, .sets = std.ArrayList(Set).init(allocator), .max_dice_values = Set.init() };
        return game;
    }

    pub fn addSet(self: *Game, set: Set) !void {
        try self.sets.append(set);
        if (self.max_dice_values.red < set.red) {
            self.max_dice_values.red = set.red;
        }
        if (self.max_dice_values.blue < set.blue) {
            self.max_dice_values.blue = set.blue;
        }
        if (self.max_dice_values.green < set.green) {
            self.max_dice_values.green = set.green;
        }
    }
};

pub fn main() !void {
    var games = try parse_games();
    var p1_count: i64 = 0;
    var p2_count: i64 = 0;
    for (games.items) |game| {
        if (game.max_dice_values.red <= 12 and game.max_dice_values.green <= 13 and game.max_dice_values.blue <= 14) {
            p1_count += game.id;
        }
        p2_count += game.max_dice_values.red * game.max_dice_values.green * game.max_dice_values.blue;
    }
    std.debug.print("P1: {d}\n", .{p1_count});
    std.debug.print("P2: {d}\n", .{p2_count});
}

fn parse_games() anyerror!std.ArrayList(Game) {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    var game_id: i64 = 1;
    var games = std.ArrayList(Game).init(allocator);

    while (true) {
        in_stream.streamUntilDelimiter(line.writer(), '\n', null) catch break;
        defer line.clearAndFree();
        var game = Game.init(game_id);
        var iter = std.mem.splitScalar(u8, line.items, ':');
        _ = iter.next();
        var sets_unparsed = iter.next();
        var sets_split = std.mem.splitScalar(u8, sets_unparsed.?, ';');
        while (sets_split.next()) |set| {
            var trimmed_set = std.mem.trim(u8, set, " ");
            var set_items = std.mem.splitScalar(u8, trimmed_set, ',');
            var built_set = Set.init();
            while (set_items.next()) |set_item| {
                var set_item_trimmed = std.mem.trim(u8, set_item, " ");
                var separator_index = std.mem.indexOf(u8, set_item_trimmed, " ");
                var value = try std.fmt.parseInt(i64, set_item_trimmed[0..separator_index.?], 10);
                var colour = set_item_trimmed[separator_index.? + 1 ..];
                var c = Colour.fromString(colour);
                built_set.setColourValue(c, value);
            }
            try game.addSet(built_set);
        }
        try games.append(game);
        game_id += 1;
    }
    return games;
}
