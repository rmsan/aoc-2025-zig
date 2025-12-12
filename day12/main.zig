const std = @import("std");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part1Time = timer.read() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nTime1: {d}us\n", .{ part1, part1Time });
}

fn solvePart1(input: []const u8) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    // do not count the double new lines in the first 30 lines
    // so 30 - 6 = 24
    var lines_to_skip: usize = 24;
    while (lines.next()) |line| {
        if (lines_to_skip > 0) {
            lines_to_skip -= 1;
            continue;
        }
        const xPos = std.mem.indexOfScalar(u8, line, 'x').?;
        const endPos = std.mem.indexOfScalar(u8, line, ':').?;
        const width = try std.fmt.parseInt(usize, line[0..xPos], 10);
        const heigth = try std.fmt.parseInt(usize, line[xPos + 1 .. endPos], 10);
        const rest = line[endPos + 1 ..];
        var numbers = std.mem.tokenizeScalar(u8, rest, ' ');
        var sum: usize = 0;
        while (numbers.next()) |numberString| {
            const number = try std.fmt.parseInt(usize, numberString, 10);
            sum += number;
        }
        const capacity = @divFloor(width, 3) * @divFloor(heigth, 3);
        if (capacity >= sum) {
            result += 1;
        }
    }

    return result;
}

test "test-input" {
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest);

    // solution is only valid for real input
    try std.testing.expectEqual(part1, 0);
}
