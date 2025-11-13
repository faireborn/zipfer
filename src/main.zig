const std = @import("std");
const Zipfer = @import("zipfer").Zipfer;

const usage_text =
    \\Usage: zipfer --vocab=<vocab_file> --target=<target_file>
    \\
    \\Compares the performance of the provided commands.
    \\
    \\Options:
    \\ --help      Show help (This message)
    \\ --vocab     Vocabulary file
    \\ --target    Target file
    \\
;

const Flags = enum {
    help,
    vocab,
    target,
    pub fn str(self: Flags) []const u8 {
        switch (self) {
            .help => return "--help",
            .vocab => return "--vocab",
            .target => return "--target",
        }
    }
};

const Options = struct {
    vocab: ?[]const u8,
    target: ?[]const u8,
};

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout_w = &stdout_writer.interface;

    const allocator = std.heap.page_allocator;

    var arena_instance: std.heap.ArenaAllocator = .init(allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const args = try std.process.argsAlloc(arena);

    if (args.len < 2) {
        std.log.err("Too few arguments: {s}\n", .{usage_text});
        std.process.exit(1);
    }

    var options: Options = .{ .vocab = null, .target = null };

    // Arg parse
    var arg_i: usize = 1;
    while (arg_i < args.len) : (arg_i += 1) {
        const arg = args[arg_i];

        if (std.mem.eql(u8, arg, Flags.help.str())) {
            // --help
            try stdout_w.writeAll(usage_text);
            try stdout_w.flush();
            return std.process.cleanExit();
        } else if (std.mem.startsWith(u8, arg, Flags.vocab.str())) {
            // --vocab
            const vocab_flag_len = Flags.vocab.str().len;
            if (arg.len <= vocab_flag_len or arg[vocab_flag_len] != '=') {
                std.log.err("Invalid command line format: {s}\n", .{usage_text});
                std.process.exit(1);
            }
            options.vocab = arg[(vocab_flag_len + 1)..];
        } else if (std.mem.startsWith(u8, arg, Flags.target.str())) {
            // --target
            const target_flag_len = Flags.target.str().len;
            if (arg.len <= target_flag_len or arg[target_flag_len] != '=') {
                std.log.err("Invalid command line format: {s}\n", .{usage_text});
                std.process.exit(1);
            }
            options.target = arg[(target_flag_len + 1)..];
        } else {
            std.log.err("Unrecognized argument: '{s}'\n{s}\n", .{ arg, usage_text });
            std.process.exit(1);
        }
    }

    // Check arguments
    if (options.vocab == null or options.target == null) {
        std.log.err("Required to set both options: {s}\n", .{usage_text});
    }

    const vocab_file = try std.fs.cwd().openFile(options.vocab.?, .{ .mode = .read_only });
    defer vocab_file.close();

    const target_file = try std.fs.cwd().openFile(options.target.?, .{ .mode = .read_only });
    defer target_file.close();

    var zipfer = Zipfer.init(allocator);
    defer zipfer.deinit();

    try zipfer.loadVocab(vocab_file);

    for (zipfer.vocab.items) |token| {
        std.debug.print("{s}", .{token});
    }
}
