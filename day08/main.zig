const std = @import("std");

pub fn main() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();
    var allocator = arenaAllocator.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator, 1000);
    const part1Time = timer.lap() / std.time.ns_per_ms;
    const part2 = try solvePart2(fileContent, &allocator);
    const part2Time = timer.lap() / std.time.ns_per_ms;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}ms\nTime2: {d}ms\n", .{ part1, part2, part1Time, part2Time });
}

const iPair = [3]isize;
const Pair = [3]usize;

fn cmpPoint(context: void, a: Pair, b: Pair) bool {
    _ = context;
    return (a[0] < b[0]);
}

fn distance(coordLeft: iPair, coordRight: iPair) usize {
    const dx = coordLeft[0] - coordRight[0];
    const dy = coordLeft[1] - coordRight[1];
    const dz = coordLeft[2] - coordRight[2];

    return @intCast((dx * dx) + (dy * dy) + (dz * dz));
}

inline fn find(groups: []usize, x: usize) usize {
    var innerX = x;

    while (groups[innerX] != innerX) {
        innerX = groups[innerX];
    }
    const root = innerX;

    innerX = x;
    while (groups[x] != innerX) {
        const parent = groups[innerX];
        groups[innerX] = root;
        innerX = parent;
    }

    return root;
}

fn mix(groups: []usize, x: usize, y: usize) void {
    const root_x = find(groups, x);
    const root_y = find(groups, y);
    groups[root_x] = root_y;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator, testRuns: usize) !usize {
    var result: usize = 1;
    var coords = try std.ArrayList(iPair).initCapacity(allocator.*, 1000);
    defer coords.deinit(allocator.*);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var rangeString = std.mem.tokenizeScalar(u8, line, ',');
        const xString = rangeString.next().?;
        const yString = rangeString.next().?;
        const zString = rangeString.next().?;

        const x = try std.fmt.parseInt(isize, xString, 10);
        const y = try std.fmt.parseInt(isize, yString, 10);
        const z = try std.fmt.parseInt(isize, zString, 10);

        coords.appendAssumeCapacity(iPair{ x, y, z });
    }

    const coordCount = coords.items.len;

    var distList = try std.ArrayList(Pair).initCapacity(allocator.*, 500_000);
    defer distList.deinit(allocator.*);

    for (coords.items[0..], 0..) |left, xIndex| {
        for (coords.items[0..], 0..) |right, yIndex| {
            if (xIndex > yIndex) {
                const dist = distance(left, right);
                distList.appendAssumeCapacity(Pair{ dist, xIndex, yIndex });
            }
        }
    }

    std.mem.sortUnstable(Pair, distList.items[0..], {}, cmpPoint);

    var groups = try std.ArrayList(usize).initCapacity(allocator.*, coordCount);
    for (0..coordCount) |coordIndex| {
        groups.appendAssumeCapacity(coordIndex);
    }
    defer groups.deinit(allocator.*);

    var groupCount = try std.ArrayList(usize).initCapacity(allocator.*, coordCount);
    for (0..coordCount) |_| {
        groupCount.appendAssumeCapacity(0);
    }
    defer groupCount.deinit(allocator.*);
    for (distList.items, 0..) |item, itemIndex| {
        if (itemIndex == testRuns) {
            for (0..coordCount) |cIndex| {
                groupCount.items[find(groups.items, cIndex)] += 1;
            }
            break;
        }

        const xItem = item[1];
        const yItem = item[2];
        mix(groups.items, xItem, yItem);
    }

    std.mem.sortUnstable(usize, groupCount.items, {}, std.sort.asc(usize));

    for (0..3) |_| {
        result *= groupCount.pop().?;
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 1;
    var coords = try std.ArrayList(iPair).initCapacity(allocator.*, 1000);
    defer coords.deinit(allocator.*);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var rangeString = std.mem.tokenizeScalar(u8, line, ',');
        const xString = rangeString.next().?;
        const yString = rangeString.next().?;
        const zString = rangeString.next().?;

        const x = try std.fmt.parseInt(isize, xString, 10);
        const y = try std.fmt.parseInt(isize, yString, 10);
        const z = try std.fmt.parseInt(isize, zString, 10);

        coords.appendAssumeCapacity(iPair{ x, y, z });
    }

    const coordCount = coords.items.len;

    var distList = try std.ArrayList(Pair).initCapacity(allocator.*, 500_000);
    defer distList.deinit(allocator.*);

    for (coords.items[0..], 0..) |left, xIndex| {
        for (coords.items[0..], 0..) |right, yIndex| {
            if (xIndex > yIndex) {
                const dist = distance(left, right);
                distList.appendAssumeCapacity(Pair{ dist, xIndex, yIndex });
            }
        }
    }

    std.mem.sortUnstable(Pair, distList.items[0..], {}, cmpPoint);

    var groups = try std.ArrayList(usize).initCapacity(allocator.*, coordCount);
    for (0..coordCount) |coordIndex| {
        groups.appendAssumeCapacity(coordIndex);
    }
    defer groups.deinit(allocator.*);

    var groupCount = try std.ArrayList(usize).initCapacity(allocator.*, coordCount);
    for (0..coordCount) |_| {
        groupCount.appendAssumeCapacity(0);
    }
    defer groupCount.deinit(allocator.*);
    var connections: usize = 0;
    for (distList.items) |item| {
        const xItem = item[1];
        const yItem = item[2];
        if (find(groups.items, xItem) != find(groups.items, yItem)) {
            connections += 1;
            if (connections == coordCount - 1) {
                result = @intCast(coords.items[xItem][0] * coords.items[yItem][0]);
                break;
            }
            mix(groups.items, xItem, yItem);
        }
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator, 10);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 40);
    try std.testing.expectEqual(part2, 25272);
}
