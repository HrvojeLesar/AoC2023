const std = @import("std");

pub fn main() !void {
    try part1();
    try part2();
}

const numbers_written = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

const DigitIndex = struct { index: u64, digit: u64 };

fn part1() anyerror!void {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    var sum: u64 = 0;

    while (true) {
        in_stream.streamUntilDelimiter(line.writer(), '\n', null) catch break;
        defer line.clearAndFree();

        var slice: []u8 = try line.toOwnedSlice();
        var digits: ?DigitIndex = null;
        for (0..slice.len, slice) |i, element| {
            if (element >= '0' and element <= '9') {
                digits = DigitIndex{ .index = i, .digit = element - '0' };
                break;
            }
        }
        var backwards_idx = slice.len - 1;
        while (backwards_idx >= 0) {
            if (slice[backwards_idx] >= '0' and slice[backwards_idx] <= '9') {
                digits.?.digit = digits.?.digit * 10 + slice[backwards_idx] - '0';
                break;
            }
            backwards_idx -= 1;
        }
        sum += digits.?.digit;
    }
    std.debug.print("Part 1: {d}\n", .{sum});
}

fn part2() anyerror!void {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    var sum: u64 = 0;

    while (true) {
        in_stream.streamUntilDelimiter(line.writer(), '\n', null) catch break;
        defer line.clearAndFree();

        var slice: []u8 = try line.toOwnedSlice();

        var first_written = indexOfFirstStringDigit(slice);
        var last_written = indexOfLastStringDigit(slice);

        var first_digit: ?DigitIndex = null;
        var last_digit: ?DigitIndex = null;
        for (0..slice.len, slice) |i, element| {
            if (element >= '0' and element <= '9') {
                first_digit = DigitIndex{ .index = i, .digit = element - '0' };
                if (first_written != null and first_written.?.index < first_digit.?.index) {
                    first_digit = first_written;
                }
                break;
            }
        }
        var backwards_index = slice.len - 1;
        while (backwards_index >= 0) {
            if (slice[backwards_index] >= '0' and slice[backwards_index] <= '9') {
                last_digit = DigitIndex{ .index = backwards_index, .digit = slice[backwards_index] - '0' };
                if (last_written != null and last_written.?.index > last_digit.?.index) {
                    last_digit = last_written;
                }
                break;
            }
            if (backwards_index == 0) {
                break;
            }
            backwards_index -= 1;
        }
        if (first_digit == null) {
            first_digit = first_written;
        }
        if (last_digit == null) {
            last_digit = last_written;
        }
        sum += first_digit.?.digit * 10 + last_digit.?.digit;
    }
    std.debug.print("Part 2: {d}\n", .{sum});
}

fn indexOfFirstStringDigit(slice: []u8) ?DigitIndex {
    for (0..slice.len - 1) |i| {
        for (0..numbers_written.len, numbers_written) |digit, number| {
            if (number.len + i > slice.len) {
                continue;
            }
            var is_digit = true;
            for (0..number.len, number) |j, br_char| {
                if (br_char != slice[i + j]) {
                    is_digit = false;
                    break;
                }
            }
            if (is_digit) {
                return DigitIndex{ .index = i, .digit = digit + 1 };
            }
        }
    }

    return null;
}

fn indexOfLastStringDigit(slice: []u8) ?DigitIndex {
    var backwards_idx = slice.len - 1;
    while (backwards_idx >= 0) {
        for (0..numbers_written.len, numbers_written) |digit, number| {
            if (backwards_idx < number.len) {
                continue;
            }
            var is_digit = true;
            for (0..number.len, number) |j, br_char| {
                if (backwards_idx < number.len - 1 + j) {
                    continue;
                }
                if (br_char != slice[backwards_idx - (number.len - 1 - j)]) {
                    is_digit = false;
                    break;
                }
            }
            if (is_digit) {
                return DigitIndex{ .index = backwards_idx - (number.len - 1), .digit = digit + 1 };
            }
        }

        if (backwards_idx == 0) {
            break;
        }
        backwards_idx -= 1;
    }
    return null;
}
