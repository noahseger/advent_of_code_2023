// --- Day 11: Cosmic Expansion ---
//
// You continue following signs for "Hot Springs" and eventually come across an observatory. The Elf within turns out to be a researcher studying cosmic expansion using the giant telescope here.
//
// He doesn't know anything about the missing machine parts; he's only visiting for this research project. However, he confirms that the hot springs are the next-closest area likely to have people; he'll even take you straight there once he's done with today's observation analysis.
//
// Maybe you can help him with the analysis to speed things up?
//
// The researcher has collected a bunch of data and compiled the data into a single giant image (your puzzle input). The image includes empty space (.) and galaxies (#). For example:
//
// ...#......
// .......#..
// #.........
// ..........
// ......#...
// .#........
// .........#
// ..........
// .......#..
// #...#.....
//
// The researcher is trying to figure out the sum of the lengths of the shortest path between every pair of galaxies. However, there's a catch: the universe expanded in the time it took the light from those galaxies to reach the observatory.
//
// Due to something involving gravitational effects, only some space expands. In fact, the result is that any rows or columns that contain no galaxies should all actually be twice as big.
//
// In the above example, three columns and two rows contain no galaxies:
//
//    v  v  v
//  ...#......
//  .......#..
//  #.........
// >..........<
//  ......#...
//  .#........
//  .........#
// >..........<
//  .......#..
//  #...#.....
//    ^  ^  ^
//
// These rows and columns need to be twice as big; the result of cosmic expansion therefore looks like this:
//
// ....#........
// .........#...
// #............
// .............
// .............
// ........#....
// .#...........
// ............#
// .............
// .............
// .........#...
// #....#.......
//
// Equipped with this expanded universe, the shortest path between every pair of galaxies can be found. It can help to assign every galaxy a unique number:
//
// ....1........
// .........2...
// 3............
// .............
// .............
// ........4....
// .5...........
// ............6
// .............
// .............
// .........7...
// 8....9.......
//
// In these 9 galaxies, there are 36 pairs. Only count each pair once; order within the pair doesn't matter. For each pair, find any shortest path between the two galaxies using only steps that move up, down, left, or right exactly one . or # at a time. (The shortest path between two galaxies is allowed to pass through another galaxy.)
//
// For example, here is one of the shortest paths between galaxies 5 and 9:
//
// ....1........
// .........2...
// 3............
// .............
// .............
// ........4....
// .5...........
// .##.........6
// ..##.........
// ...##........
// ....##...7...
// 8....9.......
//
// This path has length 9 because it takes a minimum of nine steps to get from galaxy 5 to galaxy 9 (the eight locations marked # plus the step onto galaxy 9 itself). Here are some other example shortest path lengths:
//
//     Between galaxy 1 and galaxy 7: 15
//     Between galaxy 3 and galaxy 6: 17
//     Between galaxy 8 and galaxy 9: 5
//
// In this example, after expanding the universe, the sum of the shortest path between all 36 pairs of galaxies is 374.
//
// Expand the universe, then find the length of the shortest path between every pair of galaxies. What is the sum of these lengths?
const std = @import("std");

const Galaxy = struct {
    y: i32,
    x: i32,

    fn distance(this: Galaxy, other: Galaxy) !i32 {
        const x = try std.math.absInt(this.x - other.x);
        const y = try std.math.absInt(this.y - other.y);
        return x + y;
    }
};

test "example test" {
    const input =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(i32, 374), solution.part_one);
}

pub fn main() !void {
    const input = @embedFile("11_input.txt");
    const solution = try solve(input, .{});
    std.debug.print("{}\n", .{solution});
}

fn solve(input: []const u8, options: Options) !Solution {
    var space = std.ArrayList([]const u8).init(options.allocator);
    var galaxies = std.ArrayList(Galaxy).init(options.allocator);

    var x: usize = 0;
    var y: usize = 0;
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| : (y += 1) {
        if (line.len == 0) break;
        try space.append(line);

        x = 0;
        while (x < line.len) : (x += 1) {
            if (line[x] == '#') {
                try galaxies.append(Galaxy{ .y = @intCast(y), .x = @intCast(x) });
            }
        }
    }

    // std.debug.print("{} galaxies...\n", .{galaxies.items.len});

    // Expand rows
    var y2: usize = 0;
    var expansion: usize = 0;
    while (y2 < y) : (y2 += 1) {
        var is_empty = true;
        for (space.items[y2]) |it| {
            if (it == '#') {
                is_empty = false;
                break;
            }
        }
        if (!is_empty) continue;

        for (galaxies.items) |*galaxy| {
            if (galaxy.y > y2 + expansion) {
                // std.debug.print("expanding galaxy y > {}: {} ", .{ y2, galaxy });
                galaxy.y += 1;
                // std.debug.print("to {}\n", .{galaxy});
            }
        }

        expansion += 1;
    }

    // Expand columns
    var x2: usize = 0;
    expansion = 0;
    while (x2 < x) : (x2 += 1) {
        var is_empty = true;
        for (space.items) |it| {
            if (it[x2] == '#') {
                is_empty = false;
                break;
            }
        }
        if (!is_empty) continue;

        for (galaxies.items) |*galaxy| {
            if (galaxy.x > x2 + expansion) {
                // std.debug.print("expanding galaxy x > {}: {} ", .{ x2, galaxy });
                galaxy.x += 1;
                // std.debug.print("to {}\n", .{galaxy});
            } else {
                // std.debug.print("...ignoring expansion x > {}: {}\n", .{ x2, galaxy });
            }
        }

        expansion += 1;
    }

    // Find all galaxy distances
    var part_one: i32 = 0;
    var pairs: i32 = 0;
    for (galaxies.items, 0..) |galaxy, i| {
        // std.debug.print("adjusted_galaxy={}\n", .{galaxy});
        var j: usize = 0;
        while (j < i) : (j += 1) {
            part_one += try galaxy.distance(galaxies.items[j]);
            pairs += 1;
            // std.debug.print("from={}, to={}, n={}\n", .{ galaxy, galaxies.items[j], pairs });
        }
    }

    return .{ .part_one = part_one, .part_two = 0 };
}

const Solution = struct { part_one: i32, part_two: i32 };

const Options = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
