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
const std = @import("std");

const Options = struct { allocator: std.mem.Allocator = std.heap.page_allocator };

const Solution = struct { required_steps: u32 };

const Map = struct {
    instructions: []const u8,
    elements: std.StringHashMap([2][]const u8),

    // Navigate from AAA to ZZZ, returning the number of steps taken.
    fn navigate(this: Map) u32 {
        var steps: u32 = 0;
        var element: []const u8 = "AAA";
        while (!std.mem.eql(u8, element, "ZZZ")) : (steps += 1) {
            const elements = this.elements.get(element).?;
            const instruction = this.instructions[steps % this.instructions.len];
            element = if (instruction == 'L') elements[0] else elements[1];
        }

        return steps;
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
    const instructions = lines.next().?;

    // Parse map elements
    var elements = std.StringHashMap([2][]const u8).init(options.allocator);
    while (lines.next()) |line| {
        // Skip empty lines
        if (line.len == 0) continue;

        var chunks = std.mem.split(u8, line, " = ");
        const key = chunks.next().?;

        const value_chunk = std.mem.trim(u8, chunks.next().?, "()");
        var value_iterator = std.mem.split(u8, value_chunk, ", ");
        var values: [2][]const u8 = .{ value_iterator.next().?, value_iterator.next().? };

        try elements.put(key, values);
    }

    const map = Map{ .instructions = instructions, .elements = elements };
    return .{ .required_steps = map.navigate() };
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
}

test "modulo" {
    const nextInstruction = struct {
        fn nextInstruction(step: usize) u8 {
            const instructions = "LR";
            const i = step % instructions.len;
            return instructions[i];
        }
    }.nextInstruction;

    try std.testing.expectEqual(nextInstruction(0), 'L');
    try std.testing.expectEqual(nextInstruction(1), 'R');
    try std.testing.expectEqual(nextInstruction(2), 'L');
    try std.testing.expectEqual(nextInstruction(3), 'R');
    try std.testing.expectEqual(nextInstruction(4), 'L');
}
