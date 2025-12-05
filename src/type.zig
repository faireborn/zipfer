pub const Token = struct {
    token: []const u8,
    length: usize,
    freq: usize,
};

pub fn Zipf(comptime T: type) type {
    return struct {
        token_id: usize,
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
        tokens_per_sent: T,
        characters_per_token: T,
    };
}
