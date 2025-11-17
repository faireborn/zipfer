const std = @import("std");

pub fn mean(comptime T: type, comptime ResultT: type, xs: []const T) ResultT {
    var sum: ResultT = 0;
    for (xs) |x| {
        switch (@typeInfo(T)) {
            .int => sum += @floatFromInt(x),
            .float => sum += @floatCast(x),
            else => @compileError("Type Error"),
        }
    }
    return sum / @as(ResultT, @floatFromInt(xs.len));
}

test "mean" {
    {
        const xs = &[_]usize{ 0, 0, 1, 0 };
        const expect: f64 = 0.25;

        const res = mean(usize, f64, xs);

        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]i32{ -1, 0, 1, 0 };
        const expect: f64 = 0;

        const res = mean(i32, f64, xs);

        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]i64{ 100, -30, 9393, 1293, -293193 };
        const expect: f64 = -56487.4;

        const res = mean(i64, f64, xs);

        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]f32{ 43.43, 213, 51, -328.18, -318.329 };
        const expect: f32 = -67.8158;

        const res = mean(f32, f32, xs);

        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]f64{ 21.00, -213.25, -2199.01, 1203.2, 0.32 };
        const expect: f64 = -237.54800000000006;

        const res = mean(f64, f64, xs);

        try std.testing.expectEqual(expect, res);
    }
}
