const std = @import("std");

pub const TokenType = enum {
    Number,
    Keyword,
    Identifier,
    PercentSign,
    Plus,
    Minus,
    Star,
    Slash,
    Colon,
    Semicolon,
    String,
};

pub const Keyword = enum {
    Load,
    LoadImm,
    Storeu8,
    Storeu16,
    Storeu32,
    Inc,
    Push,
    Pop,
    Add,
    SysCall,
};

pub const VecToken = std.ArrayList(Token);

pub const Token = struct {
    const Self = @This();

    kind: TokenType,
    lexme: []const u8,

    fn init(kind: TokenType, lexme: []const u8) Token {
        return Token{
            .kind = kind,
            .lexme = lexme,
        };
    }

    pub fn keyword(self: *const Self) ?Keyword {
        if (self.kind != TokenType.Keyword) {
            return null;
        }
        if (std.mem.eql(u8, self.lexme, "load")) {
            return Keyword.Load;
        } else if (std.mem.eql(u8, self.lexme, "loadimm")) {
            return Keyword.LoadImm;
        } else if (std.mem.eql(u8, self.lexme, "storeu8")) {
            return Keyword.Storeu8;
        } else if (std.mem.eql(u8, self.lexme, "storeu16")) {
            return Keyword.Storeu16;
        } else if (std.mem.eql(u8, self.lexme, "storeu32")) {
            return Keyword.Storeu32;
        } else if (std.mem.eql(u8, self.lexme, "inc")) {
            return Keyword.Inc;
        } else if (std.mem.eql(u8, self.lexme, "push")) {
            return Keyword.Push;
        } else if (std.mem.eql(u8, self.lexme, "pop")) {
            return Keyword.Pop;
        } else if (std.mem.eql(u8, self.lexme, "add")) {
            return Keyword.Add;
        } else if (std.mem.eql(u8, self.lexme, "syscall")) {
            return Keyword.SysCall;
        }
        unreachable;
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        _ = options;
        try std.fmt.format(out_stream, "Token(kind: {s}, lexme: {s})", .{
            @tagName(self.kind),
            self.lexme,
        });
    }
};

// TODO: Clean this function up a bit
fn checkForKeywords(lexme: []const u8) TokenType {
    if (std.mem.eql(u8, lexme, "load")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "loadimm")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "storeu8")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "storeu16")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "storeu32")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "inc")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "push")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "pop")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "add")) {
        return .Keyword;
    } else if (std.mem.eql(u8, lexme, "syscall")) {
        return .Keyword;
    }
    return .Identifier;
}

fn lineComment(ip: *usize, buf: []const u8) void {
    while (ip.* < buf.len and buf[ip.*] != '\n') {
        ip.* += 1;
    }
}

fn isLineComment(ip: usize, buf: []const u8) bool {
    const next = peek(ip, buf) orelse return false;
    return buf[ip] == '/' and next == '/';
}

fn peek(ip: usize, buf: []const u8) ?u8 {
    if (ip < buf.len) {
        return buf[ip];
    } else {
        return null;
    }
}

pub fn lexer(src: []const u8) !VecToken {
    var tokens: VecToken = VecToken.init(std.heap.page_allocator);
    var ip: usize = 0;
    while (ip < src.len) {
        if (std.ascii.isDigit(src[ip])) {
            const result = try number(&ip, src);
            const token = Token.init(.Number, result);
            try tokens.append(token);
            ip += 1;
        } else if (std.ascii.isAlphabetic(src[ip]) or src[ip] == '_') {
            const result = try identifier(&ip, src);
            const kind = checkForKeywords(result);
            const token = Token.init(kind, result);
            try tokens.append(token);
            ip += 1;
        } else if (isLineComment(ip, src)) {
            lineComment(&ip, src);
            ip += 1;
        } else if (src[ip] == '"') {
            const result = try string(&ip, src);
            const token = Token.init(.String, result);
            try tokens.append(token);
            ip += 1;
        } else if (src[ip] == '%') {
            const token = Token.init(.PercentSign, "%");
            try tokens.append(token);
            ip += 1;
        } else if (src[ip] == '+') {
            const token = Token.init(.Plus, "+");
            try tokens.append(token);
            ip += 1;
        } else if (src[ip] == '-') {
            const token = Token.init(.Minus, "-");
            try tokens.append(token);
            ip += 1;
        } else if (src[ip] == '*') {
            const token = Token.init(.Star, "-");
            try tokens.append(token);
            ip += 1;
        } else if (src[ip] == '/') {
            const token = Token.init(.Slash, "/");
            try tokens.append(token);
            ip += 1;
        } else if (src[ip] == ':') {
            const token = Token.init(.Colon, ":");
            try tokens.append(token);
            ip += 1;
        } else if (src[ip] == ';') {
            const token = Token.init(.Semicolon, ";");
            try tokens.append(token);
            ip += 1;
        } else if (std.ascii.isWhitespace(src[ip])) {
            ip += 1;
        } else {
            std.debug.panic("error: unknonw char '{c}' {d} unimplemented in assember tokenizer", .{ src[ip], ip });
            break;
        }
    }
    return tokens;
}

fn number(ip: *usize, buf: []const u8) ![]const u8 {
    const String = std.ArrayList(u8);
    var lexme: String = String.init(std.heap.page_allocator);
    while (std.ascii.isDigit(buf[ip.*])) {
        try lexme.append(buf[ip.*]);
        ip.* += 1;
    }
    ip.* -= 1;
    return lexme.items;
}

fn identifier(ip: *usize, buf: []const u8) ![]const u8 {
    const String = std.ArrayList(u8);
    var lexme: String = String.init(std.heap.page_allocator);
    while (std.ascii.isAlphanumeric(buf[ip.*])) {
        try lexme.append(buf[ip.*]);
        ip.* += 1;
    }
    ip.* -= 1;
    return lexme.items;
}

fn string(ip: *usize, buf: []const u8) ![]const u8 {
    const String = std.ArrayList(u8);
    var lexme: String = String.init(std.heap.page_allocator);
    ip.* += 1;
    while (buf[ip.*] != '"') {
        try lexme.append(buf[ip.*]);
        ip.* += 1;
    }
    ip.* += 1;
    return lexme.items;
}
