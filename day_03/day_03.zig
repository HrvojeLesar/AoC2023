const std = @import("std");

const GearPosition = struct {
    row: usize,
    column: usize,

    pub fn init(row: usize, column: usize) GearPosition {
        return GearPosition{ .row = row, .column = column };
    }
};

const Gear = struct {
    part_numbers: std.ArrayList(u64),

    pub fn init() Gear {
        const allocator = std.heap.page_allocator;
        return Gear{ .part_numbers = std.ArrayList(u64).init(allocator) };
    }

    pub fn deinit(self: *Gear) void {
        self.part_numbers.deinit();
    }

    pub fn append(self: *Gear, part_number: u64) anyerror!void {
        try self.part_numbers.append(part_number);
    }
};

const EngineSchematic = struct {
    rows: std.ArrayList(std.ArrayList(u8)),
    max_column_length: usize,

    pub fn init() EngineSchematic {
        const allocator = std.heap.page_allocator;
        return EngineSchematic{ .rows = std.ArrayList(std.ArrayList(u8)).init(allocator), .max_column_length = 0 };
    }

    pub fn deinit(self: *EngineSchematic) void {
        for (self.rows.items) |schematic_row| {
            schematic_row.deinit();
        }
    }

    pub fn appendSchematicRow(self: *EngineSchematic, row: std.ArrayList(u8)) anyerror!void {
        var number_of_columns = row.items.len;
        if (self.max_column_length < number_of_columns) {
            self.max_column_length = number_of_columns;
        }
        try self.rows.append(row);
    }

    pub fn partNumbers(self: *EngineSchematic) anyerror!std.ArrayList(u64) {
        const allocator = std.heap.page_allocator;
        var part_numbers = std.ArrayList(u64).init(allocator);

        for (0..self.rows.items.len) |row_idx| {
            var part_number: u64 = 0;
            var has_adjacent_symbol = false;
            for (0..self.rows.items[row_idx].items.len) |column_idx| {
                var current_char = self.rows.items[row_idx].items[column_idx];
                if (current_char >= '0' and current_char <= '9') {
                    part_number = (part_number + current_char - '0') * 10;
                    if (!has_adjacent_symbol) {
                        has_adjacent_symbol = self.hasAdjacentSymbol(row_idx, column_idx);
                    }
                } else {
                    if (has_adjacent_symbol) {
                        try part_numbers.append(part_number / 10);
                    }
                    part_number = 0;
                    has_adjacent_symbol = false;
                    continue;
                }
            }
            if (has_adjacent_symbol) {
                try part_numbers.append(part_number / 10);
            }
        }

        return part_numbers;
    }

    pub fn gears(self: *EngineSchematic) anyerror!std.AutoHashMap(GearPosition, Gear) {
        const allocator = std.heap.page_allocator;
        var part_numbers = std.ArrayList(u64).init(allocator);
        var gear_positions = std.AutoHashMap(GearPosition, Gear).init(allocator);

        for (0..self.rows.items.len) |row_idx| {
            var part_number: u64 = 0;
            var has_adjacent_symbol = false;
            var last_gear_position: ?GearPosition = null;
            for (0..self.rows.items[row_idx].items.len) |column_idx| {
                var current_char = self.rows.items[row_idx].items[column_idx];
                if (current_char >= '0' and current_char <= '9') {
                    part_number = (part_number + current_char - '0') * 10;
                    if (!has_adjacent_symbol) {
                        has_adjacent_symbol = self.hasAdjacentSymbol(row_idx, column_idx);
                    }
                    if (last_gear_position == null) {
                        last_gear_position = self.gearPosition(row_idx, column_idx);
                    }
                    if (last_gear_position != null) {
                        if (gear_positions.get(last_gear_position.?) == null) {
                            try gear_positions.put(last_gear_position.?, Gear.init());
                        }
                    }
                } else {
                    if (has_adjacent_symbol) {
                        try part_numbers.append(part_number / 10);
                        if (last_gear_position != null) {
                            var gear: ?*Gear = gear_positions.getPtr(last_gear_position.?);
                            try gear.?.*.append(part_number / 10);
                        }
                    }
                    part_number = 0;
                    has_adjacent_symbol = false;
                    last_gear_position = null;
                    continue;
                }
            }
            if (has_adjacent_symbol) {
                try part_numbers.append(part_number / 10);
                if (last_gear_position != null) {
                    var gear: ?*Gear = gear_positions.getPtr(last_gear_position.?);
                    try gear.?.*.append(part_number / 10);
                }
            }
        }

        return gear_positions;
    }

    fn hasAdjacentSymbol(self: *EngineSchematic, initial_row_idx: usize, initial_column_idx: usize) bool {
        var max_row_idx = self.rows.items.len - 1;
        var max_column_idx = self.max_column_length - 1;

        // above
        if (initial_row_idx > 0) {
            for (0..3) |modifier| {
                if ((initial_column_idx == 0 and modifier == 0) or (initial_column_idx == max_column_idx and modifier == 2)) {
                    continue;
                }
                const loc: i64 = @intCast(modifier);
                const col_idx: i64 = @intCast(initial_column_idx);
                const index: usize = @intCast(col_idx - 1 + loc);
                var symbol = self.rows.items[initial_row_idx - 1].items[index];
                if (symbol != '.' and (symbol < '0' or symbol > '9')) {
                    return true;
                }
            }
        }

        // left
        if (initial_column_idx > 0) {
            var symbol = self.rows.items[initial_row_idx].items[initial_column_idx - 1];
            if (symbol != '.' and (symbol < '0' or symbol > '9')) {
                return true;
            }
        }

        // right
        if (initial_column_idx < max_column_idx) {
            var symbol = self.rows.items[initial_row_idx].items[initial_column_idx + 1];
            if (symbol != '.' and (symbol < '0' or symbol > '9')) {
                return true;
            }
        }

        // below
        if (initial_row_idx < max_row_idx) {
            for (0..3) |modifier| {
                if ((initial_column_idx == 0 and modifier == 0) or (initial_column_idx == max_column_idx and modifier == 2)) {
                    continue;
                }
                const loc: i64 = @intCast(modifier);
                const col_idx: i64 = @intCast(initial_column_idx);
                const index: usize = @intCast(col_idx - 1 + loc);
                var symbol = self.rows.items[initial_row_idx + 1].items[index];
                if (symbol != '.' and (symbol < '0' or symbol > '9')) {
                    return true;
                }
            }
        }

        return false;
    }

    fn gearPosition(self: *EngineSchematic, initial_row_idx: usize, initial_column_idx: usize) ?GearPosition {
        var max_row_idx = self.rows.items.len - 1;
        var max_column_idx = self.max_column_length - 1;

        // above
        if (initial_row_idx > 0) {
            for (0..3) |modifier| {
                if ((initial_column_idx == 0 and modifier == 0) or (initial_column_idx == max_column_idx and modifier == 2)) {
                    continue;
                }
                const loc: i64 = @intCast(modifier);
                const col_idx: i64 = @intCast(initial_column_idx);
                const index: usize = @intCast(col_idx - 1 + loc);
                var symbol = self.rows.items[initial_row_idx - 1].items[index];
                if (symbol == '*') {
                    return GearPosition.init(initial_row_idx - 1, index);
                }
            }
        }

        // left
        if (initial_column_idx > 0) {
            var symbol = self.rows.items[initial_row_idx].items[initial_column_idx - 1];
            if (symbol == '*') {
                return GearPosition.init(initial_row_idx, initial_column_idx - 1);
            }
        }

        // right
        if (initial_column_idx < max_column_idx) {
            var symbol = self.rows.items[initial_row_idx].items[initial_column_idx + 1];
            if (symbol == '*') {
                return GearPosition.init(initial_row_idx, initial_column_idx + 1);
            }
        }

        // below
        if (initial_row_idx < max_row_idx) {
            for (0..3) |modifier| {
                if ((initial_column_idx == 0 and modifier == 0) or (initial_column_idx == max_column_idx and modifier == 2)) {
                    continue;
                }
                const loc: i64 = @intCast(modifier);
                const col_idx: i64 = @intCast(initial_column_idx);
                const index: usize = @intCast(col_idx - 1 + loc);
                var symbol = self.rows.items[initial_row_idx + 1].items[index];
                if (symbol == '*') {
                    return GearPosition.init(initial_row_idx + 1, index);
                }
            }
        }

        return null;
    }
};

pub fn main() !void {
    var engine_schematic = try parseInput();
    var part_numbers = try engine_schematic.partNumbers();
    var part_1: u64 = 0;
    for (part_numbers.items) |part_number| {
        part_1 += part_number;
    }
    std.debug.print("Part 1: {d}\n", .{part_1});

    var part_2: u64 = 0;
    var gear_positions = try engine_schematic.gears();
    var keys_iter = gear_positions.keyIterator();
    while (keys_iter.next()) |key| {
        var parts: std.ArrayList(u64) = gear_positions.get(key.*).?.part_numbers;
        if (parts.items.len == 2) {
            part_2 += parts.items[0] * parts.items[1];
        }
    }
    std.debug.print("Part 2: {d}\n", .{part_2});
}

fn parseInput() anyerror!EngineSchematic {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var engine_schematic = EngineSchematic.init();

    while (true) {
        var line = std.ArrayList(u8).init(allocator);
        in_stream.streamUntilDelimiter(line.writer(), '\n', null) catch break;
        try engine_schematic.appendSchematicRow(line);
    }

    return engine_schematic;
}
