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

fn solvePart1(input: []const u8, allocator: std.mem.Allocator) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var numbers = try std.ArrayList(usize).initCapacity(allocator, 4000);
    var lineCount: usize = 0;
    defer numbers.deinit(allocator);
    while (lines.next()) |line| {
        if (lines.peek() == null) {
            var ops = std.mem.tokenizeScalar(u8, line, ' ');
            var index: usize = 0;
            const numberCount = numbers.items.len;
            std.debug.assert(lineCount > 0);
            const step = numberCount / lineCount;
            while (ops.next()) |op| {
                std.debug.assert(op.len > 0);
                const opChar = op[0];
                var innerResult: usize = 1;
                switch (opChar) {
                    '*' => {
                        var innerIndex: usize = index;
                        for (0..lineCount) |_| {
                            const num = numbers.items[innerIndex];
                            innerResult *= num;
                            innerIndex += step;
                        }
                    },
                    '+' => {
                        innerResult = 0;
                        var innerIndex: usize = index;
                        for (0..lineCount) |_| {
                            const num = numbers.items[innerIndex];
                            innerResult += num;
                            innerIndex += step;
                        }
                    },
                    else => unreachable,
                }

                result += innerResult;
                index += 1;
            }
            break;
        }
        lineCount += 1;
        var numbersStrings = std.mem.tokenizeScalar(u8, line, ' ');
        while (numbersStrings.next()) |numberString| {
            std.debug.assert(numberString.len > 0);
            const num = try std.fmt.parseInt(usize, numberString, 10);
            numbers.appendAssumeCapacity(num);
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: std.mem.Allocator) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var lineList = try std.ArrayList([]const u8).initCapacity(allocator, 5);
    defer lineList.deinit(allocator);
    while (lines.next()) |lineToAdd| {
        if (lines.peek() == null) {
            var found = true;
            var temp: usize = 0;
            var feedIndex: usize = 0;
            const maxFeed: usize = lineList.items[0].len;
            var numbers = try std.ArrayList([]usize).initCapacity(allocator, 4000);
            defer {
                for (numbers.items) |item| {
                    allocator.free(item);
                }
                numbers.deinit(allocator);
            }

            while (feedIndex < maxFeed) {
                var numberCol = try std.ArrayList(usize).initCapacity(allocator, 4);

                while (found and feedIndex < maxFeed) {
                    found = false;
                    temp = 0;

                    for (lineList.items) |line| {
                        const char = line[feedIndex];

                        if (char == ' ') {
                            continue;
                        }
                        found = true;

                        temp *= 10;
                        temp += try std.fmt.charToDigit(char, 10);
                    }

                    if (temp != 0) {
                        numberCol.appendAssumeCapacity(temp);
                    }
                    feedIndex += 1;
                }

                found = true;
                const numberCols = try numberCol.toOwnedSlice(allocator);
                numbers.appendAssumeCapacity(numberCols);
            }

            var ops = std.mem.tokenizeScalar(u8, lineToAdd, ' ');
            var index: usize = 0;
            while (ops.next()) |op| {
                std.debug.assert(op.len > 0);
                const opChar = op[0];
                var innerResult: usize = 1;
                const opNumbers = numbers.items[index];
                switch (opChar) {
                    '*' => {
                        for (opNumbers) |num| {
                            innerResult *= num;
                        }
                    },
                    '+' => {
                        innerResult = 0;
                        for (opNumbers) |num| {
                            innerResult += num;
                        }
                    },
                    else => unreachable,
                }

                result += innerResult;
                index += 1;
            }
        }
        lineList.appendAssumeCapacity(lineToAdd);
    }

    return result;
}

test "test-input" {
    const allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, allocator);
    const part2 = try solvePart2(fileContentTest, allocator);

    try std.testing.expectEqual(part1, 4277556);
    try std.testing.expectEqual(part2, 3263827);
}
