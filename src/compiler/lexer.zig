const std = @import("std");
const testing = std.testing;

const TokenKind = enum {
    Integer,
};

pub const Token = struct {
    kind: TokenKind,
    lexme: []const u8,
    span: Span,
};

pub const Span = struct {
    const Self = @This();

    start: usize = 0,
    end: usize = 0,
    line: usize = 0,
};

pub const Lexer = struct {
    const Self = @This();
    currentSpan: Span = Span{},
    src: []const u8,

    pub fn init(src: []const u8) Lexer {
        return Lexer{
            .src = src,
        };
    }

    pub fn next(self: *Self) ?Token {
        self.skipWhitespace();
        const char = self.nextChar() orelse return null;
        if (!std.ascii.isDigit(char) or char != '_') {
            return self.number();
        }
        return null;
    }

    pub fn peek(_: *Self) ?Token {
        return null;
    }

    fn currentChar(self: *Self) ?u8 {
        if (self.currentSpan.end >= self.src.len) {
            return null;
        }
        return self.src[self.currentSpan.end];
    }

    fn nextChar(self: *Self) ?u8 {
        if (self.currentSpan.end + 1 >= self.src.len) {
            return null;
        }
        if (self.src[self.currentSpan.end] == '\n') {
            self.currentSpan.line += 1;
        }
        self.currentSpan.end += 1;
        return self.src[self.currentSpan.end];
    }

    fn peekChar(self: *Self) ?u8 {
        if (self.currentSpan.end + 1 >= self.src.len) {
            return null;
        }
        return self.src[self.currentSpan.end + 1];
    }

    fn span(self: *Self) Span {
        const s = Span{
            .start = self.currentSpan.start,
            .end = self.currentSpan.end,
            .line = self.currentSpan.line,
        };
        self.currentSpan.start = self.currentSpan.end;
        return s;
    }

    fn skipWhitespace(self: *Self) void {
        while (self.currentChar()) |char| {
            if (!std.ascii.isWhitespace(char)) {
                break;
            }
            _ = self.nextChar() orelse break;
        }
        _ = self.span();
    }

    fn number(self: *Self) Token {
        while (self.currentChar()) |char| {
            if (std.ascii.isDigit(char) or char == '_') {
                _ = self.nextChar() orelse break;
                continue;
            }
            break;
        }
        const start: usize = self.currentSpan.start;
        const end: usize = self.currentSpan.end + 1;
        const lexme: []const u8 = self.src[start..end];
        return Token{
            .kind = TokenKind.Integer,
            .lexme = lexme,
            .span = self.span(),
        };
    }
};

test "lexer number" {
    var lexer = Lexer.init(" 123_321");
    const token: ?Token = lexer.next();
    std.debug.print("\n'{s}'\n", .{token.?.lexme});
    const expected: ?Token = @as(?Token, Token{ .kind = TokenKind.Integer, .lexme = "123_321", .span = Span{
        .start = 1,
        .end = 7,
        .line = 0,
    } });
    try testing.expectEqualDeep(expected, token);
    // try testing.expectEqual(, token);
}
