// --- Day 12: Hot Springs ---

// You finally reach the hot springs! You can see steam rising from secluded areas attached to the primary, ornate building.

// As you turn to enter, the researcher stops you. "Wait - I thought you were looking for the hot springs, weren't you?" You indicate that this definitely looks like hot springs to you.

// "Oh, sorry, common mistake! This is actually the onsen! The hot springs are next door."

// You look in the direction the researcher is pointing and suddenly notice the massive metal helixes towering overhead. "This way!"

// It only takes you a few more steps to reach the main gate of the massive fenced-off area containing the springs. You go through the gate and into a small administrative building.

// "Hello! What brings you to the hot springs today? Sorry they're not very hot right now; we're having a lava shortage at the moment." You ask about the missing machine parts for Desert Island.

// "Oh, all of Gear Island is currently offline! Nothing is being manufactured at the moment, not until we get more lava to heat our forges. And our springs. The springs aren't very springy unless they're hot!"

// "Say, could you go up and see why the lava stopped flowing? The springs are too cold for normal operation, but we should be able to find one springy enough to launch you up there!"

// There's just one problem - many of the springs have fallen into disrepair, so they're not actually sure which springs would even be safe to use! Worse yet, their condition records of which springs are damaged (your puzzle input) are also damaged! You'll need to help them repair the damaged records.

// In the giant field just outside, the springs are arranged into rows. For each row, the condition records show every spring and whether it is operational (.) or damaged (#). This is the part of the condition records that is itself damaged; for some springs, it is simply unknown (?) whether the spring is operational or damaged.

// However, the engineer that produced the condition records also duplicated some of this information in a different format! After the list of springs for a given row, the size of each contiguous group of damaged springs is listed in the order those groups appear in the row. This list always accounts for every damaged spring, and each number is the entire size of its contiguous group (that is, groups are always separated by at least one operational spring: #### would always be 4, never 2,2).

// So, condition records with no unknown spring conditions might look like this:

// #.#.### 1,1,3
// .#...#....###. 1,1,3
// .#.###.#.###### 1,3,1,6
// ####.#...#... 4,1,1
// #....######..#####. 1,6,5
// .###.##....# 3,2,1

// However, the condition records are partially damaged; some of the springs' conditions are actually unknown (?). For example:

// ???.### 1,1,3
// .??..??...?##. 1,1,3
// ?#?#?#?#?#?#?#? 1,3,1,6
// ????.#...#... 4,1,1
// ????.######..#####. 1,6,5
// ?###???????? 3,2,1

// Equipped with this information, it is your job to figure out how many different arrangements of operational and broken springs fit the given criteria in each row.

// In the first line (???.### 1,1,3), there is exactly one way separate groups of one, one, and three broken springs (in that order) can appear in that row: the first three unknown springs must be broken, then operational, then broken (#.#), making the whole row #.#.###.

// The second line is more interesting: .??..??...?##. 1,1,3 could be a total of four different arrangements. The last ? must always be broken (to satisfy the final contiguous group of three broken springs), and each ?? must hide exactly one of the two broken springs. (Neither ?? could be both broken springs or they would form a single contiguous group of two; if that were true, the numbers afterward would have been 2,3 instead.) Since each ?? can either be #. or .#, there are four possible arrangements of springs.

// The last line is actually consistent with ten different arrangements! Because the first number is 3, the first and second ? must both be . (if either were #, the first number would have to be 4 or higher). However, the remaining run of unknown spring conditions have many different ways they could hold groups of two and one broken springs:

// ?###???????? 3,2,1
// .###.##.#...
// .###.##..#..
// .###.##...#.
// .###.##....#
// .###..##.#..
// .###..##..#.
// .###..##...#
// .###...##.#.
// .###...##..#
// .###....##.#

// In this example, the number of possible arrangements for each row is:

//     ???.### 1,1,3 - 1 arrangement
//     .??..??...?##. 1,1,3 - 4 arrangements
//     ?#?#?#?#?#?#?#? 1,3,1,6 - 1 arrangement
//     ????.#...#... 4,1,1 - 1 arrangement
//     ????.######..#####. 1,6,5 - 4 arrangements
//     ?###???????? 3,2,1 - 10 arrangements

// Adding all of the possible arrangement counts together produces a total of 21 arrangements.

// For each row, count all of the different arrangements of operational and broken springs that meet the given criteria. What is the sum of those counts?

// --- Part Two ---

// As you look out at the field of springs, you feel like there are way more springs than the condition records list. When you examine the records, you discover that they were actually folded up this whole time!

// To unfold the records, on each row, replace the list of spring conditions with five copies of itself (separated by ?) and replace the list of contiguous groups of damaged springs with five copies of itself (separated by ,).

// So, this row:

// .# 1

// Would become:

// .#?.#?.#?.#?.# 1,1,1,1,1

// The first line of the above example would become:

// ???.###????.###????.###????.###????.### 1,1,3,1,1,3,1,1,3,1,1,3,1,1,3

// In the above example, after unfolding, the number of possible arrangements for some rows is now much larger:

//     ???.### 1,1,3 - 1 arrangement
//     .??..??...?##. 1,1,3 - 16384 arrangements
//     ?#?#?#?#?#?#?#? 1,3,1,6 - 1 arrangement
//     ????.#...#... 4,1,1 - 16 arrangements
//     ????.######..#####. 1,6,5 - 2500 arrangements
//     ?###???????? 3,2,1 - 506250 arrangements

// After unfolding, adding all of the possible arrangement counts together produces 525152.

// Unfold your condition records; what is the new sum of possible arrangement counts?
const std = @import("std");

const Record = struct { arrangement: []const u8, counts: []const u64 };

const Cache = std.HashMap(Record, u64, struct {
    pub fn hash(self: @This(), key: Record) u64 {
        _ = self;
        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHashStrat(&hasher, key, .Deep);
        return hasher.final();
    }

    pub fn eql(self: @This(), a: Record, b: Record) bool {
        _ = self;
        return std.meta.eql(a, b);
    }
}, std.hash_map.default_max_load_percentage);

test "example test" {
    const input =
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u64, 21), solution.part_one);
}

pub fn main() !void {
    const input = @embedFile("12_input.txt");
    const solution = try solve(input, .{});
    std.debug.print("{}\n", .{solution});
}

fn solve(input: []const u8, options: Options) !Solution {
    var part_one: u64 = 0;
    var part_two: u64 = 0;

    // var cache = std.HashMap(Record, u64, Record, std.hash_map.default_max_load_percentage);
    var cache = Cache.init(options.allocator);
    // std.meta.eql(Record{ .arrangement = "foo", .counts = .{ 1, 2, 3 } }, Record{ .arrangement = "bar", .counts = .{ 1, 2, 3 } });

    // Part one
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var chunks = std.mem.splitScalar(u8, line, ' ');
        const pattern = chunks.next().?;
        const count_chunk = chunks.next().?;
        var count_iterator = std.mem.splitScalar(u8, count_chunk, ',');
        var counts = std.ArrayList(u64).init(options.allocator);
        while (count_iterator.next()) |raw_count| {
            const count = try std.fmt.parseInt(u64, raw_count, 10);
            try counts.append(count);
        }

        part_one += try fit(pattern, counts.items, &cache);
    }

    // Part two
    lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var chunks = std.mem.splitScalar(u8, line, ' ');
        const pattern = chunks.next().?;

        const count_chunk = chunks.next().?;
        var count_iterator = std.mem.splitScalar(u8, count_chunk, ',');
        var counts = std.ArrayList(u64).init(options.allocator);
        while (count_iterator.next()) |raw_count| {
            const count = try std.fmt.parseInt(u64, raw_count, 10);
            try counts.append(count);
        }

        // Unfold
        var unfolded_pattern = std.ArrayList(u8).init(options.allocator);
        var unfolded_counts = std.ArrayList(u64).init(options.allocator);
        for (0..5) |i| {
            try unfolded_pattern.appendSlice(pattern);
            if (i != 4) try unfolded_pattern.append('?');
            try unfolded_counts.appendSlice(counts.items);
        }

        part_two += try fit(unfolded_pattern.items, unfolded_counts.items, &cache);
    }

    // std.debug.print("{} galaxies...\n", .{galaxies.items.len});

    return .{ .part_one = part_one, .part_two = part_two };
}

fn fit(pattern: []const u8, counts: []const u64, cache: *Cache) !u64 {
    // try std.io.getStdOut().writer().print("fitting pattern={s}, counts={any}\n", .{ pattern, counts });

    const key = Record{ .arrangement = pattern, .counts = counts };
    if (cache.contains(key)) {
        // std.debug.print("cached, pattern={s}, counts={any}, value={any}\n", .{ pattern, counts, cache.get(key) });
        return cache.get(key).?;
    }

    if (counts.len == 0) {
        // std.debug.print("EMPTY WITH PATTERN={s}\n", .{pattern});
        return if (std.mem.count(u8, pattern, "#") == 0) 1 else 0;
    }

    const count = counts[0];
    const next_counts = counts[1..];
    const window = pattern.len - (sum(next_counts) + next_counts.len) - count;

    var total: u64 = 0;
    var i: usize = 0;
    var left_border: []const u8 = "";
    while (i < window + 1) : (i += 1) {
        // std.debug.print("...left_border={s}\n", .{left_border});
        if (std.mem.eql(u8, left_border, "#")) break;

        const right_border: []const u8 = if (i + count == pattern.len) "" else pattern[i + count .. i + count + 1];
        // std.debug.print("...right_border={s}\n", .{right_border});

        if (std.mem.count(u8, pattern[i .. i + count], ".") == 0 and !std.mem.eql(u8, right_border, "#")) {
            const right_total = try fit(pattern[i + count + right_border.len ..], next_counts, cache);
            total += right_total;
            // try std.io.getStdOut().writer().print("TOTAL={} (+{})\n", .{ total, right_total });
        }

        left_border = pattern[i .. i + 1];
    }

    try cache.put(key, total);
    return total;
}

fn max(values: []const u64) u64 {
    var result: u64 = 0;
    for (values) |value| {
        if (value > result) result = value;
    }
    return result;
}

fn sum(values: []const u64) u64 {
    var result: u64 = 0;
    for (values) |value| result += value;
    return result;
}

const Solution = struct { part_one: u64, part_two: u64 };

const Options = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
