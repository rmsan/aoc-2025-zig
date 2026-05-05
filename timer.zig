const std = @import("std");

pub const Timer = struct {
    last: std.Io.Timestamp,

    pub fn start() !Timer {
        return .{ .last = now() };
    }

    pub fn lap(self: *Timer) u64 {
        const current = now();
        defer self.last = current;
        return @intCast(self.last.durationTo(current).nanoseconds);
    }

    fn now() std.Io.Timestamp {
        return std.Io.Clock.awake.now(std.Options.debug_io);
    }
};
