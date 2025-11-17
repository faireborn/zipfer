pub const Zipfer = ZipferImpl(f64);
pub const ZipferImpl = @import("zipfer.zig").ZipferImpl;

const std = @import("std");

test {
    _ = Zipfer;
}
