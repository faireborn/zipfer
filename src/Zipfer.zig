const Zipfer = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

vocab: ArrayList([]const u8),
token_freq: std.StringHashMap(usize),
allocator: Allocator,

pub fn init(allocator: Allocator) Zipfer {
    return .{
        .vocab = .empty,
        .token_freq = std.StringHashMap(usize).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Zipfer) void {
    for (self.vocab.items) |token| {
        self.allocator.free(token);
    }
    self.vocab.deinit(self.allocator);
    self.token_freq.deinit();
}

pub fn loadVocab(self: *Zipfer, file_name: []const u8) !void {
    const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    defer file.close();

    var file_buffer: [1024]u8 = undefined;
    var reader = file.reader(&file_buffer);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        // Get only first column token
        var it = std.mem.splitAny(u8, line, "\t\n \r");
        if (it.next()) |token| {
            if (token.len == 0) continue;

            // Insert a token into the vocab
            const new_token = try Allocator.dupe(self.allocator, u8, token);
            try self.vocab.append(self.allocator, new_token);
        }
    }
}

test "init deinit" {
    var zipfer = Zipfer.init(std.testing.allocator);
    defer zipfer.deinit();
}

test "load vocab" {
    var zipfer = Zipfer.init(std.testing.allocator);
    defer zipfer.deinit();

    try zipfer.loadVocab("../test/test.vocab");

    const vocab = zipfer.vocab.items;
    try std.testing.expect(std.mem.eql(u8, "hello,", vocab[0]));
    try std.testing.expect(std.mem.eql(u8, "world!", vocab[1]));
    try std.testing.expect(std.mem.eql(u8, "🍣", vocab[2]));
}
