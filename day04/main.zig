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
    const part2Time = timer.lap() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\n", .{ part1, part2, part1Time, part2Time });
}

fn getGrid(input: []const u8, allocator: *std.mem.Allocator) ![][]u8 {
    var grid = try std.ArrayList([]u8).initCapacity(allocator.*, 140);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const mutLine = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, mutLine, line);
        grid.appendAssumeCapacity(mutLine);
    }
    return grid.toOwnedSlice(allocator.*);
}

fn getNeighbours(x: isize, y: isize, gridLength: isize, allocator: *std.mem.Allocator) !std.ArrayList([2]usize) {
    var neighbours = try std.ArrayList([2]usize).initCapacity(allocator.*, 8);

    const directions: [8][2]isize = [_][2]isize{
        [_]isize{ -1, -1 },
        [_]isize{ -1, 0 },
        [_]isize{ -1, 1 },
        [_]isize{ 0, -1 },
        [_]isize{ 0, 1 },
        [_]isize{ 1, -1 },
        [_]isize{ 1, 0 },
        [_]isize{ 1, 1 },
    };

    for (directions) |dir| {
        const nx = x + dir[0];
        const ny = y + dir[1];

        if (nx < 0 or ny < 0 or nx >= gridLength or ny >= gridLength) {
            continue;
        }

        const nxCoord: usize = @intCast(nx);
        const nyCoord: usize = @intCast(ny);
        neighbours.appendAssumeCapacity([2]usize{ nxCoord, nyCoord });
    }

    return neighbours;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const grid = try getGrid(input, allocator);
    defer {
        for (grid) |item| {
            allocator.free(item);
        }
        allocator.free(grid);
    }

    const gridLength = grid.len;

    for (0..gridLength) |x| {
        for (0..gridLength) |y| {
            var found: usize = 0;
            const cell = grid[x][y];
            if (cell == '@') {
                const ix: isize = @intCast(x);
                const iy: isize = @intCast(y);
                var neighbours = try getNeighbours(ix, iy, @intCast(gridLength), allocator);

                for (neighbours.items) |coord| {
                    const nx = coord[0];
                    const ny = coord[1];
                    const neighbourCell = grid[nx][ny];
                    if (neighbourCell == '@') {
                        found += 1;
                    }
                }

                if (found < 4) {
                    result += 1;
                }

                neighbours.deinit(allocator.*);
            }
        }
    }
    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const grid = try getGrid(input, allocator);
    defer {
        for (grid) |item| {
            allocator.free(item);
        }
        allocator.free(grid);
    }

    const gridLength = grid.len;

    var removable = try std.ArrayList([2]usize).initCapacity(allocator.*, 3000);
    defer removable.deinit(allocator.*);
    while (true) {
        for (0..gridLength) |x| {
            for (0..gridLength) |y| {
                var found: usize = 0;
                const cell = grid[x][y];
                if (cell == '@') {
                    const ix: isize = @intCast(x);
                    const iy: isize = @intCast(y);
                    var neighbours = try getNeighbours(ix, iy, @intCast(gridLength), allocator);

                    for (neighbours.items) |coord| {
                        const nx = coord[0];
                        const ny = coord[1];
                        const neighbourCell = grid[nx][ny];
                        if (neighbourCell == '@') {
                            found += 1;
                        }
                    }

                    if (found < 4) {
                        result += 1;
                        removable.appendAssumeCapacity([2]usize{ x, y });
                    }

                    neighbours.deinit(allocator.*);
                }
            }
        }
        if (removable.items.len == 0) {
            break;
        }
        for (removable.items) |coord| {
            const rx = coord[0];
            const ry = coord[1];
            grid[rx][ry] = '.';
        }
        removable.clearRetainingCapacity();
    }
    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 13);
    try std.testing.expectEqual(part2, 43);
}
