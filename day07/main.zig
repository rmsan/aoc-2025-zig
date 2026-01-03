const std = @import("std");

const builtin = @import("builtin");

const has_avx2 = builtin.cpu.arch == .x86_64 and std.Target.x86.featureSetHas(builtin.cpu.features, .avx2);
const has_sse42 = builtin.cpu.arch == .x86_64 and std.Target.x86.featureSetHas(builtin.cpu.features, .sse4_2);
const has_neon = builtin.cpu.arch == .aarch64;

const Vec = if (has_avx2)
    @Vector(32, u8)
else if (has_sse42 or has_neon)
    @Vector(16, u8)
else
    @Vector(8, u8);

const vec_len = @typeInfo(Vec).vector.len;

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part1Vec = try solveVec(Part.Part1, fileContent);
    const part1VecTime = timer.lap() / std.time.ns_per_us;
    std.debug.assert(part1 == part1Vec);
    const part2 = try solvePart2(fileContent);
    const part2Time = timer.lap() / std.time.ns_per_us;
    const part2Vec = try solveVec(Part.Part2, fileContent);
    const part2VecTime = timer.lap() / std.time.ns_per_us;
    std.debug.assert(part2 == part2Vec);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\nTime1(Vec): {d}us\nTime2(Vec): {d}us\n", .{ part1, part2, part1Time, part2Time, part1VecTime, part2VecTime });
}

const Part = enum { Part1, Part2 };

fn solve(comptime part: Part, input: []const u8) !usize {
    var result: usize = 0;
    var splits: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var beams: [142]usize = std.mem.zeroes([142]usize);

    const firstLineOpt = lines.next();
    std.debug.assert(firstLineOpt != null);
    const firstLine = firstLineOpt.?;
    const startPosOpt = std.mem.indexOfScalar(u8, firstLine, 'S');
    std.debug.assert(startPosOpt != null);
    const startPos = startPosOpt.?;
    beams[startPos] = 1;

    while (lines.next()) |line| {
        std.debug.assert(line.len <= beams.len);
        for (0..line.len) |index| {
            if (line[index] == '^' and beams[index] > 0) {
                std.debug.assert(index > 0);
                std.debug.assert(index + 1 < beams.len);
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

fn solveVec(comptime part: Part, input: []const u8) !usize {
    var splits: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var beams: @Vector(142, usize) = @splat(0);

    const firstLineOpt = lines.next();
    std.debug.assert(firstLineOpt != null);
    const firstLine = firstLineOpt.?;
    const startPosOpt = std.mem.indexOfScalar(u8, firstLine, 'S');
    std.debug.assert(startPosOpt != null);
    const startPos = startPosOpt.?;
    beams[startPos] = 1;

    while (lines.next()) |line| {
        var i: usize = 0;
        const caret: Vec = @splat('^');

        // Vectorized processing
        while (i + vec_len <= line.len) {
            const chunk: Vec = line[i..][0..vec_len].*;
            const is_caret = chunk == caret;
            const mask = @as(std.meta.Int(.unsigned, vec_len), @bitCast(is_caret));
            if (mask != 0) {
                var bit_pos: usize = 0;
                var remaining = mask;
                while (remaining != 0) {
                    bit_pos = @ctz(remaining);
                    const pos = i + bit_pos;

                    if (beams[pos] > 0) {
                        splits += 1;
                        beams[pos - 1] += beams[pos];
                        beams[pos + 1] += beams[pos];
                        beams[pos] = 0;
                    }

                    remaining &= remaining - 1;
                }
            }

            i += vec_len;
        }

        // Handle remaining elements (scalar fallback)
        while (i < line.len) : (i += 1) {
            const data = line[i];
            if (data == '^' and beams[i] > 0) {
                splits += 1;
                beams[i - 1] += beams[i];
                beams[i + 1] += beams[i];
                beams[i] = 0;
            }
        }
    }

    if (part == .Part1) {
        return splits;
    }

    const beamsSum = @reduce(.Add, beams);

    return beamsSum;
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

    const part1Vec = try solveVec(Part.Part1, fileContentTest);
    const part2Vec = try solveVec(Part.Part2, fileContentTest);

    try std.testing.expectEqual(part1, 21);
    try std.testing.expectEqual(part1Vec, part1);
    try std.testing.expectEqual(part2, 40);
    try std.testing.expectEqual(part2Vec, part2);
}
