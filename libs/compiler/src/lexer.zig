const std = @import("std");
const testing = std.testing;

pub const TokenKind = enum {
    Integer,
    Identifier,
    String,
    Struct,
    Enum,
    Fn,
    True,
    False,
    Let,
    If,
    Else,
    Return,
    ParenOpen,
    ParenClose,
    BracketOpen,
    BracketClose,
    BraceOpen,
    BraceClose,
    Bang,
    NotEqual,
    GreaterThen,
    GreaterThenOrEqual,
    LessThen,
    LessThenOrEqual,
    Plus,
    Dash,
    Star,
    ForwardSlash,
    Semicolon,
    EOF,
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

fn isNumber(char: u8) bool {
    return std.ascii.isDigit(char) or char == '_';
}

fn isIdentifier(char: u8) bool {
    return std.ascii.isAlphanumeric(char) or char == '_';
}

pub const Lexer = struct {
    const Self = @This();
    currentSpan: Span = Span{},
    src: []const u8,

    pub fn init(src: []const u8) Lexer {
        return Lexer{
            .src = src,
        };
    }

    pub fn next(self: *Self) !Token {
        self.skipWhitespace();
        const char = self.nextChar() orelse return Token{
            .kind = TokenKind.EOF,
            .lexme = "",
            .span = self.span(),
        };
        const peekChr = self.peekChar() orelse 0;
        if (std.ascii.isDigit(char) or char == '_') {
            return self.number();
        } else if (std.ascii.isAlphabetic(char) or char == '_') {
            return self.identifier();
        } else if (char == '"') {
            return self.string();
        } else if (char == '(') {
            return self.token(.ParenOpen, 1);
        } else if (char == ')') {
            return self.token(.ParenClose, 1);
        } else if (char == '[') {
            return self.token(.BracketOpen, 1);
        } else if (char == ']') {
            return self.token(.BracketClose, 1);
        } else if (char == '{') {
            return self.token(.BraceOpen, 1);
        } else if (char == '}') {
            return self.token(.BraceClose, 1);
        } else if (char == '!' and peekChr == '=') {
            return self.token(.NotEqual, 2);
        } else if (char == '!') {
            return self.token(.Bang, 1);
        } else if (char == '>' and peekChr == '=') {
            return self.token(.GreaterThenOrEqual, 2);
        } else if (char == '>') {
            return self.token(.GreaterThen, 1);
        } else if (char == '<' and peekChr == '=') {
            return self.token(.LessThenOrEqual, 2);
        } else if (char == '<') {
            return self.token(.LessThen, 1);
        } else if (char == '+') {
            return self.token(.Plus, 1);
        } else if (char == '-') {
            return self.token(.Dash, 1);
        } else if (char == '*') {
            return self.token(.Star, 1);
        } else if (char == '/') {
            return self.token(.ForwardSlash, 1);
        } else if (char == ';') {
            return self.token(.Semicolon, 1);
        }
        return LexerError.UnexpectedCharacter;
    }

    pub fn peek(self: *Self) !Token {
        const oldSpan = self.span();
        const tk = try self.next();
        self.currentSpan = oldSpan;
        return tk;
    }

    fn token(self: *Self, kind: TokenKind, size: usize) Token {
        for (1..size) |_| {
            _ = self.nextChar();
        }
        return Token{
            .kind = kind,
            .lexme = self.lexme(),
            .span = self.span(),
        };
    }

    fn nextChar(self: *Self) ?u8 {
        const ip = self.currentSpan.end;
        if (ip >= self.src.len) {
            return null;
        }
        const char = self.src[ip];
        self.currentSpan.line = if (char == '\n') self.currentSpan.line + 1 else self.currentSpan.line;
        self.currentSpan.end += 1;
        return char;
    }

    fn peekChar(self: *Self) ?u8 {
        if (self.currentSpan.end >= self.src.len) {
            return null;
        }
        return self.src[self.currentSpan.end];
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

    fn lexme(self: *Self) []const u8 {
        return self.src[self.currentSpan.start..self.currentSpan.end];
    }

    fn skipWhitespace(self: *Self) void {
        const c = self.peekChar() orelse return;
        if (!std.ascii.isWhitespace(c)) {
            return;
        }
        while (self.peekChar()) |char| {
            if (!std.ascii.isWhitespace(char)) {
                break;
            }
            _ = self.nextChar() orelse break;
        }
        _ = self.span();
    }

    fn number(self: *Self) Token {
        return self.takeWhile(isNumber, .Integer);
    }

    fn identifier(self: *Self) Token {
        var ident = self.takeWhile(isIdentifier, .Identifier);
        if (std.mem.eql(u8, ident.lexme, "struct")) {
            ident.kind = .Struct;
        } else if (std.mem.eql(u8, ident.lexme, "enum")) {
            ident.kind = .Enum;
        } else if (std.mem.eql(u8, ident.lexme, "fn")) {
            ident.kind = .Fn;
        } else if (std.mem.eql(u8, ident.lexme, "true")) {
            ident.kind = .True;
        } else if (std.mem.eql(u8, ident.lexme, "false")) {
            ident.kind = .False;
        } else if (std.mem.eql(u8, ident.lexme, "let")) {
            ident.kind = .Let;
        } else if (std.mem.eql(u8, ident.lexme, "if")) {
            ident.kind = .If;
        } else if (std.mem.eql(u8, ident.lexme, "else")) {
            ident.kind = .Else;
        } else if (std.mem.eql(u8, ident.lexme, "return")) {
            ident.kind = .Return;
        }
        return ident;
    }

    fn string(self: *Self) Token {
        _ = self.nextChar() orelse unreachable;
        while (self.peekChar()) |char| {
            if (char != '"') {
                _ = self.nextChar() orelse break;
                continue;
            }
            break;
        }
        _ = self.nextChar() orelse unreachable;
        return Token{
            .kind = .String,
            .lexme = self.lexme(),
            .span = self.span(),
        };
    }

    fn takeWhile(self: *Self, predicate: *const fn (u8) bool, kind: TokenKind) Token {
        while (self.peekChar()) |char| {
            if (predicate(char)) {
                _ = self.nextChar() orelse break;
                continue;
            }
            break;
        }
        return Token{
            .kind = kind,
            .lexme = self.lexme(),
            .span = self.span(),
        };
    }
};

pub const LexerError = error{
    UnexpectedCharacter,
};

test "lexer nextChar" {
    var lexer = Lexer.init(" 123_321   4_3_2_1");
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.nextChar(), '1');
    try testing.expectEqual(lexer.nextChar(), '2');
    try testing.expectEqual(lexer.nextChar(), '3');
    try testing.expectEqual(lexer.nextChar(), '_');
    try testing.expectEqual(lexer.nextChar(), '3');
    try testing.expectEqual(lexer.nextChar(), '2');
    try testing.expectEqual(lexer.nextChar(), '1');
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.nextChar(), '4');
    try testing.expectEqual(lexer.nextChar(), '_');
    try testing.expectEqual(lexer.nextChar(), '3');
    try testing.expectEqual(lexer.nextChar(), '_');
    try testing.expectEqual(lexer.nextChar(), '2');
    try testing.expectEqual(lexer.nextChar(), '_');
    try testing.expectEqual(lexer.nextChar(), '1');
    try testing.expectEqual(lexer.nextChar(), null);
}

test "lexer peekChar" {
    var lexer = Lexer.init(" 123_321   4_3_2_1");
    try testing.expectEqual(lexer.peekChar(), ' ');
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.peekChar(), '1');
    try testing.expectEqual(lexer.nextChar(), '1');
    try testing.expectEqual(lexer.peekChar(), '2');
    try testing.expectEqual(lexer.nextChar(), '2');
    try testing.expectEqual(lexer.peekChar(), '3');
    try testing.expectEqual(lexer.nextChar(), '3');
    try testing.expectEqual(lexer.peekChar(), '_');
    try testing.expectEqual(lexer.nextChar(), '_');
    try testing.expectEqual(lexer.peekChar(), '3');
    try testing.expectEqual(lexer.nextChar(), '3');
    try testing.expectEqual(lexer.peekChar(), '2');
    try testing.expectEqual(lexer.nextChar(), '2');
    try testing.expectEqual(lexer.peekChar(), '1');
    try testing.expectEqual(lexer.nextChar(), '1');
    try testing.expectEqual(lexer.peekChar(), ' ');
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.peekChar(), ' ');
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.peekChar(), ' ');
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.peekChar(), '4');
    try testing.expectEqual(lexer.nextChar(), '4');
    try testing.expectEqual(lexer.peekChar(), '_');
    try testing.expectEqual(lexer.nextChar(), '_');
    try testing.expectEqual(lexer.peekChar(), '3');
    try testing.expectEqual(lexer.nextChar(), '3');
    try testing.expectEqual(lexer.peekChar(), '_');
    try testing.expectEqual(lexer.nextChar(), '_');
    try testing.expectEqual(lexer.peekChar(), '2');
    try testing.expectEqual(lexer.nextChar(), '2');
    try testing.expectEqual(lexer.peekChar(), '_');
    try testing.expectEqual(lexer.nextChar(), '_');
    try testing.expectEqual(lexer.peekChar(), '1');
    try testing.expectEqual(lexer.nextChar(), '1');
    try testing.expectEqual(lexer.peekChar(), null);
    try testing.expectEqual(lexer.nextChar(), null);
}

test "check that span is correct" {
    var lexer = Lexer.init(" 123_321   4_3_2_1");
    try testing.expectEqual(lexer.currentSpan.end, 0);
    try testing.expectEqual(lexer.nextChar(), ' ');
    try testing.expectEqual(lexer.span(), Span{
        .start = 0,
        .end = 1,
        .line = 0,
    });
    try testing.expectEqual(lexer.currentSpan.end, 1);
    try testing.expectEqual(lexer.nextChar(), '1');
    try testing.expectEqual(lexer.currentSpan.end, 2);
    try testing.expectEqual(lexer.nextChar(), '2');
    try testing.expectEqual(lexer.currentSpan.end, 3);
    try testing.expectEqual(lexer.nextChar(), '3');
    try testing.expectEqual(lexer.span(), Span{
        .start = 1,
        .end = 4,
        .line = 0,
    });
    try testing.expectEqual(lexer.currentSpan.end, 4);
}

test "skip whitespace" {
    var lexer = Lexer.init(" 123_321   4_3_2_1");
    _ = lexer.skipWhitespace();
    try testing.expectEqual(lexer.nextChar(), '1');
}

test "number parser" {
    var lexer = Lexer.init("123_321");
    try testing.expectEqualDeep(lexer.number(), Token{ .kind = TokenKind.Integer, .lexme = "123_321", .span = Span{
        .start = 0,
        .end = 7,
        .line = 0,
    } });
}

test "identifier parser" {
    var lexer = Lexer.init("number");
    try testing.expectEqualDeep(lexer.identifier(), Token{ .kind = TokenKind.Identifier, .lexme = "number", .span = Span{
        .start = 0,
        .end = 6,
        .line = 0,
    } });
}

test "lexer number" {
    var lexer = Lexer.init(" 123_321   4_3_2_1");
    const first: Token = Token{ .kind = TokenKind.Integer, .lexme = "123_321", .span = Span{
        .start = 1,
        .end = 8,
        .line = 0,
    } };
    const t1 = try lexer.next();
    if (testing.expectEqualDeep(t1, first)) |_| {} else |err| {
        std.debug.print("\nERROR\n", .{});
        std.debug.print("{any}\n", .{err});
        std.debug.print("t1: '{s}'\n", .{t1.lexme});
        std.debug.print("start: {d}, end: {d}\n", .{ t1.span.start, t1.span.end });
    }
    const second: Token = Token{ .kind = TokenKind.Integer, .lexme = "4_3_2_1", .span = Span{
        .start = 11,
        .end = 18,
        .line = 0,
    } };
    const t2 = try lexer.next();
    try testing.expectEqualDeep(t2, second);
    if (testing.expectEqualDeep(t1, first)) |_| {} else |err| {
        std.debug.print("\ntERROR\n", .{});
        std.debug.print("{any}\n", .{err});
        std.debug.print("\nt2: '{s}'\n", .{t2.lexme});
        std.debug.print("start: {d}, end: {d}\n", .{ t2.span.start, t2.span.end });
    }
}

test "lexer string" {
    var lexer = Lexer.init("\"hello world\"");
    var token = try lexer.next();
    var expected = Token{ .kind = TokenKind.String, .lexme = "\"hello world\"", .span = Span{
        .start = 0,
        .end = 13,
        .line = 0,
    } };
    if (testing.expectEqualDeep(token, expected)) |_| {} else |err| {
        std.debug.print("\nTESTING ERROR: {any}\n", .{err});
        std.debug.print("{}\n", .{token.kind});
        std.debug.print("'{s}'\n", .{token.lexme});
        std.debug.print("{}\n", .{token.span});
    }
}

test "lexer peek" {
    var lexer = Lexer.init(" 123_321   4_3_2_1");
    const span = lexer.span();
    if (testing.expectEqual(span, Span{
        .start = 0,
        .end = 0,
        .line = 0,
    })) |_| {} else |err| {
        std.debug.print("\ntERROR\n", .{});
        std.debug.print("{any}\n", .{err});
        std.debug.print("start: {d}, end: {d}\n", .{ span.start, span.end });
    }
    const first: Token = Token{ .kind = TokenKind.Integer, .lexme = "123_321", .span = Span{
        .start = 1,
        .end = 8,
        .line = 0,
    } };
    const t1 = try lexer.next();
    if (testing.expectEqualDeep(t1, first)) |_| {} else |err| {
        std.debug.print("\ntERROR\n", .{});
        std.debug.print("{any}\n", .{err});
        std.debug.print("\nt2: '{s}'\n", .{t1.lexme});
        std.debug.print("start: {d}, end: {d}\n", .{ t1.span.start, t1.span.end });
    }
}

test "lexer keyword parser" {
    var lexer = Lexer.init("struct enum fn true false let if else return");
    try testToken(try lexer.next(), .Struct, "struct", 0, 6, 0);
    try testToken(try lexer.next(), .Enum, "enum", 7, 11, 0);
    try testToken(try lexer.next(), .Fn, "fn", 12, 14, 0);
    try testToken(try lexer.next(), .True, "true", 15, 19, 0);
    try testToken(try lexer.next(), .False, "false", 20, 25, 0);
    try testToken(try lexer.next(), .Let, "let", 26, 29, 0);
    try testToken(try lexer.next(), .If, "if", 30, 32, 0);
    try testToken(try lexer.next(), .Else, "else", 33, 37, 0);
    try testToken(try lexer.next(), .Return, "return", 38, 44, 0);
}

test "lexer punctuator parser" {
    const src = "()[]{}!!= > >= < <= + - * /;";
    var lexer = Lexer.init(src);
    try testToken(try lexer.next(), .ParenOpen, "(", 0, 1, 0);
    try testToken(try lexer.next(), .ParenClose, ")", 1, 2, 0);
    try testToken(try lexer.next(), .BracketOpen, "[", 2, 3, 0);
    try testToken(try lexer.next(), .BracketClose, "]", 3, 4, 0);
    try testToken(try lexer.next(), .BraceOpen, "{", 4, 5, 0);
    try testToken(try lexer.next(), .BraceClose, "}", 5, 6, 0);
    try testToken(try lexer.next(), .Bang, "!", 6, 7, 0);
    try testToken(try lexer.next(), .NotEqual, "!=", 7, 9, 0);
    try testToken(try lexer.next(), .GreaterThen, ">", 10, 11, 0);
    try testToken(try lexer.next(), .GreaterThenOrEqual, ">=", 12, 14, 0);
    try testToken(try lexer.next(), .LessThen, "<", 15, 16, 0);
    try testToken(try lexer.next(), .LessThenOrEqual, "<=", 17, 19, 0);
    try testToken(try lexer.next(), .Plus, "+", 20, 21, 0);
    try testToken(try lexer.next(), .Dash, "-", 22, 23, 0);
    try testToken(try lexer.next(), .Star, "*", 24, 25, 0);
    try testToken(try lexer.next(), .ForwardSlash, "/", 26, 27, 0);
    try testToken(try lexer.next(), .Semicolon, ";", 27, 28, 0);
}

test "lexing a basic hello world" {
    const src = "fn main() {\n println(\"Hello, World!\");\n}";
    var lexer = Lexer.init(src);
    try testToken(try lexer.next(), .Fn, "fn", 0, 2, 0);
    try testToken(try lexer.next(), .Identifier, "main", 3, 7, 0);
    try testToken(try lexer.next(), .ParenOpen, "(", 7, 8, 0);
    try testToken(try lexer.next(), .ParenClose, ")", 8, 9, 0);
    try testToken(try lexer.next(), .BraceOpen, "{", 10, 11, 0);
    try testToken(try lexer.next(), .Identifier, "println", 13, 20, 1);
    try testToken(try lexer.next(), .ParenOpen, "(", 20, 21, 1);
    try testToken(try lexer.next(), .String, "\"Hello, World!\"", 21, 36, 1);
    try testToken(try lexer.next(), .ParenClose, ")", 36, 37, 1);
    try testToken(try lexer.next(), .Semicolon, ";", 37, 38, 1);
    try testToken(try lexer.next(), .BraceClose, "}", 40, 40, 2);
}

fn testToken(token: Token, expectedKind: TokenKind, expectedLexme: []const u8, expectedStart: usize, expectedEnd: usize, expectedLine: usize) !void {
    const GREEN = "\x1b[32m";
    const RED = "\x1b[31m";
    const RESET = "\x1b[0m";
    testing.expectEqualDeep(token.kind, expectedKind) catch {
        std.debug.print("{s}{} -> {s}{}{s}\n", .{ GREEN, expectedKind, RED, token.kind, RESET });
        return error.TestFailed;
    };
    testing.expectEqualDeep(token.lexme, expectedLexme) catch {
        std.debug.print("{s}{s} -> {s}{s}{s}\n", .{ GREEN, expectedLexme, RED, token.lexme, RESET });
        return error.TestFailed;
    };
    testing.expectEqualDeep(token.span.start, expectedStart) catch {
        std.debug.print("{s}{d} -> {s}{d}{s}\n", .{ GREEN, expectedStart, RED, token.span.start, RESET });
        return error.TestFailed;
    };
    testing.expectEqualDeep(token.span.end, expectedEnd) catch {
        std.debug.print("{s}{d} -> {s}{d}{s}\n", .{ GREEN, expectedEnd, RED, token.span.end, RESET });
        return error.TestFailed;
    };
    testing.expectEqualDeep(token.span.line, expectedLine) catch {
        std.debug.print("{s}{d} -> {s}{d}{s}\n", .{ GREEN, expectedLine, RED, token.span.end, RESET });
        return error.TestFailed;
    };
}
