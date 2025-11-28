pub fn Zipf(comptime T: type) type {
    return struct {
        token: []const u8,
        rank: usize,
        freq: usize,
        log_rank: T,
        log_freq: T,
    };
}

pub fn ZipferResult(comptime T: type) type {
    return struct {
        R_squared: ?T,
        slope: T,
        intercept: T,
        mae: T,
    };
}
