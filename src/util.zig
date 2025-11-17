const std = @import("std");

pub fn mean(comptime T: type, comptime ResultT: type, xs: []const T) ResultT {
    var sum: T = 0;
    for (xs) |x| {
        sum += x;
    }

    switch (@typeInfo(T)) {
        .int => {
            return @as(ResultT, @floatFromInt(sum)) / @as(ResultT, @floatFromInt(xs.len));
        },
        .float => {
            return sum / @as(ResultT, @floatFromInt(xs.len));
        },
        else => {
            @compileError("Type Error");
        },
    }
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
        const xs = &[_]f64{ 0, 0, 0, 0 };
        const expect: f64 = 0;

        const res = mean(f64, f64, xs);

        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]f32{ 0, 0, 0, 0 };
        const expect: f64 = 0;

        const res = mean(f32, f64, xs);

        try std.testing.expectEqual(expect, res);
    }
}
