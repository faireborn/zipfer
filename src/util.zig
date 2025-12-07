const std = @import("std");

pub const k_unicode_error: u21 = 0xFFFD;

pub const StringUtil = struct {
    pub fn oneCharLen(src: []const u8) usize {
        return "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x02\x02\x03\x04"[(src[0] & 0xFF) >> 4];
    }

    pub fn strLen(string: []const u8) usize {
        var length: usize = 0;
        var begin: usize = 0;
        const end = string.len;
        while (begin < end) : (length += 1) {
            begin += oneCharLen(string[begin..]);
        }
        return length;
    }

    pub fn decodeUTF8(utf8: []const u8) struct { u21, usize } {
        const len = utf8.len;

        // If string is null
        if (len == 0) return .{ 0, 1 };

        if (utf8[0] < 0x80) {
            return .{ utf8[0], 1 };
        } else if (len >= 2 and (utf8[0] & 0xE0) == 0xC0) {
            const cp: u21 = ((@as(u21, (utf8[0] & 0x1F)) << 6) | ((utf8[1] & 0x3F)));
            if (isTrailByte(utf8[1]) and cp >= 0x0080 and isValidCodepoint(cp)) {
                return .{ cp, 2 };
            }
        } else if (len >= 3 and (utf8[0] & 0xF0) == 0xE0) {
            const cp: u21 = ((@as(u21, (utf8[0] & 0x0F)) << 12) | (@as(u21, (utf8[1] & 0x3F)) << 6) | ((utf8[2] & 0x3F)));
            if (isTrailByte(utf8[1]) and isTrailByte(utf8[2]) and cp >= 0x0800 and isValidCodepoint(cp)) {
                return .{ cp, 3 };
            }
        } else if (len >= 4 and (utf8[0] & 0xF8) == 0xF0) {
            const cp: u21 = ((@as(u21, (utf8[0] & 0x07)) << 18) | (@as(u21, (utf8[1] & 0x3F)) << 12) | ((utf8[2] & 0x3F) << 6) | ((utf8[3] & 0x3F)));
            if (isTrailByte(utf8[1]) and isTrailByte(utf8[2]) and isTrailByte(utf8[3]) and cp >= 0x10000 and isValidCodepoint(cp)) {
                return .{ cp, 4 };
            }
        }

        // Invalid UTF-8
        return .{ k_unicode_error, 1 };
    }

    // Return (x & 0xC0) == 0x80;
    // Trail bytes are always in [0x80, 0xBF], we can optimize:
    pub fn isTrailByte(x: u8) bool {
        return @as(i8, @bitCast(x)) < -0x40;
    }

    pub fn isValidCodepoint(c: u21) bool {
        return (c < 0xD800) or (c >= 0xE000 and c <= 0x10FFFF);
    }

    pub fn isStructurallyValid(str: []const u8) bool {
        var begin: usize = 0;
        const end = str.len;
        while (begin < end) {
            const res = decodeUTF8(str);
            if (res[0] == k_unicode_error and res[1] != 3) return false;
            if (!isValidCodepoint(res[0])) return false;
            begin += res[1];
        }
        return true;
    }
};

pub const Stats = struct {
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

        // Set deviations to xs and ys
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
};

test "oneCharLen" {
    try std.testing.expectEqual(1, StringUtil.oneCharLen("abc"));
    try std.testing.expectEqual(3, StringUtil.oneCharLen("テスト"));
}

test "strLen" {
    try std.testing.expectEqual(3, StringUtil.strLen("abc"));
    try std.testing.expectEqual(3, StringUtil.strLen("テスト"));
    try std.testing.expectEqual(7, StringUtil.strLen("これはtest"));
}

test "decodeUTF8" {
    // Valid UTF-8
    {
        try std.testing.expectEqual(.{ 0, 1 }, StringUtil.decodeUTF8(""));
        try std.testing.expectEqual(.{ 1, 1 }, StringUtil.decodeUTF8("\x01"));
        try std.testing.expectEqual(.{ 0x7F, 1 }, StringUtil.decodeUTF8("\x7F"));
        try std.testing.expectEqual(.{ 0x80, 2 }, StringUtil.decodeUTF8("\xC2\x80 "));
        try std.testing.expectEqual(.{ 0x7FF, 2 }, StringUtil.decodeUTF8("\xDF\xBF "));
        try std.testing.expectEqual(.{ 0x800, 3 }, StringUtil.decodeUTF8("\xE0\xA0\x80 "));
        try std.testing.expectEqual(.{ 0x10000, 4 }, StringUtil.decodeUTF8("\xF0\x90\x80\x80 "));
    }

    // Invalid UTF-8
    {
        try std.testing.expectEqual(.{ k_unicode_error, 1 }, StringUtil.decodeUTF8("\xF7\xBF\xBF\xBF "));
        try std.testing.expectEqual(.{ k_unicode_error, 1 }, StringUtil.decodeUTF8("\xF8\x88\x80\x80\x80 "));
        try std.testing.expectEqual(.{ k_unicode_error, 1 }, StringUtil.decodeUTF8("\xFC\x84\x80\x80\x80\x80 "));

        const k_invalid_data = [_][]const u8{
            "\xC2", // must be 2byte.
            "\xE0\xE0", // must be 3byte.
            "\xFF", // BOM
            "\xFE", // BOM
        };

        for (k_invalid_data) |bytes| {
            try std.testing.expectEqual(.{ k_unicode_error, 1 }, StringUtil.decodeUTF8(bytes));
            try std.testing.expect(!StringUtil.isStructurallyValid(bytes));
        }

        try std.testing.expectEqual(.{ k_unicode_error, 1 }, StringUtil.decodeUTF8("\xDF\xDF "));
        try std.testing.expectEqual(.{ k_unicode_error, 1 }, StringUtil.decodeUTF8("\xE0\xE0\xE0 "));
        try std.testing.expectEqual(.{ k_unicode_error, 1 }, StringUtil.decodeUTF8("\xF0\xF0\xF0\xFF "));
    }
}

test "mean" {
    {
        const xs = &[_]f64{ 0, 0, 1, 0 };
        const expect: f64 = 0.25;
        const res = Stats.mean(f64, xs);
        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]f32{ 43.43, 213, 51, -328.18, -318.329 };
        const expect: f32 = -67.8158;
        const res = Stats.mean(f32, xs);
        try std.testing.expectEqual(expect, res);
    }
    {
        const xs = &[_]f64{ 21.00, -213.25, -2199.01, 1203.2, 0.32 };
        const expect: f64 = -237.54800000000006;
        const res = Stats.mean(f64, xs);
        try std.testing.expectEqual(expect, res);
    }
}

test "cov" {
    const xs = &[_]f64{ 0, 1, 2 };
    const ys = &[_]f64{ 2, 1, 0 };
    const cov_result = try Stats.cov(f64, xs, ys);

    try std.testing.expectEqual(1.0, cov_result.xx);
    try std.testing.expectEqual(-1.0, cov_result.xy);
    try std.testing.expectEqual(1.0, cov_result.yy);
}
