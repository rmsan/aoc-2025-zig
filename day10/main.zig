const std = @import("std");

pub fn main() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();
    var allocator = arenaAllocator.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part2 = try solvePart2(fileContent, &allocator);
    const part2Time = timer.lap() / std.time.ns_per_ms;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}ms\n", .{ part1, part2, part1Time, part2Time });
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var buttons = try std.ArrayList(usize).initCapacity(allocator.*, 20);
        defer buttons.deinit(allocator.*);

        var segments = std.mem.tokenizeScalar(u8, line, ' ');
        const lightString = segments.next().?;
        const light = lightString[1 .. lightString.len - 1];
        var lightNumber: usize = 0;
        for (light, 0..) |lightChar, lightIndex| {
            if (lightChar == '#') {
                lightNumber += std.math.pow(usize, 2, lightIndex);
            }
        }

        while (segments.next()) |segment| {
            var buttonNumber: usize = 0;
            // ignore last segment
            if (segments.peek() == null) {
                break;
            }
            const segmentString = segment[1 .. segment.len - 1];
            var buttonSegments = std.mem.tokenizeScalar(u8, segmentString, ',');
            while (buttonSegments.next()) |buttonSegment| {
                const buttonChar = buttonSegment[0] - '0';
                buttonNumber += std.math.pow(usize, 2, buttonChar);
            }
            buttons.appendAssumeCapacity(buttonNumber);
        }

        var current = std.AutoHashMap(usize, void).init(allocator.*);
        var next = std.AutoHashMap(usize, void).init(allocator.*);
        defer {
            current.deinit();
            next.deinit();
        }

        var iterations: usize = 0;
        const end: usize = 0;

        try current.put(lightNumber, {});

        while (!current.contains(end)) {
            next.clearRetainingCapacity();

            var iter = current.keyIterator();
            outer: while (iter.next()) |curr| {
                for (buttons.items) |button| {
                    const pattern = curr.* ^ button;
                    try next.put(pattern, {});
                    if (pattern == 0) {
                        break :outer;
                    }
                }
            }

            std.mem.swap(@TypeOf(current), &current, &next);
            iterations += 1;
        }

        result += iterations;
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    _ = allocator;
    _ = input;
    result += 0;
    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 7);
    try std.testing.expectEqual(part2, 0);
}
