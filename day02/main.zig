const std = @import("std");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part1Time = timer.lap() / std.time.ns_per_ms;
    const part2 = try solvePart2(fileContent);
    const part2Time = timer.lap() / std.time.ns_per_ms;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}ms\nTime2: {d}ms\n", .{ part1, part2, part1Time, part2Time });
}

fn solvePart1(input: []const u8) !usize {
    var result: usize = 0;
    var sequences = std.mem.tokenizeScalar(u8, input, ',');
    while (sequences.next()) |sequence| {
        var numbers = std.mem.tokenizeScalar(u8, sequence, '-');
        const firstNumberString = numbers.next().?;
        const secondNumberString = numbers.next().?;
        const firstNumber = try std.fmt.parseInt(usize, firstNumberString, 10);
        const secondNumber = try std.fmt.parseInt(usize, secondNumberString, 10);

        for (firstNumber..secondNumber + 1) |toCheck| {
            var buf: [16]u8 = undefined;
            const numberAsString = try std.fmt.bufPrint(buf[0..], "{d}", .{toCheck});

            const numberLength = numberAsString.len;
            if (numberLength % 2 != 0) {
                continue;
            }

            const halfSize = numberLength / 2;
            const leftSide = numberAsString[0..halfSize];
            const rightSide = numberAsString[halfSize..];
            if (std.mem.eql(u8, leftSide, rightSide)) {
                result += toCheck;
            }
        }
    }
    return result;
}

fn solvePart2(input: []const u8) !usize {
    var result: usize = 0;
    var sequences = std.mem.tokenizeScalar(u8, input, ',');
    while (sequences.next()) |sequence| {
        var numbers = std.mem.tokenizeScalar(u8, sequence, '-');
        const firstNumberString = numbers.next().?;
        const secondNumberString = numbers.next().?;
        const firstNumber = try std.fmt.parseInt(usize, firstNumberString, 10);
        const secondNumber = try std.fmt.parseInt(usize, secondNumberString, 10);

        for (firstNumber..secondNumber + 1) |toCheck| {
            var buf: [16]u8 = undefined;
            const numberAsString = try std.fmt.bufPrint(buf[0..], "{d}", .{toCheck});

            const numberLength = numberAsString.len;
            const halfSize = numberLength / 2;
            for (1..halfSize + 1) |blockLength| {
                if (numberLength % blockLength != 0) {
                    continue;
                }

                var allOk = true;
                const numberToCheck = numberAsString[0..blockLength];
                var blockLengthCurr = blockLength;
                while (blockLengthCurr < numberLength) : (blockLengthCurr += blockLength) {
                    const otherNumber = numberAsString[blockLengthCurr .. blockLengthCurr + blockLength];
                    if (!std.mem.eql(u8, numberToCheck, otherNumber)) {
                        allOk = false;
                        break;
                    }
                }

                if (allOk) {
                    result += toCheck;
                    break;
                }
            }
        }
    }
    return result;
}

test "test-input" {
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest);
    const part2 = try solvePart2(fileContentTest);

    try std.testing.expectEqual(part1, 1227775554);
    try std.testing.expectEqual(part2, 4174379265);
}
