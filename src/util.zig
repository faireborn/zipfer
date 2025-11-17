const std = @import("std");

pub fn mean(comptime T: type, xs: []const T) T {
    var sum: T = 0;
    for (xs) |x| {
        sum += x;
    }
    return sum / @as(T, @floatFromInt(xs.len));
}

test "mean" {
    {
        const xs = &[_]f64{ 0, 0, 1, 0 };
        const expect: f64 = 0.25;

        const res = mean(f64, xs);

        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]f32{ 43.43, 213, 51, -328.18, -318.329 };
        const expect: f32 = -67.8158;

        const res = mean(f32, xs);

        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]f64{ 21.00, -213.25, -2199.01, 1203.2, 0.32 };
        const expect: f64 = -237.54800000000006;

        const res = mean(f64, xs);

        try std.testing.expectEqual(expect, res);
    }
}
