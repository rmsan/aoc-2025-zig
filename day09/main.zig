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

fn parseAndGetRanges(input: []const u8, allocator: *std.mem.Allocator) !std.ArrayList([2]isize) {
    var ranges = try std.ArrayList([2]isize).initCapacity(allocator.*, 500);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var rangeString = std.mem.tokenizeScalar(u8, line, ',');
        const xString = rangeString.next().?;
        const yString = rangeString.next().?;

        const x = try std.fmt.parseInt(isize, xString, 10);
        const y = try std.fmt.parseInt(isize, yString, 10);

        ranges.appendAssumeCapacity([2]isize{ x, y });
    }
    return ranges;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var ranges = try parseAndGetRanges(input, allocator);
    defer ranges.deinit(allocator.*);

    for (ranges.items[0..ranges.items.len]) |first| {
        for (ranges.items[1..]) |second| {
            const dist: usize = @intCast((@abs(first[0] - second[0]) + 1) * (@abs(first[1] - second[1]) + 1));
            result = @max(result, dist);
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var ranges = try parseAndGetRanges(input, allocator);
    defer ranges.deinit(allocator.*);

    const rangesLen = ranges.items.len;

    for (0..rangesLen) |i| {
        for (i + 1..rangesLen) |j| {
            const minX = @min(ranges.items[i][0], ranges.items[j][0]);
            const minY = @min(ranges.items[i][1], ranges.items[j][1]);
            const maxX = @max(ranges.items[i][0], ranges.items[j][0]);
            const maxY = @max(ranges.items[i][1], ranges.items[j][1]);

            var valid = true;
            for (0..rangesLen) |k| {
                const currX = ranges.items[k][0];
                const currY = ranges.items[k][1];
                const next = @mod((k + 1), rangesLen);
                const nextX = ranges.items[next][0];
                const nextY = ranges.items[next][1];

                // Check if the line segment from (currX, currY) to (nextX, nextY) intersects the rectangle
                if (!(minX >= @max(currX, nextX) or
                    maxX <= @min(currX, nextX) or
                    minY >= @max(currY, nextY) or
                    maxY <= @min(currY, nextY)))
                {
                    valid = false;
                    break;
                }
            }
            if (valid) {
                const first = ranges.items[i];
                const second = ranges.items[j];
                const dist: usize = @intCast((@abs(first[0] - second[0]) + 1) * (@abs(first[1] - second[1]) + 1));
                result = @max(result, dist);
            }
        }
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 50);
    try std.testing.expectEqual(part2, 24);
}
