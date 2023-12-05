const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const TokenKind = @import("lexer.zig").TokenKind;
const Token = @import("lexer.zig").Token;
const Span = @import("lexer.zig").Span;
const Lexer = @import("lexer.zig").Lexer;
const IdentList = std.ArrayList([]const u8);

pub const AtomNumber = struct {
    value: f64,
    span: Span,
};

pub const AtomString = struct {
    value: []const u8,
    span: Span,
};

pub const Atom = union(enum) {
    number: AtomNumber,
    string: AtomString,
};

pub const Call = struct {
    name: []const u8,
    args: std.ArrayList(Expr),
    span: Span,
};

pub const Function = struct {
    name: []const u8,
    params: std.ArrayList([]const u8),
    body: std.ArrayList(Expr),
    span: Span,
};

pub const Expr = union(enum) {
    atom: Atom,
    call: Call,
    function: Function,
};

pub const Parser = struct {
    const Self = @This();
    allactor: std.mem.Allocator,
    currentToken: ?Token = null,
    lexer: Lexer,

    pub fn init(allactor: std.mem.Allocator, lexer: Lexer) Parser {
        return Parser{
            .allactor = allactor,
            .lexer = lexer,
        };
    }

    pub fn parse(self: *Self) ParserError![]Expr {
        var exprs = std.ArrayList(Expr).init(std.heap.page_allocator);
        defer exprs.deinit();
        while (self.next() != null) {
            exprs.append(self.function()) catch return ParserError.BlowingUp;
        }

        return self.allactor.dupe(Expr, exprs.items) catch return ParserError.OutOfMemory;
    }

    fn next(self: *Self) ?Token {
        self.currentToken = self.lexer.next() catch return null;
        return self.currentToken;
    }

    fn peekKind(self: *Self) TokenKind {
        const token = self.lexer.peek() catch return TokenKind.EOF;
        return token.kind;
    }

    fn matches(self: *Self, kind: TokenKind) bool {
        return self.currentToken != null and self.currentToken.?.kind == kind;
    }

    // Maybe change this from peeking to looking at the current token.
    fn consume(self: *Self, kind: TokenKind) ParserError!Token {
        if (self.peekKind() != kind) {
            const expected = try colorize(self.allactor, .Green, @tagName(kind));
            const found = try colorize(self.allactor, .Red, @tagName(self.peekKind()));
            print("Expected {s} but got {s}\n", .{ expected, found });
            self.allactor.free(expected);
            self.allactor.free(found);
            return ParserError.UnexpectedToken;
        }
        const token = self.next() orelse unreachable;
        print("{s} -> {s}\n", .{ @tagName(kind), @tagName(self.peekKind()) });
        return token;
    }

    fn function(self: *Self) ParserError!Expr {
        if (!self.matches(TokenKind.Fn)) {
            return self.expression();
        }
        const start = self.currentToken.?.span;

        const name_token = try self.consume(TokenKind.Identifier);

        var params = std.ArrayList([]const u8).init(self.allactor);
        errdefer params.deinit();

        _ = try self.consume(TokenKind.ParenOpen);

        while (self.peekKind() != TokenKind.ParenClose) {
            const token = try self.consume(TokenKind.Identifier);
            params.append(token.lexme) catch return ParserError.OutOfMemory;
            // TODO: Add support for comma
            // _ = try self.consume(TokenKind.Comma);
        }

        _ = try self.consume(TokenKind.ParenClose);

        // TODO: add return type if we add types to the language
        _ = try self.consume(TokenKind.BraceOpen);
        _ = self.next();

        var body = std.ArrayList(Expr).init(self.allactor);
        errdefer params.deinit();
        const stmt: Expr = try self.expression();
        body.append(stmt) catch return ParserError.OutOfMemory;

        const end = try self.consume(TokenKind.BraceClose);

        const span = Span{ .start = start.start, .end = end.span.end, .line = start.line };

        return Expr{ .function = Function{
            .name = name_token.lexme,
            .params = params,
            .body = body,
            .span = span,
        } };
    }

    fn expression(self: *Self) ParserError!Expr {
        return self.call();
    }

    fn call(self: *Self) ParserError!Expr {
        if (!(self.matches(TokenKind.Identifier) and self.peekKind() == TokenKind.ParenOpen)) {
            return self.primary();
        }
        const name = try self.consume(TokenKind.Identifier);
        var args = std.ArrayList(Expr).init(self.allactor);
        errdefer args.deinit();
        _ = try self.consume(TokenKind.ParenOpen);
        while (self.peekKind() != TokenKind.ParenClose) {
            const expr = try self.expression();
            args.append(expr) catch return ParserError.OutOfMemory;

            // TODO: Add support for comma
            // _ = try self.consume(TokenKind.Comma);
        }
        _ = try self.consume(TokenKind.ParenClose);
        const end = try self.consume(TokenKind.Semicolon);
        const span = Span{ .start = name.span.start, .end = end.span.end, .line = name.span.line };
        return Expr{ .call = Call{
            .name = name.lexme,
            .args = args,
            .span = span,
        } };
    }

    fn primary(self: *Self) ParserError!Expr {
        const token = self.currentToken orelse return ParserError.UnexpectedEndOfFile;
        switch (token.kind) {
            TokenKind.Integer => {
                return Expr{ .atom = Atom{ .number = AtomNumber{
                    .value = std.fmt.parseFloat(f64, self.currentToken.?.lexme) catch
                        return ParserError.LexerFailerOnParsingNumbers,
                    .span = self.currentToken.?.span,
                } } };
            },
            TokenKind.String => {
                return Expr{ .atom = Atom{ .string = AtomString{
                    .value = self.currentToken.?.lexme,
                    .span = self.currentToken.?.span,
                } } };
            },
            else => {
                const message = try colorize(self.allactor, .Yellow, "Unexpected token kind: ");
                const found = try colorize(self.allactor, .Red, @tagName(token.kind));
                std.debug.panic("{s}{s}", .{ message, found });
                self.allactor.free(message);
                self.allactor.free(found);
            },
        }
    }
};

fn eof() Token {
    return Token{
        .kind = TokenKind.EOF,
        .lexme = "",
        .span = Span{},
    };
}

pub const ParserError = error{
    UnexpectedToken,
    UnexpectedEndOfFile,
    LexerFailerOnParsingNumbers,
    OutOfMemory,
    BlowingUp,
};

const Color = enum(u8) {
    Black = 30,
    Red = 31,
    Green = 32,
    Yellow = 33,
    Blue = 34,
    Magenta = 35,
    Cyan = 36,
    White = 37,
    // pub fn rgb(r: u8, g: u8, b: u8) []const u8 {
    //     return "\x1b[38;2;{};{};{}m";
    // }
};

fn colorize(allocator: std.mem.Allocator, comptime color: Color, text: []const u8) std.mem.Allocator.Error![]const u8 {
    return try std.fmt.allocPrint(allocator, "\x1b[{d}m{s}\x1b[0m", .{ @intFromEnum(color), text });
}

test "parser primary number" {
    var lexer = Lexer.init(" 123_321   4_3_2_1");
    var parser = Parser.init(testing.allocator, lexer);
    _ = parser.next();
    var primary = try parser.primary();
    switch (primary) {
        .atom => |atom| {
            switch (atom) {
                .number => |a| {
                    try testing.expectEqual(a.value, 123321.0);
                    try testing.expectEqual(a.span.start, 1);
                    try testing.expectEqual(a.span.end, 8);
                    try testing.expectEqual(a.span.line, 0);
                },
                else => return error.FailingTest,
            }
        },
        else => return error.FailingTest,
    }
}

test "parser primary string" {
    var lexer = Lexer.init("\"hello\"");
    var parser = Parser.init(testing.allocator, lexer);
    _ = parser.next();
    var primary = try parser.primary();
    switch (primary) {
        .atom => |atom| {
            switch (atom) {
                .string => |a| {
                    try testing.expectEqual(a.value, "\"hello\"");
                    try testing.expectEqual(a.span.start, 0);
                    try testing.expectEqual(a.span.end, 7);
                    try testing.expectEqual(a.span.line, 0);
                },
                else => return error.FailingTest,
            }
        },
        else => return error.FailingTest,
    }
}

test "parser function parse" {
    var lexer = Lexer.init("fn main() {\n    print(\"Hello World!\n\");\n}");
    var parser = Parser.init(testing.allocator, lexer);
    _ = parser.next();
    var func = try parser.function();

    switch (func) {
        .function => |fun| {
            try testing.expectEqual(fun.name, "main");
            try testing.expectEqual(fun.params.items.len, 0);
            if (fun.body.items.len > 0) {
                try testing.expectEqual(
                    fun.body.items[0],
                    Expr{ .atom = Atom{ .string = AtomString{ .value = "\"Hello World!\"", .span = Span{ .start = 14, .end = 29, .line = 1 } } } },
                );
            } else {
                return ParserError.BlowingUp;
            }
        },
        .call => return ParserError.BlowingUp,
        .atom => return ParserError.BlowingUp,
    }
}
