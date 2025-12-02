const std = @import("std");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part1Time = timer.lap() / std.time.ns_per_ms;
    const part2 = try solvePart2(fileContent);
    const part2Time = timer.lap() / std.time.ns_per_ms;
    const part2Alt = try solvePart2Alt(fileContent);
    std.debug.assert(part2 == part2Alt);
    const part2AltTime = timer.lap() / std.time.ns_per_ms;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1\t\t: {d}ms\nTime2\t\t: {d}ms\n", .{ part1, part2, part1Time, part2Time });
    std.debug.print("Time2 (Alt)\t: {d}ms\n", .{part2AltTime});
}

fn digits(number: usize) usize {
    // example: number = 1010
    // log_10(1010) + 1
    // 3 + 1 = 4
    return std.math.log10(number) + 1;
}

fn slice(number: usize, start: usize, end: usize, digitCount: usize) usize {
    // example: number = 101010, start = 0, end = 3, digitCount = 6
    // powLeft = 10^3 = 1000
    // powRight = 10^3 = 1000
    // 101010 / 1000 = 101 % 1000 = 101
    const left = digitCount - end;
    const right = end - start;
    const powLeft = std.math.pow(usize, 10, left);
    const powRight = std.math.pow(usize, 10, right);
    return @mod(@divFloor(number, powLeft), powRight);
}

fn isInvalid(number: usize) bool {
    const digitCount = digits(number);
    if (digitCount % 2 != 0) {
        return false;
    }
    const halfSize = @divFloor(digitCount, 2);
    return slice(number, 0, halfSize, digitCount) == slice(number, halfSize, digitCount, digitCount);
}

// use math to slice number into parts
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
            if (isInvalid(toCheck)) {
                result += toCheck;
            }
        }
    }
    return result;
}

// use math to slice number into parts (slower alternative)
fn solvePart2Alt(input: []const u8) !usize {
    var result: usize = 0;
    var sequences = std.mem.tokenizeScalar(u8, input, ',');
    while (sequences.next()) |sequence| {
        var numbers = std.mem.tokenizeScalar(u8, sequence, '-');
        const firstNumberString = numbers.next().?;
        const secondNumberString = numbers.next().?;
        const firstNumber = try std.fmt.parseInt(usize, firstNumberString, 10);
        const secondNumber = try std.fmt.parseInt(usize, secondNumberString, 10);

        for (firstNumber..secondNumber + 1) |toCheck| {
            const digitCount = digits(toCheck);

            // max length is 10 (only need to check half of the digits)
            inline for (1..6) |digitLength| {
                if (digitCount % digitLength == 0) {
                    const digitsToCount = @divFloor(digitCount, digitLength);
                    if (digitsToCount > 1) {
                        const left = slice(toCheck, 0, digitLength, digitCount);
                        var allOk = true;
                        for (1..digitsToCount) |index| {
                            const right = slice(toCheck, index * digitLength, (index + 1) * digitLength, digitCount);
                            if (left != right) {
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
        }
    }
    return result;
}

// use string representation to slice number into parts
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
    const part2Alt = try solvePart2Alt(fileContentTest);

    try std.testing.expectEqual(part1, 1227775554);
    try std.testing.expectEqual(part2, 4174379265);
    try std.testing.expectEqual(part2, part2Alt);
}
