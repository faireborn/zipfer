const std = @import("std");
const Zipfer = @import("zipfer").Zipfer;

const usage_text =
    \\Usage: zipfer --vocab=<vocab_file> --target=<target_file> --output=<output_file>
    \\
    \\Zipf toolkit
    \\
    \\Options:
    \\ --help      show help (This message)
    \\ --vocab     vocabulary file
    \\ --target    target file
    \\ --output    output file
    \\
;

const Flags = enum {
    help,
    vocab,
    target,
    output,
    pub fn str(self: Flags) []const u8 {
        switch (self) {
            .help => return "--help",
            .vocab => return "--vocab",
            .target => return "--target",
            .output => return "--output",
        }
    }
};

const Options = struct {
    vocab: ?[]const u8,
    target: ?[]const u8,
    output: ?[]const u8,
};

// helper for flag parsing
fn parseFlag(arg: []const u8, flag: Flags, option: *?[]const u8) void {
    const flag_len = flag.str().len;
    if (arg.len <= flag_len or arg[flag_len] != '=') {
        std.log.err("Invalid command line format: {s}\n", .{usage_text});
        std.process.exit(1);
    }
    option.* = arg[(flag_len + 1)..];
}

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

    var options: Options = .{ .vocab = null, .target = null, .output = null };

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
            parseFlag(arg, Flags.vocab, &(options.vocab));
        } else if (std.mem.startsWith(u8, arg, Flags.target.str())) {
            // --target
            parseFlag(arg, Flags.target, &(options.target));
        } else if (std.mem.startsWith(u8, arg, Flags.output.str())) {
            // --output
            parseFlag(arg, Flags.output, &(options.output));
        } else {
            std.log.err("Unrecognized argument: '{s}'\n{s}\n", .{ arg, usage_text });
            std.process.exit(1);
        }
    }

    // Check arguments
    if (options.vocab == null or options.target == null) {
        std.log.err("Required to set all options: {s}\n", .{usage_text});
    }

    const vocab_file = try std.fs.cwd().openFile(options.vocab.?, .{ .mode = .read_only });
    defer vocab_file.close();

    const target_file = try std.fs.cwd().openFile(options.target.?, .{ .mode = .read_only });
    defer target_file.close();

    var zipfer = Zipfer.init(allocator);
    defer zipfer.deinit();

    try zipfer.loadVocab(vocab_file);
    try zipfer.count(target_file);
    try zipfer.eval();

    const output_file = try std.fs.cwd().createFile(options.output.?, .{});
    defer output_file.close();

    try zipfer.save(output_file);
}
