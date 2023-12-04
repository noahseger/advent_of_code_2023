// --- Day 4: Scratchcards ---
//
// The gondola takes you up. Strangely, though, the ground doesn't seem to be coming with you; you're not climbing a mountain. As the circle of Snow Island recedes below you, an entire new landmass suddenly appears above you! The gondola carries you to the surface of the new island and lurches into the station.
//
// As you exit the gondola, the first thing you notice is that the air here is much warmer than it was on Snow Island. It's also quite humid. Is this where the water source is?
//
// The next thing you notice is an Elf sitting on the floor across the station in what seems to be a pile of colorful square cards.
//
// "Oh! Hello!" The Elf excitedly runs over to you. "How may I be of service?" You ask about water sources.
//
// "I'm not sure; I just operate the gondola lift. That does sound like something we'd have, though - this is Island Island, after all! I bet the gardener would know. He's on a different island, though - er, the small kind surrounded by water, not the floating kind. We really need to come up with a better naming scheme. Tell you what: if you can help me with something quick, I'll let you borrow my boat and you can go visit the gardener. I got all these scratchcards as a gift, but I can't figure out what I've won."
//
// The Elf leads you over to the pile of colorful cards. There, you discover dozens of scratchcards, all with their opaque covering already scratched off. Picking one up, it looks like each card has two lists of numbers separated by a vertical bar (|): a list of winning numbers and then a list of numbers you have. You organize the information into a table (your puzzle input).
//
// As far as the Elf has been able to figure out, you have to figure out which of the numbers you have appear in the list of winning numbers. The first match makes the card worth one point and each match after the first doubles the point value of that card.
//
// For example:
//
// Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
// Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
// Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
// Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
// Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
// Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
//
// In the above example, card 1 has five winning numbers (41, 48, 83, 86, and 17) and eight numbers you have (83, 86, 6, 31, 17, 9, 48, and 53). Of the numbers you have, four of them (48, 83, 17, and 86) are winning numbers! That means card 1 is worth 8 points (1 for the first match, then doubled three times for each of the three matches after the first).
//
//     Card 2 has two winning numbers (32 and 61), so it is worth 2 points.
//     Card 3 has two winning numbers (1 and 21), so it is worth 2 points.
//     Card 4 has one winning number (84), so it is worth 1 point.
//     Card 5 has no winning numbers, so it is worth no points.
//     Card 6 has no winning numbers, so it is worth no points.
//
// So, in this example, the Elf's pile of scratchcards is worth 13 points.
//
// Take a seat in the large pile of colorful cards. How many points are they worth in total?
const std = @import("std");

const Options = struct { allocator: std.mem.Allocator = std.heap.page_allocator };

const Solution = struct { points: u32 };

pub fn main() !void {
    const input = @embedFile("04_input.txt");
    const solution = try solve(input, .{});
    std.debug.print("{}\n", .{solution});
}

pub fn solve(input: []const u8, options: Options) !Solution {
    var points: u32 = 0;

    var lines = std.mem.split(u8, input, "\n");
    var line_number: u32 = 0;
    while (lines.next()) |line| : (line_number += 1) {
        // Skip the last newline.
        if (line.len == 0) continue;

        std.debug.print("{s}\n", .{line});
        var line_chunks = std.mem.split(u8, line, ":");
        // elide... header = Card 1
        _ = line_chunks.next();

        var body = line_chunks.next().?;
        var card_chunks = std.mem.split(u8, body, " |");

        var winning_numbers_cache = std.StringHashMap(bool).init(options.allocator);
        defer winning_numbers_cache.deinit();

        var winning_numbers_chunk = card_chunks.next().?;
        var raw_winning_numbers = std.mem.window(u8, winning_numbers_chunk, 3, 3);
        while (raw_winning_numbers.next()) |raw_winning_number| {
            std.debug.print("winning_number={s}\n", .{raw_winning_number});
            try winning_numbers_cache.put(raw_winning_number, true);
        }

        var my_numbers_chunk = card_chunks.next().?;
        var raw_my_numbers = std.mem.window(u8, my_numbers_chunk, 3, 3);
        var card_points: u32 = 0;
        while (raw_my_numbers.next()) |raw_my_number| {
            std.debug.print("my_number={s}\n", .{raw_my_number});
            const is_winning = winning_numbers_cache.get(raw_my_number) orelse false;
            if (is_winning and card_points == 0) {
                card_points = 1;
            } else if (is_winning) {
                card_points *= 2;
            }
        }

        points += card_points;
    }

    return .{ .points = points };
}

test "example test" {
    const input =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u32, 13), solution.points);
}
