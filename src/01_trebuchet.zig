// --- Day 1: Trebuchet?! ---
//
// Something is wrong with global snow production, and you've been selected to take a look. The Elves have even given you a map; on it, they've used stars to mark the top fifty locations that are likely to be having problems.
//
// You've been doing this long enough to know that to restore snow operations, you need to check all fifty stars by December 25th.
//
// Collect stars by solving puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants one star. Good luck!
//
// You try to ask why they can't just use a weather machine ("not powerful enough") and where they're even sending you ("the sky") and why your map looks mostly blank ("you sure ask a lot of questions") and hang on did you just say the sky ("of course, where do you think snow comes from") when you realize that the Elves are already loading you into a trebuchet ("please hold still, we need to strap you in").
//
// As they're making the final adjustments, they discover that their calibration document (your puzzle input) has been amended by a very young Elf who was apparently just excited to show off her art skills. Consequently, the Elves are having trouble reading the values on the document.
//
// The newly-improved calibration document consists of lines of text; each line originally contained a specific calibration value that the Elves now need to recover. On each line, the calibration value can be found by combining the first digit and the last digit (in that order) to form a single two-digit number.
//
// For example:
//
// 1abc2
// pqr3stu8vwx
// a1b2c3d4e5f
// treb7uchet
//
// In this example, the calibration values of these four lines are 12, 38, 15, and 77. Adding these together produces 142.
//
// Consider your entire calibration document. What is the sum of all of the calibration values?
const std = @import("std");

const input_filename = "src/01_input.txt";

const numbers = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

const Numerals = enum {
    digits,
    digits_and_numbers,
};

const Options = struct { numerals: Numerals = .digits };

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var stat = try std.fs.cwd().statFile(input_filename);
    var buffer = try allocator.alloc(u8, stat.size);
    defer allocator.free(buffer);

    var file = try std.fs.cwd().openFile(input_filename, .{});

    defer file.close();

    _ = try file.readAll(buffer);
    const digits_total = sumCalibrationValues(buffer, .{});
    const bugfix_total = sumCalibrationValues(buffer, .{ .numerals = .digits_and_numbers });

    var writer = std.io.getStdOut().writer();
    try writer.print("digits: {}\n", .{digits_total});
    try writer.print("bugfix: {}\n", .{bugfix_total});
}

fn sumCalibrationValues(document: []const u8, options: Options) u32 {
    var i: u32 = 0;
    var total: u32 = 0;
    var lines = std.mem.split(u8, document, "\n");
    while (lines.next()) |line| : (i += 1) {
        if (line.len == 0) continue;
        std.debug.print("{}: {s}\n", .{ i, line });
        total += getLineValue(line, options.numerals);
    }

    return total;
}

fn getLineValue(line: []const u8, numerals: Numerals) u32 {
    var first_digit: ?u32 = null;
    var last_digit: ?u32 = null;

    for (line, 0..) |c, i| {
        // Check ASCII ranges for 0—9.
        if (c >= 48 and c <= 57) {
            const value = c - 48;
            if (first_digit == null) first_digit = value;
            last_digit = value;
            continue;
        }

        // Skip numbers without bugfix option.
        if (numerals != .digits_and_numbers) continue;

        // Check any named number starting at this index.
        var ordinal: u32 = 0;
        for (numbers) |number| {
            ordinal += 1;
            if (i + number.len > line.len) continue;
            if (std.mem.eql(u8, line[i .. i + number.len], number)) {
                // std.debug.print("line={s}, i={}, number={s}, ordinal={}\n", .{ line, i, number, ordinal });
                if (first_digit == null) first_digit = ordinal;
                last_digit = ordinal;
            }
        }
    }

    std.debug.assert(first_digit != null);
    std.debug.assert(last_digit != null);

    return (first_digit.? * 10) + last_digit.?;
}

test "example test" {
    const document =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    const total = sumCalibrationValues(document, .{});
    try std.testing.expectEqual(@as(u32, 142), total);
}

test "one digit" {
    const document =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
        \\asdfasdf1bbb
    ;
    const total = sumCalibrationValues(document, .{});
    try std.testing.expectEqual(@as(u32, 153), total);
}
