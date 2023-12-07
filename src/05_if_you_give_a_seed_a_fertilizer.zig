// --- Day 5: If You Give A Seed A Fertilizer ---
//
// You take the boat and find the gardener right where you were told he would be: managing a giant "garden" that looks more to you like a farm.
//
// "A water source? Island Island is the water source!" You point out that Snow Island isn't receiving any water.
//
// "Oh, we had to stop the water because we ran out of sand to filter it with! Can't make snow with dirty water. Don't worry, I'm sure we'll get more sand soon; we only turned off the water a few days... weeks... oh no." His face sinks into a look of horrified realization.
//
// "I've been so busy making sure everyone here has food that I completely forgot to check why we stopped getting more sand! There's a ferry leaving soon that is headed over in that direction - it's much faster than your boat. Could you please go check it out?"
//
// You barely have time to agree to this request when he brings up another. "While you wait for the ferry, maybe you can help us with our food production problem. The latest Island Island Almanac just arrived and we're having trouble making sense of it."
//
// The almanac (your puzzle input) lists all of the seeds that need to be planted. It also lists what type of soil to use with each kind of seed, what type of fertilizer to use with each kind of soil, what type of water to use with each kind of fertilizer, and so on. Every type of seed, soil, fertilizer and so on is identified with a number, but numbers are reused by each category - that is, soil 123 and fertilizer 123 aren't necessarily related to each other.
//
// For example:
//
// seeds: 79 14 55 13
//
// seed-to-soil map:
// 50 98 2
// 52 50 48
//
// soil-to-fertilizer map:
// 0 15 37
// 37 52 2
// 39 0 15
//
// fertilizer-to-water map:
// 49 53 8
// 0 11 42
// 42 0 7
// 57 7 4
//
// water-to-light map:
// 88 18 7
// 18 25 70
//
// light-to-temperature map:
// 45 77 23
// 81 45 19
// 68 64 13
//
// temperature-to-humidity map:
// 0 69 1
// 1 0 69
//
// humidity-to-location map:
// 60 56 37
// 56 93 4
//
// The almanac starts by listing which seeds need to be planted: seeds 79, 14, 55, and 13.
//
// The rest of the almanac contains a list of maps which describe how to convert numbers from a source category into numbers in a destination category. That is, the section that starts with seed-to-soil map: describes how to convert a seed number (the source) to a soil number (the destination). This lets the gardener and his team know which soil to use with which seeds, which water to use with which fertilizer, and so on.
//
// Rather than list every source number and its corresponding destination number one by one, the maps describe entire ranges of numbers that can be converted. Each line within a map contains three numbers: the destination range start, the source range start, and the range length.
//
// Consider again the example seed-to-soil map:
//
// 50 98 2
// 52 50 48
//
// The first line has a destination range start of 50, a source range start of 98, and a range length of 2. This line means that the source range starts at 98 and contains two values: 98 and 99. The destination range is the same length, but it starts at 50, so its two values are 50 and 51. With this information, you know that seed number 98 corresponds to soil number 50 and that seed number 99 corresponds to soil number 51.
//
// The second line means that the source range starts at 50 and contains 48 values: 50, 51, ..., 96, 97. This corresponds to a destination range starting at 52 and also containing 48 values: 52, 53, ..., 98, 99. So, seed number 53 corresponds to soil number 55.
//
// Any source numbers that aren't mapped correspond to the same destination number. So, seed number 10 corresponds to soil number 10.
//
// So, the entire list of seed numbers and their corresponding soil numbers looks like this:
//
// seed  soil
// 0     0
// 1     1
// ...   ...
// 48    48
// 49    49
// 50    52
// 51    53
// ...   ...
// 96    98
// 97    99
// 98    50
// 99    51
//
// With this map, you can look up the soil number required for each initial seed number:
//
//     Seed number 79 corresponds to soil number 81.
//     Seed number 14 corresponds to soil number 14.
//     Seed number 55 corresponds to soil number 57.
//     Seed number 13 corresponds to soil number 13.
//
// The gardener and his team want to get started as soon as possible, so they'd like to know the closest location that needs a seed. Using these maps, find the lowest location number that corresponds to any of the initial seeds. To do this, you'll need to convert each seed number through other categories until you can find its corresponding location number. In this example, the corresponding types are:
//
//     Seed 79, soil 81, fertilizer 81, water 81, light 74, temperature 78, humidity 78, location 82.
//     Seed 14, soil 14, fertilizer 53, water 49, light 42, temperature 42, humidity 43, location 43.
//     Seed 55, soil 57, fertilizer 57, water 53, light 46, temperature 82, humidity 82, location 86.
//     Seed 13, soil 13, fertilizer 52, water 41, light 34, temperature 34, humidity 35, location 35.
//
// So, the lowest location number in this example is 35.
//
// What is the lowest location number that corresponds to any of the initial seed numbers?
const std = @import("std");

const Options = struct { allocator: std.mem.Allocator = std.heap.page_allocator };

const Solution = struct { lowest_location_number: u32 };

const MapRange = struct {
    destination: u32,
    source: u32,
    length: u32,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = @embedFile("05_input.txt");
    const solution = try solve(input, .{ .allocator = arena.allocator() });
    std.debug.print("{}\n", .{solution});
}

pub fn solve(input: []const u8, options: Options) !Solution {
    var lowest_location_number: u32 = std.math.maxInt(u32);
    // std.debug.print("maxInt={}\n", .{lowest_location_number});

    var lines = std.mem.split(u8, input, "\n");

    // Parse seed numbers from first line...
    var seeds = std.AutoHashMap(u32, void).init(options.allocator);
    defer seeds.deinit();

    var seed_line_chunks = std.mem.split(u8, lines.next().?, ": ");
    _ = seed_line_chunks.next();

    var raw_seeds = std.mem.split(u8, seed_line_chunks.next().?, " ");
    while (raw_seeds.next()) |raw_seed| {
        const seed = try std.fmt.parseInt(u32, raw_seed, 10);
        try seeds.put(seed, {});
        // std.debug.print("seed={}\n", .{seed});
    }

    // Allocate range maps...
    var seedToSoilMap = std.AutoHashMap(u32, MapRange).init(options.allocator);
    var soilToFertilizerMap = std.AutoHashMap(u32, MapRange).init(options.allocator);
    var fertilizerToWaterMap = std.AutoHashMap(u32, MapRange).init(options.allocator);
    var waterToLightMap = std.AutoHashMap(u32, MapRange).init(options.allocator);
    var lightToTemperatureMap = std.AutoHashMap(u32, MapRange).init(options.allocator);
    var temperatureToHumidityMap = std.AutoHashMap(u32, MapRange).init(options.allocator);
    var humidityToLocationMap = std.AutoHashMap(u32, MapRange).init(options.allocator);

    // Parse map ranges...
    var line_number: u32 = 0;
    var currentMap: *std.AutoHashMap(u32, MapRange) = &seedToSoilMap;
    while (lines.next()) |line| : (line_number += 1) {
        // Skip the last newline.
        if (line.len == 0) continue;

        std.debug.print("{s}\n", .{line});

        // Ugh...
        if (std.mem.startsWith(u8, line, "seed-to-soil")) {
            currentMap = &seedToSoilMap;
            continue;
        } else if (std.mem.startsWith(u8, line, "soil-to-fertilizer")) {
            currentMap = &soilToFertilizerMap;
            continue;
        } else if (std.mem.startsWith(u8, line, "fertilizer-to-water")) {
            currentMap = &fertilizerToWaterMap;
            continue;
        } else if (std.mem.startsWith(u8, line, "water-to-light")) {
            currentMap = &waterToLightMap;
            continue;
        } else if (std.mem.startsWith(u8, line, "light-to-temperature")) {
            currentMap = &lightToTemperatureMap;
            continue;
        } else if (std.mem.startsWith(u8, line, "temperature-to-humidity")) {
            currentMap = &temperatureToHumidityMap;
            continue;
        } else if (std.mem.startsWith(u8, line, "humidity-to-location")) {
            currentMap = &humidityToLocationMap;
            continue;
        }

        // Parse and set ranges...
        const range = try parseRange(line);
        try currentMap.put(range.source, range);
    }

    // Find lowest location number from maps...
    var keys = seeds.keyIterator();
    while (keys.next()) |key| {
        const seed = key.*;
        const soil = mapRange(seed, seedToSoilMap);
        const fertilizer = mapRange(soil, soilToFertilizerMap);
        const water = mapRange(fertilizer, fertilizerToWaterMap);
        const light = mapRange(water, waterToLightMap);
        const temperature = mapRange(light, lightToTemperatureMap);
        const humidity = mapRange(temperature, temperatureToHumidityMap);
        const location = mapRange(humidity, humidityToLocationMap);

        // std.debug.print("Seed {}, soil {}, fertilizer {}, water {}, light {}, temperature {}, humidity {}, location {}\n", .{ seed, soil, fertilizer, water, light, temperature, humidity, location });
        if (location < lowest_location_number) {
            lowest_location_number = location;
        }
    }

    return .{ .lowest_location_number = lowest_location_number };
}

fn parseRange(line: []const u8) !MapRange {
    var chunks = std.mem.split(u8, line, " ");
    return .{
        .destination = try std.fmt.parseInt(u32, chunks.next().?, 10),
        .source = try std.fmt.parseInt(u32, chunks.next().?, 10),
        .length = try std.fmt.parseInt(u32, chunks.next().?, 10),
    };
}

fn mapRange(input: u32, map: std.AutoHashMap(u32, MapRange)) u32 {
    var values = map.valueIterator();
    while (values.next()) |value| {
        // std.debug.print("input={}, source={}, destination={}, length={}", .{ input, value.source, value.destination, value.length });
        if (input >= value.source and (input - value.source) < value.length) {
            return value.destination + (input - value.source);
        }
    }

    return input;
}

test "example test" {
    const input =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;
    const solution = try solve(input, .{});
    try std.testing.expectEqual(@as(u32, 35), solution.lowest_location_number);
}
