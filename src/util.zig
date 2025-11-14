const Zipf = @import("type.zig").Zipf;

const std = @import("std");

pub fn sortZipf(zipf: []Zipf) void {
    std.mem.sort(Zipf, zipf, {}, struct {
        fn lessThan(_: void, lhs: Zipf, rhs: Zipf) bool {
            if (lhs.freq > rhs.freq) return true;
            if (lhs.freq < rhs.freq) return false;
            return std.mem.order(u8, lhs.token, rhs.token) == .lt;
        }
    }.lessThan);
}
