// --- Day 14: Parabolic Reflector Dish ---

// You reach the place where all of the mirrors were pointing: a massive parabolic reflector dish attached to the side of another large mountain.

// The dish is made up of many small mirrors, but while the mirrors themselves are roughly in the shape of a parabolic reflector dish, each individual mirror seems to be pointing in slightly the wrong direction. If the dish is meant to focus light, all it's doing right now is sending it in a vague direction.

// This system must be what provides the energy for the lava! If you focus the reflector dish, maybe you can go where it's pointing and use the light to fix the lava production.

// Upon closer inspection, the individual mirrors each appear to be connected via an elaborate system of ropes and pulleys to a large metal platform below the dish. The platform is covered in large rocks of various shapes. Depending on their position, the weight of the rocks deforms the platform, and the shape of the platform controls which ropes move and ultimately the focus of the dish.

// In short: if you move the rocks, you can focus the dish. The platform even has a control panel on the side that lets you tilt it in one of four directions! The rounded rocks (O) will roll when the platform is tilted, while the cube-shaped rocks (#) will stay in place. You note the positions of all of the empty spaces (.) and rocks (your puzzle input). For example:

// O....#....
// O.OO#....#
// .....##...
// OO.#O....O
// .O.....O#.
// O.#..O.#.#
// ..O..#O..O
// .......O..
// #....###..
// #OO..#....

// Start by tilting the lever so all of the rocks will slide north as far as they will go:

// OOOO.#.O..
// OO..#....#
// OO..O##..O
// O..#.OO...
// ........#.
// ..#....#.#
// ..O..#.O.O
// ..O.......
// #....###..
// #....#....

// You notice that the support beams along the north side of the platform are damaged; to ensure the platform doesn't collapse, you should calculate the total load on the north support beams.

// The amount of load caused by a single rounded rock (O) is equal to the number of rows from the rock to the south edge of the platform, including the row the rock is on. (Cube-shaped rocks (#) don't contribute to load.) So, the amount of load caused by each rock in each row is as follows:

// OOOO.#.O.. 10
// OO..#....#  9
// OO..O##..O  8
// O..#.OO...  7
// ........#.  6
// ..#....#.#  5
// ..O..#.O.O  4
// ..O.......  3
// #....###..  2
// #....#....  1

// The total load is the sum of the load caused by all of the rounded rocks. In this example, the total load is 136.

// Tilt the platform so that the rounded rocks all roll north. Afterward, what is the total load on the north support beams?
const std = @import("std");

const Location = struct {
    y: u64,
    x: u64,
    fn north(self: @This()) Location {
        return Location{ .x = self.x, .y = self.y - 1 };
    }
};

const Stone = struct { location: Location };

const Dish = struct {
    const Self = @This();

    stones: std.ArrayList(Stone),
    blocks: std.AutoHashMap(Location, void),
    width: u64,
    height: u64,

    fn tiltNorth(self: *Self) !void {
        for (self.stones.items) |*stone| {
            // const start_location = stone.location;
            while (stone.location.y > 0 and !self.blocks.contains(stone.location.north())) {
                stone.location = stone.location.north();
                // std.debug.print("moving stone={} north...\n", .{stone});
            }

            // std.debug.print("moved stone from={} to={}...\n", .{ start_location, stone.location });
            try self.blocks.put(stone.location, {});
        }
    }
};

test "example test" {
    const input =
        \\O....#....
        \\O.OO#....#
        \\.....##...
        \\OO.#O....O
        \\.O.....O#.
        \\O.#..O.#.#
        \\..O..#O..O
        \\.......O..
        \\#....###..
        \\#OO..#....
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u64, 136), solution.part_one);
}

pub fn main() !void {
    const input = @embedFile("14_input.txt");
    const solution = try solve(input, .{});
    std.debug.print("{}\n", .{solution});
}

fn solve(input: []const u8, options: Options) !Solution {
    var part_one: u64 = 0;
    const part_two: u64 = 0;

    var lines = std.mem.split(u8, input, "\n");
    var stones = std.ArrayList(Stone).init(options.allocator);
    var blocks = std.AutoHashMap(Location, void).init(options.allocator);

    var y: usize = 0;
    var width: usize = undefined;
    while (lines.next()) |line| : (y += 1) {
        if (line.len == 0) break;

        width = line.len;
        var x: usize = 0;
        while (x < line.len) : (x += 1) {
            const location = Location{ .y = y, .x = x };
            if (line[x] == '#') try blocks.put(location, {});
            if (line[x] == 'O') try stones.append(.{ .location = location });
        }
    }

    var dish = Dish{ .height = y, .width = width, .blocks = blocks, .stones = stones };
    try dish.tiltNorth();

    for (dish.stones.items) |stone| {
        // std.debug.print("O: location={}\n", .{stone.location});
        part_one += dish.height - stone.location.y;
    }

    return .{ .part_one = part_one, .part_two = part_two };
}

const Solution = struct { part_one: u64, part_two: u64 };

const Options = struct { allocator: std.mem.Allocator = std.heap.page_allocator };
