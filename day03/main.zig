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

const Part = enum { Part1, Part2 };

fn solve(comptime part: Part, input: []const u8, allocator: std.mem.Allocator) !usize {
    const maxDigits: usize = switch (part) {
        .Part1 => 2,
        .Part2 => 12,
    };
    var result: usize = 0;
    var buf = try std.ArrayList(u8).initCapacity(allocator, maxDigits);
    defer buf.deinit(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const lineLength = line.len;
        var currentIndex: usize = 0;
        var digits: usize = maxDigits;
        std.debug.assert(lineLength >= digits);
        while (digits > 0) : (digits -= 1) {
            var largest: u8 = 0;
            var largestIndex: usize = 0;
            var index: usize = currentIndex;
            while (index <= (lineLength - digits)) : (index += 1) {
                const toCheck = line[index];
                if (toCheck > largest) {
                    largest = toCheck;
                    largestIndex = index;
                }
            }
            currentIndex = largestIndex + 1;
            try buf.append(allocator, line[currentIndex - 1]);
        }
        std.debug.assert(buf.items.len > 0);
        result += try std.fmt.parseInt(usize, buf.items, 10);
        buf.clearRetainingCapacity();
    }
    return result;
}

fn solvePart1(input: []const u8, allocator: std.mem.Allocator) !usize {
    return solve(Part.Part1, input, allocator);
}

fn solvePart2(input: []const u8, allocator: std.mem.Allocator) !usize {
    return solve(Part.Part2, input, allocator);
}

test "test-input" {
    const allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, allocator);
    const part2 = try solvePart2(fileContentTest, allocator);

    try std.testing.expectEqual(part1, 357);
    try std.testing.expectEqual(part2, 3121910778619);
}
