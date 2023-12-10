// --- Day 10: Pipe Maze ---
//
// You use the hang glider to ride the hot air from Desert Island all the way up to the floating metal island. This island is surprisingly cold and there definitely aren't any thermals to glide on, so you leave your hang glider behind.
//
// You wander around for a while, but you don't find any people or animals. However, you do occasionally find signposts labeled "Hot Springs" pointing in a seemingly consistent direction; maybe you can find someone at the hot springs and ask them where the desert-machine parts are made.
//
// The landscape here is alien; even the flowers and trees are made of metal. As you stop to admire some metal grass, you notice something metallic scurry away in your peripheral vision and jump into a big pipe! It didn't look like any animal you've ever seen; if you want a better look, you'll need to get ahead of it.
//
// Scanning the area, you discover that the entire field you're standing on is densely packed with pipes; it was hard to tell at first because they're the same metallic silver color as the "ground". You make a quick sketch of all of the surface pipes you can see (your puzzle input).
//
// The pipes are arranged in a two-dimensional grid of tiles:
//
//     | is a vertical pipe connecting north and south.
//     - is a horizontal pipe connecting east and west.
//     L is a 90-degree bend connecting north and east.
//     J is a 90-degree bend connecting north and west.
//     7 is a 90-degree bend connecting south and west.
//     F is a 90-degree bend connecting south and east.
//     . is ground; there is no pipe in this tile.
//     S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.
//
// Based on the acoustics of the animal's scurrying, you're confident the pipe that contains the animal is one large, continuous loop.
//
// For example, here is a square loop of pipe:
//
// .....
// .F-7.
// .|.|.
// .L-J.
// .....
//
// If the animal had entered this loop in the northwest corner, the sketch would instead look like this:
//
// .....
// .S-7.
// .|.|.
// .L-J.
// .....
//
// In the above diagram, the S tile is still a 90-degree F bend: you can tell because of how the adjacent pipes connect to it.
//
// Unfortunately, there are also many pipes that aren't connected to the loop! This sketch shows the same loop as above:
//
// -L|F7
// 7S-7|
// L|7||
// -L-J|
// L|-JF
//
// In the above diagram, you can still figure out which pipes form the main loop: they're the ones connected to S, pipes those pipes connect to, pipes those pipes connect to, and so on. Every pipe in the main loop connects to its two neighbors (including S, which will have exactly two pipes connecting to it, and which is assumed to connect back to those two pipes).
//
// Here is a sketch that contains a slightly more complex main loop:
//
// ..F7.
// .FJ|.
// SJ.L7
// |F--J
// LJ...
//
// Here's the same example sketch with the extra, non-main-loop pipe tiles also shown:
//
// 7-F7-
// .FJ|7
// SJLL7
// |F--J
// LJ.LJ
//
// If you want to get out ahead of the animal, you should find the tile in the loop that is farthest from the starting position. Because the animal is in the pipe, it doesn't make sense to measure this by direct distance. Instead, you need to find the tile that would take the longest number of steps along the loop to reach from the starting point - regardless of which way around the loop the animal went.
//
// In the first example with the square loop:
//
// .....
// .S-7.
// .|.|.
// .L-J.
// .....
//
// You can count the distance each tile in the loop is from the starting point like this:
//
// .....
// .012.
// .1.3.
// .234.
// .....
//
// In this example, the farthest point from the start is 4 steps away.
//
// Here's the more complex loop again:
//
// ..F7.
// .FJ|.
// SJ.L7
// |F--J
// LJ...
//
// Here are the distances for each tile on that loop:
//
// ..45.
// .236.
// 01.78
// 14567
// 23...
//
// Find the single giant loop starting at S. How many steps along the loop does it take to get from the starting position to the point farthest from the starting position?
const std = @import("std");

const Direction = enum { NORTH, SOUTH, EAST, WEST };

const Location = struct {
    x: usize,
    y: usize,
    pipe: ?[2]Direction,
    traversed: bool = false,
};

test "example test" {
    const input =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(i32, 8), solution.part_one);
}

pub fn main() !void {
    const input = @embedFile("10_input.txt");
    const solution = try solve(input, .{});
    std.debug.print("{}\n", .{solution});
}

fn solve(input: []const u8, options: Options) !Solution {
    var part_two: i32 = 0;

    var map = std.ArrayList([]Location).init(options.allocator);
    var start: *Location = undefined;

    var x: usize = 0;
    var y: usize = 0;
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| : (y += 1) {
        if (line.len == 0) break;

        x = 0;
        const locations = try options.allocator.alloc(Location, line.len);
        while (x < line.len) : (x += 1) {
            // std.debug.print("y={}, x={}\n", .{ y, x });
            const pipe: ?[2]Direction = switch (line[x]) {
                '|' => .{ .NORTH, .SOUTH },
                '-' => .{ .EAST, .WEST },
                'L' => .{ .NORTH, .EAST },
                'J' => .{ .NORTH, .WEST },
                '7' => .{ .SOUTH, .WEST },
                'F' => .{ .SOUTH, .EAST },
                else => null,
            };
            locations[x] = Location{ .x = x, .y = y, .pipe = pipe };
            if (line[x] == 'S') start = &locations[x];
        }

        // std.debug.print("locations={any}\n", .{locations});
        try map.append(locations);
    }

    var phase: usize = 0;
    var next_directions: [2]Direction = undefined;
    var next_pipe_locations: [2]*Location = undefined;
    for (std.enums.values(Direction)) |direction| {
        x = start.*.x;
        y = start.*.y;
        if (direction == .NORTH and start.*.y > 0) y -= 1;
        if (direction == .SOUTH and start.*.y < (map.items.len - 1)) y += 1;
        if (direction == .EAST and start.*.x < (map.items[0].len - 1)) x += 1;
        if (direction == .WEST and start.*.x > 0) x -= 1;
        var from_direction: Direction = switch (direction) {
            .NORTH => .SOUTH,
            .SOUTH => .NORTH,
            .EAST => .WEST,
            .WEST => .EAST,
        };

        const location = &map.items[y][x];
        if (location.pipe != null) {
            if (location.pipe.?[0] != from_direction and location.pipe.?[1] != from_direction) {
                continue;
            }

            // std.debug.print("found start pipe {}, phase={}, next_direction{}\n", .{ location.*, phase, direction });
            next_directions[phase] = direction;
            next_pipe_locations[phase] = location;
            phase += 1;
        }
    }

    var steps: i32 = 0;
    var is_furthest_step = false;
    while (!is_furthest_step) {
        steps += 1;
        for (next_pipe_locations, 0..) |l, p| {
            var from_direction: Direction = switch (next_directions[p]) {
                .NORTH => .SOUTH,
                .SOUTH => .NORTH,
                .EAST => .WEST,
                .WEST => .EAST,
            };

            // std.debug.print("{}/{}: location={}, from={}\n", .{ steps, p, l, from_direction });
            if (l.*.traversed) {
                is_furthest_step = true;
                break;
            }

            var next_pipe = l.*.pipe.?;
            l.*.traversed = true;
            x = l.*.x;
            y = l.*.y;
            var to_direction = if (from_direction == next_pipe[0])
                next_pipe[1]
            else
                next_pipe[0];

            if (to_direction == .NORTH) y -= 1;
            if (to_direction == .SOUTH) y += 1;
            if (to_direction == .EAST) x += 1;
            if (to_direction == .WEST) x -= 1;

            // std.debug.print("{}/{}: to={}, next_y={}, next_x={}\n", .{ steps, p, to_direction, y, x });

            next_pipe_locations[p] = &map.items[y][x];
            next_directions[p] = to_direction;
        }
    }

    return .{ .part_one = steps, .part_two = part_two };
}

const Solution = struct { part_one: i32, part_two: i32 };

const Options = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
