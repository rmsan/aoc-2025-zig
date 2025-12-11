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

fn getGraph(input: []const u8, allocator: *std.mem.Allocator) !std.StringHashMap(std.ArrayList([]const u8)) {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var graph = std.StringHashMap(std.ArrayList([]const u8)).init(allocator.*);
    while (lines.next()) |line| {
        var segments = std.mem.tokenizeScalar(u8, line, ':');
        const device = segments.next().?;
        var connectionString = std.mem.tokenizeScalar(u8, segments.next().?, ' ');

        var connections: std.ArrayList([]const u8) = .empty;
        while (connectionString.next()) |connection| {
            try connections.append(allocator.*, connection);
        }
        try graph.put(device, connections);
    }
    return graph;
}

fn count(src: []const u8, dest: []const u8, graph: *std.StringHashMap(std.ArrayList([]const u8)), cache: *std.StringHashMap(usize)) !usize {
    if (std.mem.eql(u8, src, dest)) {
        return 1;
    }

    if (cache.get(src)) |cached| {
        return cached;
    }

    var total: usize = 0;
    if (graph.get(src)) |children| {
        for (children.items) |child| {
            total += try count(child, dest, graph, cache);
        }
    }

    try cache.put(src, total);
    return total;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var graph = try getGraph(input, allocator);
    defer {
        var iter = graph.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.*.deinit(allocator.*);
        }
        graph.deinit();
    }

    var cache = std.StringHashMap(usize).init(allocator.*);
    defer cache.deinit();
    return try count("you", "out", &graph, &cache);
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var graph = try getGraph(input, allocator);
    defer {
        var iter = graph.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.*.deinit(allocator.*);
        }
        graph.deinit();
    }

    var cache = std.StringHashMap(usize).init(allocator.*);
    defer cache.deinit();

    const firstPath: [4][]const u8 = .{ "svr", "dac", "fft", "out" };
    const secondPath: [4][]const u8 = .{ "svr", "fft", "dac", "out" };
    var count_first: usize = 1;
    var count_second: usize = 1;
    for (firstPath[0..3], 0..) |src, i| {
        const dest = firstPath[i + 1];
        const cnt = try count(src, dest, &graph, &cache);
        cache.clearRetainingCapacity();
        count_first *= cnt;
    }
    for (secondPath[0..3], 0..) |src, i| {
        const dest = secondPath[i + 1];
        const cnt = try count(src, dest, &graph, &cache);
        cache.clearRetainingCapacity();
        count_second *= cnt;
    }

    return count_first + count_second;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTestPart1 = @embedFile("test1.txt");
    const fileContentTestPart2 = @embedFile("test2.txt");

    const part1 = try solvePart1(fileContentTestPart1, &allocator);
    const part2 = try solvePart2(fileContentTestPart2, &allocator);

    try std.testing.expectEqual(part1, 5);
    try std.testing.expectEqual(part2, 2);
}
