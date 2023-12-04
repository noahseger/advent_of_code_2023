// --- Day 3: Gear Ratios ---
//
// You and the Elf eventually reach a gondola lift station; he says the gondola lift will take you up to the water source, but this is as far as he can bring you. You go inside.
//
// It doesn't take long to find the gondolas, but there seems to be a problem: they're not moving.
//
// "Aaah!"
//
// You turn around to see a slightly-greasy Elf with a wrench and a look of surprise. "Sorry, I wasn't expecting anyone! The gondola lift isn't working right now; it'll still be a while before I can fix it." You offer to help.
//
// The engineer explains that an engine part seems to be missing from the engine, but nobody can figure out which one. If you can add up all the part numbers in the engine schematic, it should be easy to work out which part is missing.
//
// The engine schematic (your puzzle input) consists of a visual representation of the engine. There are lots of numbers and symbols you don't really understand, but apparently any number adjacent to a symbol, even diagonally, is a "part number" and should be included in your sum. (Periods (.) do not count as a symbol.)
//
// Here is an example engine schematic:
//
// 467..114..
// ...*......
// ..35..633.
// ......#...
// 617*......
// .....+.58.
// ..592.....
// ......755.
// ...$.*....
// .664.598..

// In this schematic, two numbers are not part numbers because they are not adjacent to a symbol: 114 (top right) and 58 (middle right). Every other number is adjacent to a symbol and so is a part number; their sum is 4361.
//
// Of course, the actual engine schematic is much larger. What is the sum of all of the part numbers in the engine schematic?
const std = @import("std");

const Options = struct { allocator: std.mem.Allocator = std.heap.page_allocator };

const Solution = struct { sum_of_part_numbers: u32 };

const Symbol = struct { line_number: usize, i: usize };

const PartNumber = struct { value: u32, line_number: usize, i_0: usize, i_n: usize };

pub fn main() !void {
    const input = @embedFile("03_input.txt");
    const solution = try solve(input, .{});
    std.debug.print("{}\n", .{solution});
}

pub fn solve(input: []const u8, options: Options) !Solution {
    var sum_of_part_numbers: u32 = 0;

    // Track locations of all symbols
    // TODO: Optimize by only keeping previous line.
    var symbols = std.ArrayList(Symbol).init(options.allocator);
    defer symbols.deinit();

    // Track locations of all part numbers
    // TODO: Optimize by only keeping previous line.
    var part_numbers = std.ArrayList(PartNumber).init(options.allocator);
    defer part_numbers.deinit();

    var lines = std.mem.split(u8, input, "\n");
    var line_number: u32 = 0;
    var part_number: ?PartNumber = null;
    while (lines.next()) |line| : (line_number += 1) {
        // If the last line ended with a part number, track it.
        if (part_number != null) {
            try part_numbers.append(part_number.?);
            part_number = null;
        }

        // Skip the last newline.
        if (line.len == 0) continue;

        std.debug.print("{s}\n", .{line});
        for (line, 0..) |c, i| {

            // Check ASCII ranges for 0—9.
            if (c >= 48 and c <= 57) {
                const value = c - 48;
                if (part_number == null) {
                    part_number = .{ .value = value, .line_number = line_number, .i_0 = i, .i_n = i };
                } else {
                    part_number.?.value = part_number.?.value * 10 + value;
                    part_number.?.i_n = i;
                }
            } else {
                // TODO: Deduplicate start-of-loop condition.
                if (part_number != null) {
                    try part_numbers.append(part_number.?);
                    part_number = null;
                }

                if (c != '.') {
                    try symbols.append(.{ .line_number = line_number, .i = i });
                }
            }
        }
    }

    // Add these bad boys
    for (part_numbers.items) |possible_part_number| {
        const l = possible_part_number.line_number;
        const i_0 = possible_part_number.i_0;
        const i_n = possible_part_number.i_n;
        for (symbols.items) |symbol| {
            const i = symbol.i;
            if (symbol.line_number == l) { // Symbol on same line
                if (i_n == i - 1 or i_0 == i + 1) {
                    sum_of_part_numbers += possible_part_number.value;
                }
            } else if (l > 0 and symbol.line_number == l - 1) { // Symbol on previous line
                if ((i_0 <= i and i_n >= i)) {
                    sum_of_part_numbers += possible_part_number.value;
                }
            } else if (symbol.line_number == l + 1) { // Symbol on next line
                if ((i_0 <= i and i_n >= i)) {
                    sum_of_part_numbers += possible_part_number.value;
                }
            }
        }
    }

    return .{ .sum_of_part_numbers = sum_of_part_numbers };
}

test "example test" {
    const input =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u32, 4361), solution.sum_of_part_numbers);
}
