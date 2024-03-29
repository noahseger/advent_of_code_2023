// --- Day 8: Haunted Wasteland ---
//
// You're still riding a camel across Desert Island when you spot a sandstorm quickly approaching. When you turn to warn the Elf, she disappears before your eyes! To be fair, she had just finished warning you about ghosts a few minutes ago.
//
// One of the camel's pouches is labeled "maps" - sure enough, it's full of documents (your puzzle input) about how to navigate the desert. At least, you're pretty sure that's what they are; one of the documents contains a list of left/right instructions, and the rest of the documents seem to describe some kind of network of labeled nodes.
//
// It seems like you're meant to use the left/right instructions to navigate the network. Perhaps if you have the camel follow the same instructions, you can escape the haunted wasteland!
//
// After examining the maps for a bit, two nodes stick out: AAA and ZZZ. You feel like AAA is where you are now, and you have to follow the left/right instructions until you reach ZZZ.
//
// This format defines each node of the network individually. For example:
//
// RL
//
// AAA = (BBB, CCC)
// BBB = (DDD, EEE)
// CCC = (ZZZ, GGG)
// DDD = (DDD, DDD)
// EEE = (EEE, EEE)
// GGG = (GGG, GGG)
// ZZZ = (ZZZ, ZZZ)
//
// Starting with AAA, you need to look up the next element based on the next left/right instruction in your input. In this example, start with AAA and go right (R) by choosing the right element of AAA, CCC. Then, L means to choose the left element of CCC, ZZZ. By following the left/right instructions, you reach ZZZ in 2 steps.
//
// Of course, you might not find ZZZ right away. If you run out of left/right instructions, repeat the whole sequence of instructions as necessary: RL really means RLRLRLRLRLRLRLRL... and so on. For example, here is a situation that takes 6 steps to reach ZZZ:
//
// LLR
//
// AAA = (BBB, BBB)
// BBB = (AAA, ZZZ)
// ZZZ = (ZZZ, ZZZ)
//
// Starting at AAA, follow the left/right instructions. How many steps are required to reach ZZZ?
//
// --- Part Two ---
//
// The sandstorm is upon you and you aren't any closer to escaping the wasteland. You had the camel follow the instructions, but you've barely left your starting position. It's going to take significantly more steps to escape!
//
// What if the map isn't for people - what if the map is for ghosts? Are ghosts even bound by the laws of spacetime? Only one way to find out.
//
// After examining the maps a bit longer, your attention is drawn to a curious fact: the number of nodes with names ending in A is equal to the number ending in Z! If you were a ghost, you'd probably just start at every node that ends with A and follow all of the paths at the same time until they all simultaneously end up at nodes that end with Z.
//
// For example:
//
// LR
//
// 11A = (11B, XXX)
// 11B = (XXX, 11Z)
// 11Z = (11B, XXX)
// 22A = (22B, XXX)
// 22B = (22C, 22C)
// 22C = (22Z, 22Z)
// 22Z = (22B, 22B)
// XXX = (XXX, XXX)
//
// Here, there are two starting nodes, 11A and 22A (because they both end with A). As you follow each left/right instruction, use that instruction to simultaneously navigate away from both nodes you're currently on. Repeat this process until all of the nodes you're currently on end with Z. (If only some of the nodes you're on end with Z, they act like any other node and you continue as normal.) In this example, you would proceed as follows:
//
//     Step 0: You are at 11A and 22A.
//     Step 1: You choose all of the left paths, leading you to 11B and 22B.
//     Step 2: You choose all of the right paths, leading you to 11Z and 22C.
//     Step 3: You choose all of the left paths, leading you to 11B and 22Z.
//     Step 4: You choose all of the right paths, leading you to 11Z and 22B.
//     Step 5: You choose all of the left paths, leading you to 11B and 22C.
//     Step 6: You choose all of the right paths, leading you to 11Z and 22Z.
//
// So, in this example, you end up entirely on nodes that end in Z after 6 steps.
//
// Simultaneously start on every node that ends with A. How many steps does it take before you're only on nodes that end with Z?
const std = @import("std");

const Options = struct { allocator: std.mem.Allocator = std.heap.page_allocator };

const Solution = struct { required_steps: u32, required_steps_as_ghost: u64 };

const Map = struct {
    instructions: []const u8,
    elements: std.StringHashMap([2][]const u8),
    ghost_path: std.ArrayList(u64),

    pub fn init(instructions: []const u8, options: Options) Map {
        return .{
            .instructions = instructions,
            .elements = std.StringHashMap([2][]const u8).init(options.allocator),
            .ghost_path = std.ArrayList(u64).init(options.allocator),
        };
    }

    // Navigate from AAA to ZZZ, returning the number of steps taken.
    fn navigate(this: Map) u32 {
        var steps: u32 = 0;
        var element: []const u8 = "AAA";
        if (!this.elements.contains(element)) return 0;
        while (!std.mem.eql(u8, element, "ZZZ")) : (steps += 1) {
            const elements = this.elements.get(element).?;
            const instruction = this.instructions[steps % this.instructions.len];
            element = if (instruction == 'L') elements[0] else elements[1];
        }

        return steps;
    }

    // Navigate simultaneously from __A to __Z, returning the number of steps taken.
    fn navigateAsGhost(this: *Map) !u64 {
        var keys = this.elements.keyIterator();
        while (keys.next()) |key| {
            if (!std.mem.endsWith(u8, key.*, "A")) {
                continue;
            }

            // std.debug.print("path start: {s}\n", .{key.*});

            var steps: u32 = 0;
            var cycle_steps: u32 = 0;
            var zed_count: u32 = 0;
            var element = key.*;
            while (zed_count < 1) : (steps += 1) {
                const instruction = this.instructions[steps % this.instructions.len];
                const elements = this.elements.get(element).?;
                element = if (instruction == 'L') elements[0] else elements[1];
                if (std.mem.endsWith(u8, element, "Z")) {
                    // std.debug.print("{s} -> {s} in {} steps, {} step cycle\n", .{
                    //     key.*,
                    //     element,
                    //     steps,
                    //     steps - cycle_steps,
                    // });

                    zed_count += 1;

                    // All paths on the input have cycles, but the problem _seems_ to
                    // wants us to ignore them and use the first circuit as the multiple.
                    if (zed_count == 1) cycle_steps = steps;
                }
            }

            try this.ghost_path.append(steps);
        }

        // 22103062509257
        // Expect 27450 15847 22922 31978 39902 41317
        // std.debug.print("ghost_path={any}", .{this.ghost_path.items});
        return lcm(this.ghost_path.items);
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = @embedFile("08_input.txt");
    const solution = try solve(input, .{ .allocator = arena.allocator() });
    std.debug.print("{}\n", .{solution});
}

pub fn solve(input: []const u8, options: Options) !Solution {
    var lines = std.mem.split(u8, input, "\n");

    // Parse map instructions
    var map = Map.init(lines.next().?, options);

    // Parse map elements
    while (lines.next()) |line| {
        // Skip empty lines
        if (line.len == 0) continue;

        var chunks = std.mem.split(u8, line, " = ");
        const key = chunks.next().?;

        const value_chunk = std.mem.trim(u8, chunks.next().?, "()");
        var value_iterator = std.mem.split(u8, value_chunk, ", ");
        var values: [2][]const u8 = .{ value_iterator.next().?, value_iterator.next().? };

        try map.elements.put(key, values);
    }

    return .{
        .required_steps = map.navigate(),
        .required_steps_as_ghost = try map.navigateAsGhost(),
    };
}

fn gcd(a: *u64, b: *u64) u64 {
    var temp: *u64 = undefined;
    while (b > 0) {
        temp = b.* % a.*;
        a = b;
        b = temp;
    }

    return a;
}

fn lcm(numbers: []u64) u64 {
    var result: u64 = 1;
    for (numbers) |n| {
        result = result * n / gcd(&result, &n);
    }

    return result;
}

test "example test" {
    const input =
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u32, 2), solution.required_steps);
    try std.testing.expectEqual(@as(u64, 2), solution.required_steps_as_ghost);
}

test "ghost test" {
    const input =
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u32, 0), solution.required_steps);
    try std.testing.expectEqual(@as(u64, 6), solution.required_steps_as_ghost);
}
