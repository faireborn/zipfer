const Zipfer = @This();

const Zipf = @import("type.zig").Zipf;
const util = @import("util.zig");

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ArenaAllocator = std.heap.ArenaAllocator;
const Dir = std.fs.Dir;
const File = std.fs.File;

vocab: ArrayList([]const u8),
unk: usize,
token_freq: std.StringHashMap(usize),
zipf: ?[]Zipf,
allocator: Allocator,
arena: ArenaAllocator,

pub fn init(allocator: Allocator) Zipfer {
    return .{
        .vocab = .empty,
        .unk = 0,
        .token_freq = std.StringHashMap(usize).init(allocator),
        .zipf = null,
        .allocator = allocator,
        .arena = ArenaAllocator.init(allocator),
    };
}

pub fn deinit(self: *Zipfer) void {
    self.arena.deinit();

    self.vocab.deinit(self.allocator);
    self.token_freq.deinit();
    if (self.zipf != null) self.allocator.free(self.zipf.?);
}

pub fn loadVocab(self: *Zipfer, file: File) !void {
    var file_buffer: [1024]u8 = undefined;
    var reader = file.reader(&file_buffer);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        // Get only first column token
        var it = std.mem.splitAny(u8, line, "\t\n \r");
        if (it.next()) |token| {
            if (token.len == 0) continue;

            // Insert a token into the vocab
            const new_token = try Allocator.dupe(self.arena.allocator(), u8, token);
            try self.vocab.append(self.allocator, new_token);
        }
    }
}

pub fn count(self: *Zipfer, file: File) !void {
    // Initialize hash map
    for (self.vocab.items) |token| {
        try self.token_freq.put(token, 0);
    }

    var file_buffer: [1 << 20]u8 = undefined;
    var reader = file.reader(&file_buffer);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitAny(u8, line, " ");
        while (it.next()) |token| {
            if (token.len == 0) continue;

            if (self.token_freq.getPtr(token)) |ptr| {
                ptr.* += 1;
            } else {
                self.unk += 1;
            }
        }
    }

    self.zipf = try self.allocator.alloc(Zipf, self.token_freq.count());

    var it = self.token_freq.iterator();
    var i: usize = 0;
    while (it.next()) |kv| : (i += 1) {
        self.zipf.?[i].token = kv.key_ptr.*;
        self.zipf.?[i].rank = null;
        self.zipf.?[i].freq = kv.value_ptr.*;
    }

    util.sortZipf(self.zipf.?);

    // Set Rank
    for (self.zipf.?, 1..) |*entry, rank| {
        entry.rank = rank;
    }

    std.debug.print("{any}", .{self.zipf});
}

pub fn save(self: Zipfer, file: File) !void {
    _ = self;
    _ = file;
}

test "init deinit" {
    var zipfer = Zipfer.init(std.testing.allocator);
    defer zipfer.deinit();
}

test "load vocab" {
    var zipfer = Zipfer.init(std.testing.allocator);
    defer zipfer.deinit();

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(.{ .sub_path = "test.vocab", .data = 
        \\hello,
        \\world!
        \\🍣
        \\🤗
    });

    const file = try tmp.dir.openFile("test.vocab", .{ .mode = .read_only });
    defer file.close();

    try zipfer.loadVocab(file);

    const vocab = zipfer.vocab.items;
    try std.testing.expect(std.mem.eql(u8, "hello,", vocab[0]));
    try std.testing.expect(std.mem.eql(u8, "world!", vocab[1]));
    try std.testing.expect(std.mem.eql(u8, "🍣", vocab[2]));
    try std.testing.expect(std.mem.eql(u8, "🤗", vocab[3]));
}

test "count" {
    var zipfer = Zipfer.init(std.testing.allocator);
    defer zipfer.deinit();

    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();

    try tmp.dir.writeFile(.{ .sub_path = "test.vocab", .data = 
        \\hello,
        \\world!
        \\🍣
        \\🤗
    });

    try tmp.dir.writeFile(.{ .sub_path = "input.txt", .data = 
        \\hello, 🤗 world! 🍣 🍣
        \\hello, 🍣 🤗
        \\world! 🍣 world!
        \\world! 🤗
        \\world! 🍣 hello,
        \\hello, world! 🍣
        \\happy! 🍣 goodbye!
    });

    const vocab_file = try tmp.dir.openFile("test.vocab", .{ .mode = .read_only });
    defer vocab_file.close();

    const input_file = try tmp.dir.openFile("input.txt", .{ .mode = .read_only });
    defer input_file.close();

    try zipfer.loadVocab(vocab_file);
    try zipfer.count(input_file);

    try std.testing.expectEqual(4, zipfer.token_freq.get("hello,").?);
    try std.testing.expectEqual(6, zipfer.token_freq.get("world!").?);
    try std.testing.expectEqual(7, zipfer.token_freq.get("🍣").?);
    try std.testing.expectEqual(3, zipfer.token_freq.get("🤗").?);
    try std.testing.expectEqual(2, zipfer.unk);
}
