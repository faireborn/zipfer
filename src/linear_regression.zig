const std = @import("std");
const util = @import("util.zig");

pub fn Result(comptime T: type) type {
    return struct {
        r: ?T,
        slope: T,
        intercept: T,
    };
}

pub fn model(comptime T: type, xs: []const T, ys: []const T) !Result(T) {
    if (xs.len == 0 or ys.len == 0) {
        std.log.err("Inputs must not be empty.", .{});
        return error.ValueError;
    }

    if (xs.len != ys.len) {
        std.log.err("The length of x and y must be equal.", .{});
        return error.ValueError;
    }

    const length = xs.len;

    if (length > 1) {
        const x = xs[0];
        for (1..xs.len) |i| {
            if (xs[i] != x) {
                break;
            }

            if (i == xs.len - 1) {
                std.log.err(
                    \\Cannot calculate a linear regression 
                    \\if all x values are identical.
                , .{});
                return error.ValueError;
            }
        }
    }

    const x_mean = util.mean(T, xs);
    const y_mean = util.mean(T, ys);
    const cov = try util.cov(T, xs, ys);

    var result: Result(T) = .{
        .r = undefined,
        .slope = undefined,
        .intercept = undefined,
    };

    // r = cov.xy / sqrt( cov.xx * cov.yy )
    if (cov.xx == 0.0 or cov.yy == 0.0) {
        result.r = if (cov.xy == 0.0) null else 0.0;
    } else {
        var r = cov.xy / std.math.sqrt(cov.xx * cov.yy);
        if (r > 1.0) r = 1.0 else if (r < -1.0) r = -1.0;
        result.r = r;
    }

    result.slope = cov.xy / cov.xx;
    result.intercept = y_mean - result.slope * x_mean;

    return result;
}

test "model" {
    {
        const xs = &[_]f64{ 0.95700886, 0.48545541, 0.9464698, 0.51636422, 0.96109422, 0.23767705, 0.07653071, 0.10844977, 0.15895693, 0.61648174 };
        const ys = &[_]f64{ 1.88858533, 0.99632693, 1.84770655, 0.84024667, 2.28943859, 0.45595932, 0.82434291, 0.3747796, 0.77799234, 1.12524599 };

        const result = try model(f64, xs, ys);

        try std.testing.expectApproxEqRel(0.9201534422154125, result.r.?, 1e-5);
        try std.testing.expectApproxEqRel(1.6660444629562734, result.slope, 1e-5);
        try std.testing.expectApproxEqRel(0.2982960852548444, result.intercept, 1e-5);
    }
    {
        const xs = &[_]f32{ 0.14704058, 0.04727454, 0.59597035, 0.60417735, 0.31970672, 0.74119709, 0.72439552, 0.36065246, 0.69833356, 0.71171026 };
        const ys = &[_]f32{ 0.61630415, 0.42215979, 1.45984647, 1.02782079, 0.90002424, 1.59407244, 1.74947297, 0.59424647, 1.37739303, 1.64583539 };

        const result = try model(f32, xs, ys);

        try std.testing.expectApproxEqRel(0.9279293737226924, result.r.?, 1e-5);
        try std.testing.expectApproxEqRel(1.7653229021583134, result.slope, 1e-5);
        try std.testing.expectApproxEqRel(0.2648018073970857, result.intercept, 1e-5);
    }
}

test {
    _ = util;
}
