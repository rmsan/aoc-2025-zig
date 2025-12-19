const std = @import("std");

pub fn main() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();
    const allocator = arenaAllocator.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, allocator);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part2 = try solvePart2(fileContent, allocator);
    const part2Time = timer.lap() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\n", .{ part1, part2, part1Time, part2Time });
}

fn cmpRange(context: void, a: [2]usize, b: [2]usize) bool {
    _ = context;
    return (a[0] < b[0]);
}

inline fn contains(haystack: [2]usize, needle: usize) bool {
    return needle >= haystack[0] and needle <= haystack[1];
}

fn solvePart1(input: []const u8, allocator: std.mem.Allocator) !usize {
    var result: usize = 0;
    var ranges = try std.ArrayList([2]usize).initCapacity(allocator, 185);
    defer ranges.deinit(allocator);
    var segments = std.mem.tokenizeSequence(u8, input, "\n\n");
    const ranges_segment = segments.next().?;
    const ingredients_segment = segments.next().?;
    var ranges_strings = std.mem.tokenizeScalar(u8, ranges_segment, '\n');
    var ingredients_strings = std.mem.tokenizeScalar(u8, ingredients_segment, '\n');

    while (ranges_strings.next()) |range_line| {
        var range_iter = std.mem.tokenizeScalar(u8, range_line, '-');
        const start_string = range_iter.next().?;
        const end_string = range_iter.next().?;
        const start = try std.fmt.parseInt(usize, start_string, 10);
        const end = try std.fmt.parseInt(usize, end_string, 10);

        ranges.appendAssumeCapacity([2]usize{ start, end });
    }

    std.mem.sortUnstable([2]usize, ranges.items, {}, cmpRange);
    while (ingredients_strings.next()) |ingredients_string| {
        const ingredient = try std.fmt.parseInt(usize, ingredients_string, 10);
        for (ranges.items) |range| {
            if (contains(range, ingredient)) {
                result += 1;
                break;
            }
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: std.mem.Allocator) !usize {
    var result: usize = 0;
    var ranges = try std.ArrayList([2]usize).initCapacity(allocator, 185);
    defer ranges.deinit(allocator);
    var segments = std.mem.tokenizeSequence(u8, input, "\n\n");
    const ranges_segment = segments.next().?;
    var ranges_strings = std.mem.tokenizeScalar(u8, ranges_segment, '\n');

    while (ranges_strings.next()) |range_line| {
        var range_to_parse = std.mem.tokenizeScalar(u8, range_line, '-');
        const start_string = range_to_parse.next().?;
        const end_string = range_to_parse.next().?;
        const start = try std.fmt.parseInt(usize, start_string, 10);
        const end = try std.fmt.parseInt(usize, end_string, 10);

        ranges.appendAssumeCapacity([2]usize{ start, end });
    }

    std.mem.sortUnstable([2]usize, ranges.items, {}, cmpRange);
    var merged_ranges = try std.ArrayList([2]usize).initCapacity(allocator, ranges.items.len);
    defer merged_ranges.deinit(allocator);
    var current_range = ranges.items[0];
    for (ranges.items[1..]) |range| {
        if (range[0] <= current_range[1] + 1) {
            if (range[1] > current_range[1]) {
                current_range[1] = range[1];
            }
        } else {
            merged_ranges.appendAssumeCapacity(current_range);
            current_range = range;
        }
    }
    merged_ranges.appendAssumeCapacity(current_range);

    for (merged_ranges.items) |range| {
        result += (range[1] - range[0] + 1);
    }

    return result;
}

test "test-input" {
    const allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, allocator);
    const part2 = try solvePart2(fileContentTest, allocator);

    try std.testing.expectEqual(part1, 3);
    try std.testing.expectEqual(part2, 14);
}
