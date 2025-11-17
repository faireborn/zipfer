const std = @import("std");
const mean = @import("util.zig").mean;

pub fn model(comptime T: type, xs: []const T, ys: []const T) !T {
    const tiny: T = 1.0e-20;

    if (xs.len == 0 or ys.len == 0) {
        std.log.err("Inputs must not be empty.", .{});
        return error.ValueError;
    }

    if (xs.len != ys.len) {
        std.log.err("The length of x and y must be equal.", .{});
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

    return tiny;
}

test "model" {
    _ = std.simd.suggestVectorLength(usize);
    _ = try model(f64, &[_]f64{ 0.0, 0.1 }, &[_]f64{ 0.0, 0.0 });
}

test {
    _ = mean;
}
