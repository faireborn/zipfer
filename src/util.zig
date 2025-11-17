const std = @import("std");

pub fn Cov(comptime T: type) type {
    return struct {
        xx: T,
        xy: T,
        yy: T,
    };
}

pub fn mean(comptime T: type, xs: []const T) T {
    var sum: T = 0;
    for (xs) |x| {
        sum += x;
    }
    return sum / @as(T, @floatFromInt(xs.len));
}

pub fn cov(comptime T: type, xs: []const T, ys: []const T) !Cov(T) {
    if (xs.len == 0 or ys.len == 0) {
        std.log.err("Inputs must not be empty.", .{});
        return error.ValueError;
    }

    if (xs.len != ys.len) {
        std.log.err("The length of x and y must be equal.", .{});
        return error.ValueError;
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const length = xs.len;
    const degrees_of_freedom = length - 1;

    if (degrees_of_freedom <= 0) {
        std.log.err("Degrees of freedom must be more than 0.", .{});
        return error.ValueError;
    }

    const x_mean = mean(T, xs);
    const y_mean = mean(T, ys);

    var x_deviations = try allocator.alloc(T, length);
    var y_deviations = try allocator.alloc(T, length);

    for (0..length) |i| {
        x_deviations[i] = xs[i] - x_mean;
        y_deviations[i] = ys[i] - y_mean;
    }

    var xx: T = undefined;
    var xy: T = undefined;
    var yy: T = undefined;

    for (0..length) |i| {
        xx += x_deviations[i] * x_deviations[i];
        xy += x_deviations[i] * y_deviations[i];
        yy += y_deviations[i] * y_deviations[i];
    }

    return .{
        .xx = xx / @as(T, @floatFromInt(degrees_of_freedom)),
        .xy = xy / @as(T, @floatFromInt(degrees_of_freedom)),
        .yy = yy / @as(T, @floatFromInt(degrees_of_freedom)),
    };
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

test "cov" {
    const xs = &[_]f64{ 0, 1, 2 };
    const ys = &[_]f64{ 2, 1, 0 };
    const cov_result = try cov(f64, xs, ys);

    try std.testing.expectEqual(1.0, cov_result.xx);
    try std.testing.expectEqual(-1.0, cov_result.xy);
    try std.testing.expectEqual(1.0, cov_result.yy);
}
