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
    const Self = @This();
    number: AtomNumber,
    string: AtomString,
    pub fn isA(self: *Self, t: std.meta.Tag(Self)) bool {
        switch (self.*) {
            .number => if (t == .number) {
                return true;
            },
            .string => if (t == .string) {
                return true;
            },
        }

        return false;
    }
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
    const Self = @This();
    atom: Atom,
    call: Call,
    function: Function,
    pub fn isAtomA(self: *Self, t: std.meta.Tag(Atom)) bool {
        switch (self.*) {
            .atom => |a| {
                return a.isA(t);
            },
            else => return false,
        }
    }

    pub fn isA(self: *Self, t: std.meta.Tag(Self)) bool {
        switch (self.*) {
            .atom => if (t == .atom) {
                return true;
            },
            .call => if (t == .call) {
                return true;
            },
            .function => if (t == .function) {
                return true;
            },
        }

        return false;
    }
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

    pub fn parse(self: *Self) ParserError!std.ArrayList(Expr) {
        var exprs = std.ArrayList(Expr).init(self.allactor);
        errdefer exprs.deinit();
        while (self.next() != null) {
            exprs.append(self.function()) catch return ParserError.BlowingUp;
        }

        return exprs;
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
        std.debug.print("consume {s}: {}\n", .{ @tagName(kind), !self.matches(kind) });
        if (!self.matches(kind)) {
            const expected = try colorize(self.allactor, .Green, @tagName(kind));
            const found = try colorize(self.allactor, .Red, @tagName(self.currentToken.?.kind));
            const nextToken = try colorize(self.allactor, .Red, @tagName(self.peekKind()));
            print("Expected {s} but got {s} and next {s}\n", .{ expected, found, nextToken });
            self.allactor.free(expected);
            self.allactor.free(found);
            return ParserError.UnexpectedToken;
        }
        const token = self.next() orelse unreachable;
        // print("{s} -> {s}\n", .{ @tagName(kind), @tagName(self.peekKind()) });
        return token;
    }

    fn function(self: *Self) ParserError!Expr {
        const start = self.consume(TokenKind.Fn) catch return self.expression();

        const name_token = try self.consume(TokenKind.Identifier);

        var params = std.ArrayList([]const u8).init(self.allactor);
        errdefer params.deinit();

        _ = try self.consume(TokenKind.ParenOpen);

        while (!self.matches(TokenKind.ParenClose)) {
            const token = try self.consume(TokenKind.Identifier);
            params.append(token.lexme) catch return ParserError.OutOfMemory;
            // TODO: Add support for comma
            // _ = try self.consume(TokenKind.Comma);
        }

        // const message = try colorize(self.allactor, .Green, "function params");
        // const kind = try colorize(self.allactor, .Red, @tagName(self.currentToken.?.kind));
        // std.debug.print("{s}: {s} -> {}\n", .{ message, kind, self.matches(TokenKind.ParenClose) });
        // self.allactor.free(message);
        // self.allactor.free(kind);
        _ = try self.consume(TokenKind.ParenClose);

        // TODO: add return type if we add types to the language
        _ = try self.consume(TokenKind.BraceOpen);

        var body = std.ArrayList(Expr).init(self.allactor);
        errdefer params.deinit();
        const stmt: Expr = try self.expression();
        body.append(stmt) catch return ParserError.OutOfMemory;

        const end = try self.consume(TokenKind.BraceClose);

        const span = Span{ .start = start.span.start, .end = end.span.end, .line = start.span.line };

        return Expr{ .function = Function{
            .name = name_token.lexme,
            .params = params,
            .body = body,
            .span = span,
        } };
    }

    fn expression(self: *Self) ParserError!Expr {
        return try self.call();
    }

    fn call(self: *Self) ParserError!Expr {
        if (!(self.matches(TokenKind.Identifier) and self.peekKind() == TokenKind.ParenOpen)) {
            return self.primary();
        }
        const name = try self.consume(TokenKind.Identifier);
        var args = std.ArrayList(Expr).init(self.allactor);
        errdefer args.deinit();
        _ = try self.consume(TokenKind.ParenOpen);
        while (!self.matches(TokenKind.ParenClose)) {
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
                _ = self.next();
                return Expr{ .atom = Atom{ .number = AtomNumber{
                    .value = std.fmt.parseFloat(f64, self.currentToken.?.lexme) catch
                        return ParserError.LexerFailerOnParsingNumbers,
                    .span = self.currentToken.?.span,
                } } };
            },
            TokenKind.String => {
                _ = self.next();
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
    try testing.expect(func.isA(.function));
    // try testing.expectEqualDeep(func.function.name, "main");
    // try testing.expectEqualDeep(func.function.params.items.len, 0);
    // try testing.expect(func.function.body.items[0].isA(.call));
    // try testing.expect(func.function.body.items[0].atom.isA(.string));
    // try testing.expectEqualDeep(func.function.body.items[0].atom.string.span.start, 14);
    // try testing.expectEqualDeep(func.function.body.items[0].atom.string.span.end, 29);
    // try testing.expectEqualDeep(func.function.body.items[0].atom.string.span.line, 1);
}
