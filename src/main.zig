const std = @import("std");
const Zipfer = @import("zipfer").Zipfer;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var zipfer = Zipfer.init(allocator);
    defer zipfer.deinit();

    try zipfer.loadVocab("./test/test.vocab");

    for (zipfer.vocab.items) |token| {
        std.debug.print("{s}", .{token});
    }
}
