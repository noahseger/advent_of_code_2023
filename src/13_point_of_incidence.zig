// -- Day 13: Point of Incidence ---

// With your help, the hot springs team locates an appropriate spring which launches you neatly and precisely up to the edge of Lava Island.

// There's just one problem: you don't see any lava.

// You do see a lot of ash and igneous rock; there are even what look like gray mountains scattered around. After a while, you make your way to a nearby cluster of mountains only to discover that the valley between them is completely full of large mirrors. Most of the mirrors seem to be aligned in a consistent way; perhaps you should head in that direction?

// As you move through the valley of mirrors, you find that several of them have fallen from the large metal frames keeping them in place. The mirrors are extremely flat and shiny, and many of the fallen mirrors have lodged into the ash at strange angles. Because the terrain is all one color, it's hard to tell where it's safe to walk or where you're about to run into a mirror.

// You note down the patterns of ash (.) and rocks (#) that you see as you walk (your puzzle input); perhaps by carefully analyzing these patterns, you can figure out where the mirrors are!

// For example:

// #.##..##.
// ..#.##.#.
// ##......#
// ##......#
// ..#.##.#.
// ..##..##.
// #.#.##.#.

// #...##..#
// #....#..#
// ..##..###
// #####.##.
// #####.##.
// ..##..###
// #....#..#

// To find the reflection in each pattern, you need to find a perfect reflection across either a horizontal line between two rows or across a vertical line between two columns.

// In the first pattern, the reflection is across a vertical line between two columns; arrows on each of the two columns point at the line between the columns:

// 123456789
//     ><
// #.##..##.
// ..#.##.#.
// ##......#
// ##......#
// ..#.##.#.
// ..##..##.
// #.#.##.#.
//     ><
// 123456789

// In this pattern, the line of reflection is the vertical line between columns 5 and 6. Because the vertical line is not perfectly in the middle of the pattern, part of the pattern (column 1) has nowhere to reflect onto and can be ignored; every other column has a reflected column within the pattern and must match exactly: column 2 matches column 9, column 3 matches 8, 4 matches 7, and 5 matches 6.

// The second pattern reflects across a horizontal line instead:

// 1 #...##..# 1
// 2 #....#..# 2
// 3 ..##..### 3
// 4v#####.##.v4
// 5^#####.##.^5
// 6 ..##..### 6
// 7 #....#..# 7

// This pattern reflects across the horizontal line between rows 4 and 5. Row 1 would reflect with a hypothetical row 8, but since that's not in the pattern, row 1 doesn't need to match anything. The remaining rows match: row 2 matches row 7, row 3 matches row 6, and row 4 matches row 5.

// To summarize your pattern notes, add up the number of columns to the left of each vertical line of reflection; to that, also add 100 multiplied by the number of rows above each horizontal line of reflection. In the above example, the first pattern's vertical line has 5 columns to its left and the second pattern's horizontal line has 4 rows above it, a total of 405.

// Find the line of reflection in each of the patterns in your notes. What number do you get after summarizing all of your notes?

// --- Part Two ---

// You resume walking through the valley of mirrors and - SMACK! - run directly into one. Hopefully nobody was watching, because that must have been pretty embarrassing.

// Upon closer inspection, you discover that every mirror has exactly one smudge: exactly one . or # should be the opposite type.

// In each pattern, you'll need to locate and fix the smudge that causes a different reflection line to be valid. (The old reflection line won't necessarily continue being valid after the smudge is fixed.)

// Here's the above example again:

// #.##..##.
// ..#.##.#.
// ##......#
// ##......#
// ..#.##.#.
// ..##..##.
// #.#.##.#.

// #...##..#
// #....#..#
// ..##..###
// #####.##.
// #####.##.
// ..##..###
// #....#..#

// The first pattern's smudge is in the top-left corner. If the top-left # were instead ., it would have a different, horizontal line of reflection:

// 1 ..##..##. 1
// 2 ..#.##.#. 2
// 3v##......#v3
// 4^##......#^4
// 5 ..#.##.#. 5
// 6 ..##..##. 6
// 7 #.#.##.#. 7

// With the smudge in the top-left corner repaired, a new horizontal line of reflection between rows 3 and 4 now exists. Row 7 has no corresponding reflected row and can be ignored, but every other row matches exactly: row 1 matches row 6, row 2 matches row 5, and row 3 matches row 4.

// In the second pattern, the smudge can be fixed by changing the fifth symbol on row 2 from . to #:

// 1v#...##..#v1
// 2^#...##..#^2
// 3 ..##..### 3
// 4 #####.##. 4
// 5 #####.##. 5
// 6 ..##..### 6
// 7 #....#..# 7

// Now, the pattern has a different horizontal line of reflection between rows 1 and 2.

// Summarize your notes as before, but instead use the new different reflection lines. In this example, the first pattern's new horizontal line has 3 rows above it and the second pattern's new horizontal line has 1 row above it, summarizing to the value 400.

// In each pattern, fix the smudge and find the different line of reflection. What number do you get after summarizing the new reflection line in each pattern in your notes?
const std = @import("std");

const Pattern = std.ArrayList([]const u8);

const Mirror = struct {
    pattern: Pattern,

    pub fn reflect(self: @This(), smudges: u8) !u64 {
        const pattern = self.pattern.items;
        const width = pattern[0].len;
        const height = pattern.len;
        const allocator = self.pattern.allocator;

        // Horizontal
        var total = locate(pattern, false, smudges) * 100;

        // Horizontal, reversed
        var reversed = Pattern.init(allocator);
        for (0..height) |i| try reversed.append(pattern[pattern.len - i - 1]);
        total += locate(reversed.items, true, smudges) * 100;

        // Vertical
        // std.debug.print("Vertical...\n", .{});
        var vertical = Pattern.init(allocator);
        for (0..width) |x| {
            var column = try allocator.alloc(u8, height);
            for (0..height) |y| column[y] = pattern[y][x];
            // std.debug.print("{s}\n", .{column});
            try vertical.append(column);
        }

        total += locate(vertical.items, false, smudges);

        // Vertical, reversed
        var vertical_reversed = Pattern.init(allocator);
        for (0..width) |i| try vertical_reversed.append(vertical.items[width - i - 1]);
        total += locate(vertical_reversed.items, true, smudges);

        return total;
    }

    fn locate(pattern: [][]const u8, reversed: bool, smudges: u8) u64 {
        var y: usize = 1;
        while (y * 2 < pattern.len) : (y += 1) {
            var differences: u8 = 0;
            for (0..y) |i| {
                // std.debug.print("y={}, i={}, pair={},{}\n", .{ y, i, i, y * 2 - i - 1 });
                differences += diff(pattern[i], pattern[y * 2 - i - 1]);
            }
            // std.debug.print("y={}, i={}, matches={}\n", .{ y, y, matches });
            if (differences == smudges) return if (reversed) (pattern.len - y) else (y);
        }

        return 0;
    }

    fn diff(a: []const u8, b: []const u8) u8 {
        var result: u8 = 0;
        for (a, b) |v1, v2| {
            if (v1 != v2) result += 1;
        }

        return result;
    }
};

test "example test" {
    const input =
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
        \\
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u64, 405), solution.part_one);
}

test "input test" {
    const input =
        \\#..#.....
        \\.##.##..#
        \\####..###
        \\#..###.##
        \\#..#.###.
        \\####.....
        \\....#..#.
        \\#####....
        \\#####....
        \\....#..#.
        \\####....#
        \\#..#.###.
        \\#..###.##
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u64, 2), solution.part_one);
}

pub fn main() !void {
    const input = @embedFile("13_input.txt");
    const solution = try solve(input, .{});
    std.debug.print("{}\n", .{solution});
}

fn solve(input: []const u8, options: Options) !Solution {
    var part_one: u64 = 0;
    var part_two: u64 = 0;

    // Part one
    var patterns = std.mem.split(u8, input, "\n\n");
    var i: i32 = 0;
    while (patterns.next()) |raw_pattern| : (i += 1) {
        var lines = std.mem.split(u8, raw_pattern, "\n");
        var pattern = Pattern.init(options.allocator);
        while (lines.next()) |line| {
            if (line.len == 0) break;
            try pattern.append(line);
        }

        var mirror = Mirror{ .pattern = pattern };
        part_one += try mirror.reflect(0);
        part_two += try mirror.reflect(1);
        // try std.io.getStdOut().writer().print("i={}, part_one={}, part_two={}\n", .{ i, part_one, part_two });
    }

    return .{ .part_one = part_one, .part_two = part_two };
}

const Solution = struct { part_one: u64, part_two: u64 };

const Options = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
