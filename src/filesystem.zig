const std = @import("std");
const File = std.fs.File;
const Reader = std.fs.File.Reader;

pub fn ReadableFile(comptime buf_size: usize) type {
    return struct {
        file: File,
        reader: Reader,

        const Self = @This();
        var buf: [buf_size]u8 = undefined;

        pub fn init(file_name: []const u8) !Self {
            const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
            return .{
                .file = file,
                .reader = file.reader(&buf),
            };
        }

        pub fn deinit(self: Self) void {
            self.file.close();
        }

        pub fn readLine(self: *Self, delimiter: u8) !?[]u8 {
            return self.reader.interface.takeDelimiter(delimiter);
        }
    };
}
