const Token = t.Token;
const Zipf = t.Zipf;
const ZipferResult = t.ZipferResult;
const StringUtil = util.StringUtil;
const Stats = util.Stats;
const t = @import("type.zig");
const lr = @import("linear_regression.zig");
const util = @import("util.zig");
const filesystem = @import("filesystem.zig");

const Unzipf = @import("unzipf").Unzipf;
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
        num_sentences: usize,
        num_tokens: usize,
        num_characters: usize,
        tokens: MultiArrayList(Token),
        zipf: MultiArrayList(Zipf(T)),
        tail: usize, // use only zipf[0..tail] and discard the rest
        result: ?ZipferResult(T),

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .arena = ArenaAllocator.init(allocator),
                .num_sentences = 0,
                .num_tokens = 0,
                .num_characters = 0,
                .tokens = .empty,
                .zipf = .empty,
                .tail = 0,
                .result = null,
            };
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
            self.tokens.deinit(self.allocator);
            self.zipf.deinit(self.allocator);
        }

        pub fn load(self: *Self, vocab_file: []const u8, target_file: []const u8) !void {
            var vocab = try filesystem.ReadableFile(1 << 10).init(vocab_file);
            defer vocab.deinit();

            var input = try filesystem.ReadableFile(1 << 22).init(target_file);
            defer input.deinit();

            while (try vocab.readLine('\n')) |line| {
                var it = std.mem.splitAny(u8, line, "\t ");
                const token = it.next() orelse "";
                try self.tokens.append(self.allocator, .{
                    .token = try Allocator.dupe(self.arena.allocator(), u8, token),
                    .length = StringUtil.strLen(token),
                    .freq = 0,
                });
            }

            const sliced_tokens = self.tokens.slice();

            while (try input.readLine('\n')) |line| {
                self.num_sentences += 1;

                var it = std.mem.splitAny(u8, line, " ");
                while (it.next()) |id| {
                    if (std.fmt.parseInt(usize, id, 10)) |token_id| {
                        sliced_tokens.items(.freq)[token_id] += 1;
                        self.num_tokens += 1;
                    } else |_| continue;
                }
            }

            // count characters
            for (0..self.tokens.len) |token_id| {
                const tmp = self.tokens.get(token_id);
                self.num_characters += tmp.length * tmp.freq;
            }

            // Create MultiArrayList of `Zipf`
            try self.zipf.resize(self.allocator, self.tokens.len);

            for (0..self.zipf.len) |token_id| {
                self.zipf.set(token_id, .{
                    .token_id = token_id,
                    .rank = undefined,
                    .freq = self.tokens.get(token_id).freq,
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

        pub fn eval(self: *Self) !void {
            self.tail = self.zipf.len;

            const sliced = self.zipf.slice();
            const ranks = sliced.items(.rank);
            const freqs = sliced.items(.freq);
            const log_ranks = sliced.items(.log_rank);
            const log_freqs = sliced.items(.log_freq);

            for (0..self.zipf.len) |i| {
                // log(rank)
                const log_rank = log10(@as(T, @floatFromInt(ranks[i])));
                // We consider only tokens with log(rank) <= 6
                if (log_rank > 6) {
                    self.tail = i;
                    break;
                }
                log_ranks[i] = log_rank;

                // log(freq)
                if (freqs[i] == 0) {
                    self.tail = i;
                    break;
                }
                log_freqs[i] = log10(@as(T, @floatFromInt(freqs[i])));
            }

            // We don't consider tokens with a frequency of 0 (0..tail)
            const lr_result = try lr.model(T, log_ranks[0..self.tail], log_freqs[0..self.tail]);
            const slope = lr_result.slope;
            const intercept = lr_result.intercept;

            const absolute_errors = try self.allocator.alloc(T, self.tail);
            defer self.allocator.free(absolute_errors);

            for (0..self.tail) |i| {
                const zipf_log_freq = slope * log_ranks[i] + intercept;
                absolute_errors[i] = @abs(zipf_log_freq - log_freqs[i]);
            }

            // Set results (R^2, slope, intercept, MAE)
            self.result = .{
                .R_squared = if (lr_result.r) |r| r * r else null,
                .slope = slope,
                .intercept = intercept,
                .mae = Stats.mean(T, absolute_errors),
                .tokens_per_sent = @as(T, @floatFromInt(self.num_tokens)) / @as(T, @floatFromInt(self.num_sentences)),
                .characters_per_token = @as(T, @floatFromInt(self.num_characters)) / @as(T, @floatFromInt(self.num_tokens)),
            };
        }

        pub fn write(self: Self, dir_name: []const u8) !void {
            try std.fs.cwd().makeDir(dir_name);
            var dir = try std.fs.cwd().openDir(dir_name, .{});
            defer dir.close();

            if (self.zipf.len == 0) return error.NoDataToWrite;

            var file_buffer: [1024]u8 = undefined;

            // Write tokens info to a file
            var tokens_file = try dir.createFile("tokens.tsv", .{});
            var tokens_writer = tokens_file.writer(&file_buffer);
            try tokens_writer.interface.print("token_id\trank\tfreq\tlog_rank\tlog_freq\tlength\ttoken\n", .{});

            for (0..self.tail) |i| {
                const tmp_zipf = self.zipf.get(i);
                const tmp_token = self.tokens.get(tmp_zipf.token_id);

                try tokens_writer.interface.print("{}\t{}\t{}\t{}\t{}\t{}\t", .{
                    tmp_zipf.token_id,
                    tmp_zipf.rank,
                    tmp_zipf.freq,
                    tmp_zipf.log_rank,
                    tmp_zipf.log_freq,
                    tmp_token.length,
                });

                var begin: usize = 0;
                const end = tmp_token.token.len;
                while (begin < end) {
                    const res = StringUtil.decodeUTF8(tmp_token.token[begin..]);
                    try tokens_writer.interface.print("{u}", .{res[0]});
                    begin += res[1];
                }
                try tokens_writer.interface.writeByte('\n');
            }
            try tokens_writer.interface.flush();

            // If result is not null, create a file and write a result to the file
            if (self.result) |result| {
                var result_file = try dir.createFile("result.tsv", .{});
                var result_writer = result_file.writer(&file_buffer);
                try result_writer.interface.print("R^2\tslope\tintercept\tMAE\t#tokens/sent\t#chars/token\n", .{});
                if (self.result.?.R_squared) |R_squared| {
                    try result_writer.interface.print("{}\t{}\t{}\t{}\t{}\t{}", .{
                        R_squared,
                        result.slope,
                        result.intercept,
                        result.mae,
                        result.tokens_per_sent,
                        result.characters_per_token,
                    });
                } else {
                    try result_writer.interface.print("null\t{}\t{}\t{}\t{}\t{}", .{
                        result.slope,
                        result.intercept,
                        result.mae,
                        result.tokens_per_sent,
                        result.characters_per_token,
                    });
                }
                try result_writer.interface.flush();
            } else {
                return error.ResultIsNull;
            }
        }
    };
}

test "init deinit" {
    {
        var zipfer = ZipferImpl(f32).init(std.testing.allocator);
        defer zipfer.deinit();
    }
    {
        var zipfer = ZipferImpl(f64).init(std.testing.allocator);
        defer zipfer.deinit();
    }
}

test {
    _ = lr;
}
