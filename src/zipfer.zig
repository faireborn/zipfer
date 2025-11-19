const Zipf = @import("type.zig").Zipf;
const lr = @import("linear_regression.zig");

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const Dir = std.fs.Dir;
const File = std.fs.File;
const ArrayList = std.ArrayList;
const MultiArrayList = std.MultiArrayList;
const log10 = std.math.log10;

pub fn ZipferImpl(comptime T: type) type {
    return struct {
        allocator: Allocator,
        arena: ArenaAllocator,
        vocab: ArrayList([]const u8),
        unk: usize,
        token_freq: std.StringHashMap(usize),
        zipf: MultiArrayList(Zipf(T)),
        score: ?T,

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .arena = ArenaAllocator.init(allocator),
                .vocab = .empty,
                .unk = 0,
                .token_freq = std.StringHashMap(usize).init(allocator),
                .zipf = .empty,
                .score = undefined,
            };
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
            self.vocab.deinit(self.allocator);
            self.token_freq.deinit();
            self.zipf.deinit(self.allocator);
        }

        pub fn loadVocab(self: *Self, file: File) !void {
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

        pub fn count(self: *Self, file: File) !void {
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

            // Create MultiArrayList of `Zipf`
            try self.zipf.resize(self.allocator, self.token_freq.count());

            // Set token and freq to zipf
            var it = self.token_freq.iterator();
            var i: usize = 0;
            while (it.next()) |kv| : (i += 1) {
                self.zipf.set(i, .{
                    .token = kv.key_ptr.*,
                    .rank = undefined,
                    .freq = kv.value_ptr.*,
                    .log_rank = undefined,
                    .log_freq = undefined,
                });
            }

            // Sort by freq
            const sliced = self.zipf.slice();
            self.zipf.sortUnstable(struct {
                freqs: []usize,

                pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
                    return ctx.freqs[a] > ctx.freqs[b];
                }
            }{ .freqs = sliced.items(.freq) });

            // Set Rank
            for (sliced.items(.rank), 1..) |*entry, rank| {
                entry.* = rank;
            }
        }

        pub fn eval(self: *Self, file_or_null: ?File) !void {
            if (file_or_null) |file| try self.count(file) else {
                if (self.token_freq.count() == 0) return error.FileIsNull;
            }

            const sliced = self.zipf.slice();
            const ranks = sliced.items(.rank);
            const freqs = sliced.items(.freq);
            var log_ranks = sliced.items(.log_rank);
            var log_freqs = sliced.items(.log_freq);

            for (0..self.zipf.len) |i| {
                log_ranks[i] = log10(@as(T, @floatFromInt(ranks[i])));
                if (freqs[i] == 0) {
                    log_freqs[i] = 0;
                } else {
                    log_freqs[i] = log10(@as(T, @floatFromInt(freqs[i])));
                }
            }

            const result = try lr.model(T, log_ranks, log_freqs);

            if (result.r) |r| {
                // Return R^2 score
                self.score = r * r;
            } else {
                // If r value is null, return null
                self.score = null;
            }
        }

        pub fn write(self: Self, dir: Dir) !void {
            if (self.zipf.len == 0) return error.NoDataToWrite;

            var file_buffer: [1024]u8 = undefined;

            // Write tokens info to a file
            var tokens_file = try dir.createFile("tokens.tsv", .{});
            var tokens_writer = tokens_file.writer(&file_buffer);
            try tokens_writer.interface.print("token\trank\tfreq\tlog_rank\tlog_freq\n", .{});

            for (0..self.zipf.len) |i| {
                const tmp = self.zipf.get(i);
                try tokens_writer.interface.print("{s}\t{}\t{}\t{}\t{}\n", .{ tmp.token, tmp.rank, tmp.freq, tmp.log_rank, tmp.log_freq });
            }
            try tokens_writer.interface.flush();

            // Write some extra info to a file
            var info_file = try dir.createFile("info.txt", .{});
            var info_writer = info_file.writer(&file_buffer);
            if (self.unk > 0) {
                try info_writer.interface.print("Unknown tokens count = {}\n", .{self.unk});
            }
            try info_writer.interface.flush();

            // If score is not null, create a file and write a score to the file
            if (self.score) |score| {
                var score_file = try dir.createFile("score.txt", .{});
                var score_writer = score_file.writer(&file_buffer);
                try score_writer.interface.print("{}", .{score});
                try score_writer.interface.flush();
            } else {
                return error.ScoreIsNull;
            }
        }
    };
}

test "init deinit" {
    var zipfer = ZipferImpl(f32).init(std.testing.allocator);
    defer zipfer.deinit();
}

test "load vocab" {
    var zipfer = ZipferImpl(f32).init(std.testing.allocator);
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
    try std.testing.expectEqual(4, vocab.len);
    try std.testing.expect(std.mem.eql(u8, "hello,", vocab[0]));
    try std.testing.expect(std.mem.eql(u8, "world!", vocab[1]));
    try std.testing.expect(std.mem.eql(u8, "🍣", vocab[2]));
    try std.testing.expect(std.mem.eql(u8, "🤗", vocab[3]));
}

test "count" {
    var zipfer = ZipferImpl(f32).init(std.testing.allocator);
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

test {
    _ = lr;
}
