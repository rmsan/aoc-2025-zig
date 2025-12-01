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

fn solvePart1(input: []const u8) !usize {
    var position: isize = 50;
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const operation = line[0];
        const distance = try std.fmt.parseInt(isize, line[1..], 10);
        if (operation == 'L') {
            position -= distance;
        } else {
            position += distance;
        }

        if (@mod(position, 100) == 0) {
            result += 1;
        }
    }
    return result;
}

fn solvePart2(input: []const u8) !usize {
    var position: isize = 50;
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const operation = line[0];
        const distance = try std.fmt.parseInt(isize, line[1..], 10);
        if (operation == 'L') {
            const distanceToPos = position - distance;
            const div = @divFloor(distanceToPos, 100);
            const mod = @mod(distanceToPos, 100);
            result += @intCast(@abs(div));
            if (position == 0 and mod > 0) {
                result -= 1;
            }
            if (position > 0 and mod == 0) {
                result += 1;
            }
            position = mod;
        } else {
            const distanceToPos = position + distance;
            const div = @divFloor(distanceToPos, 100);
            const mod = @mod(distanceToPos, 100);
            result += @intCast(div);
            position = mod;
        }
    }
    return result;
}

test "test-input" {
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest);
    const part2 = try solvePart2(fileContentTest);

    try std.testing.expectEqual(part1, 3);
    try std.testing.expectEqual(part2, 6);
}
