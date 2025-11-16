const std = @import("std");

pub fn r2(comptime T: type) void {
    _ = T;
}

test "r2" {
    std.debug.print("hello from r2!", .{});
}
