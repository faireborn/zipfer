const std = @import("std");
const Zipfer = @import("zipfer").Zipfer;

const usage_text =
    \\Usage: zipfer --target=<target_file> --output=<output_directory>
    \\
    \\Zipf toolkit for tokenizer evaluation
    \\
    \\Options:
    \\ --help      show help (This message)
    \\ --vocab     vocabrary file
    \\ --target    target file
    \\ --output    output directory
    \\
;

const help: []const u8 = "--help";
const vocab: []const u8 = "--vocab";
const target: []const u8 = "--target";
const output: []const u8 = "--output";

const Options = struct {
    vocab: ?[]const u8,
    target: ?[]const u8,
    output: ?[]const u8,
};

// helper for flag parsing
fn parseFlag(arg: []const u8, string: []const u8, option: *?[]const u8) void {
    const flag_len = string.len;
    if (arg.len <= flag_len or arg[flag_len] != '=') {
        std.log.err("Invalid command line format\n{s}\n", .{usage_text});
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
        std.log.err("Too few arguments\n{s}\n", .{usage_text});
        std.process.exit(1);
    }

    var options: Options = .{ .vocab = null, .target = null, .output = null };

    // Arg parse
    var arg_i: usize = 1;
    while (arg_i < args.len) : (arg_i += 1) {
        const arg = args[arg_i];

        if (std.mem.eql(u8, arg, help)) {
            // --help
            try stdout_w.writeAll(usage_text);
            try stdout_w.flush();
            return std.process.cleanExit();
        } else if (std.mem.startsWith(u8, arg, vocab)) {
            // --vocab
            parseFlag(arg, vocab, &(options.vocab));
        } else if (std.mem.startsWith(u8, arg, target)) {
            // --target
            parseFlag(arg, target, &(options.target));
        } else if (std.mem.startsWith(u8, arg, output)) {
            // --output
            parseFlag(arg, output, &(options.output));
        } else {
            std.log.err("Unrecognized argument: '{s}'\n{s}\n", .{ arg, usage_text });
            std.process.exit(1);
        }
    }

    // Check arguments
    if (options.vocab == null or options.target == null or options.output == null) {
        std.log.err("Required to set all options:\n{s}\n", .{usage_text});
        std.process.exit(1);
    }

    var zipfer = Zipfer.init(allocator);
    defer zipfer.deinit();

    try zipfer.load(options.vocab.?, options.target.?);
    try zipfer.eval();
    try zipfer.write(options.output.?);
}
