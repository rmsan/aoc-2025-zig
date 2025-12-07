const std = @import("std");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part2 = try solvePart2(fileContent);
    const part2Time = timer.lap() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\n", .{ part1, part2, part1Time, part2Time });
}

const Part = enum { Part1, Part2 };

fn solve(comptime part: Part, input: []const u8) !usize {
    var result: usize = 0;
    var splits: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var beams: [142]usize = std.mem.zeroes([142]usize);

    const firstLine = lines.next().?;
    const startPos = std.mem.indexOfScalar(u8, firstLine, 'S').?;
    beams[startPos] = 1;

    while (lines.next()) |line| {
        for (0..line.len) |index| {
            if (line[index] == '^' and beams[index] > 0) {
                splits += 1;
                beams[index - 1] += beams[index];
                beams[index + 1] += beams[index];
                beams[index] = 0;
            }
        }
    }

    if (part == .Part1) {
        return splits;
    }

    for (beams) |beam| {
        result += beam;
    }

    return result;
}

fn solvePart1(input: []const u8) !usize {
    return solve(Part.Part1, input);
}

fn solvePart2(input: []const u8) !usize {
    return solve(Part.Part2, input);
}

test "test-input" {
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest);
    const part2 = try solvePart2(fileContentTest);

    try std.testing.expectEqual(part1, 21);
    try std.testing.expectEqual(part2, 40);
}
