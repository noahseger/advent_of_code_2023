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
//
// In this schematic, two numbers are not part numbers because they are not adjacent to a symbol: 114 (top right) and 58 (middle right). Every other number is adjacent to a symbol and so is a part number; their sum is 4361.
//
// Of course, the actual engine schematic is much larger. What is the sum of all of the part numbers in the engine schematic?
//
// --- Part Two ---
//
// The engineer finds the missing part and installs it in the engine! As the engine springs to life, you jump in the closest gondola, finally ready to ascend to the water source.
//
// You don't seem to be going very fast, though. Maybe something is still wrong? Fortunately, the gondola has a phone labeled "help", so you pick it up and the engineer answers.
//
// Before you can explain the situation, she suggests that you look out the window. There stands the engineer, holding a phone in one hand and waving with the other. You're going so slowly that you haven't even left the station. You exit the gondola.
//
// The missing part wasn't the only issue - one of the gears in the engine is wrong. A gear is any * symbol that is adjacent to exactly two part numbers. Its gear ratio is the result of multiplying those two numbers together.
//
// This time, you need to find the gear ratio of every gear and add them all up so that the engineer can figure out which gear needs to be replaced.
//
// Consider the same engine schematic again:
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
//
// In this schematic, there are two gears. The first is in the top left; it has part numbers 467 and 35, so its gear ratio is 16345. The second gear is in the lower right; its gear ratio is 451490. (The * adjacent to 617 is not a gear because it is only adjacent to one part number.) Adding up all of the gear ratios produces 467835.
//
// What is the sum of all of the gear ratios in your engine schematic?
const std = @import("std");

const Options = struct { allocator: std.mem.Allocator = std.heap.page_allocator };

const Solution = struct { sum_of_part_numbers: u32, sum_of_gear_ratios: u64 };

const Symbol = struct {
    const Self = @This();

    value: u8,
    line_number: usize,
    i: usize,
    gear_count: u32 = 0,
    gear_ratio: u64 = 1,

    fn addGear(self: *Self, gear: u32) void {
        // std.debug.print("{}, gear={}\n", .{ self, gear });
        self.gear_count += 1;
        self.gear_ratio *= gear;
    }
};

const PartNumber = struct { value: u32, line_number: usize, i_0: usize, i_n: usize };

pub fn main() !void {
    const input = @embedFile("03_input.txt");
    const solution = try solve(input, .{});
    std.debug.print("{}\n", .{solution});
}

pub fn solve(input: []const u8, options: Options) !Solution {
    var sum_of_part_numbers: u32 = 0;
    var sum_of_gear_ratios: u64 = 0;

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
                    var symbol = Symbol{ .value = c, .line_number = line_number, .i = i };
                    try symbols.append(symbol);
                }
            }
        }
    }

    // Add these bad boys
    for (part_numbers.items) |possible_part_number| {
        const l = possible_part_number.line_number;
        const i_0 = possible_part_number.i_0;
        const i_n = possible_part_number.i_n;
        // std.debug.print("{}\n", .{possible_part_number});

        var symbol_index: usize = 0;
        while (symbol_index < symbols.items.len) : (symbol_index += 1) {
            var symbol = &symbols.items[symbol_index];

            const i = symbol.i;
            // std.debug.print("{}\n", .{symbol});
            if (symbol.line_number == l) { // Symbol on same line
                if (i_n == i - 1 or i_0 == i + 1) {
                    sum_of_part_numbers += possible_part_number.value;
                    if (symbol.value == '*') symbol.addGear(possible_part_number.value);
                }
            } else if (l > 0 and symbol.line_number == l - 1) { // Symbol on previous line
                if (i_n == i - 1 or i_n == i or i_0 == i or i_0 == i + 1 or (i_0 <= i and i_n >= i)) {
                    sum_of_part_numbers += possible_part_number.value;
                    if (symbol.value == '*') symbol.addGear(possible_part_number.value);
                }
            } else if (symbol.line_number == l + 1) { // Symbol on next line
                if (i_n == i - 1 or i_n == i or i_0 == i or i_0 == i + 1 or (i_0 <= i and i_n >= i)) {
                    sum_of_part_numbers += possible_part_number.value;
                    if (symbol.value == '*') symbol.addGear(possible_part_number.value);
                }
            }
        }
    }

    // Gear up
    // std.debug.print("Adding gear ratios...\n", .{});
    for (symbols.items) |symbol| {
        // std.debug.print("{}\n", .{symbol});
        if (symbol.gear_count > 1) {
            sum_of_gear_ratios += symbol.gear_ratio;
        }
    }

    return .{ .sum_of_part_numbers = sum_of_part_numbers, .sum_of_gear_ratios = sum_of_gear_ratios };
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
    try std.testing.expectEqual(@as(u64, 467835), solution.sum_of_gear_ratios);
}
