const std = @import("std");
const print = std.debug.print;

const Error = error{
    CannotPop,
    StackUnderflow,
    InvalidNumber,
};

const Op = enum {
    Add,
    Number,
    Print,
    fn format(self: Op, comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.Writer) !void {
        switch (self) {
            .Add => writer.writeAll("Add"),
            .Number => writer.writeAll("Number"),
        }
    }
};

const Token = struct {
    op: Op,
    lexme: []const u8,
    fn format(self: Op, comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.Writer) !void {
        writer.writeAll("Token(op: {s}, lexme: {s})", .{ @tagName(self.op), self.lexme });
    }
};

fn number(ip: *usize, buf: []const u8) ![]const u8 {
    const String = std.ArrayList(u8);
    var string: String = String.init(std.heap.page_allocator);
    while (std.ascii.isDigit(buf[ip.*])) {
        try string.append(buf[ip.*]);
        ip.* += 1;
    }
    ip.* -= 1;
    return string.items;
}

fn identifier(ip: *usize, buf: []const u8) ![]const u8 {
    const String = std.ArrayList(u8);
    var string: String = String.init(std.heap.page_allocator);
    while (std.ascii.isAlphanumeric(buf[ip.*])) {
        try string.append(buf[ip.*]);
        ip.* += 1;
    }
    ip.* -= 1;
    return string.items;
}

fn parser(src: []const u8) !std.ArrayList(Token) {
    var ip: usize = 0;

    const VecToken = std.ArrayList(Token);
    var tokens: VecToken = VecToken.init(std.heap.page_allocator);

    while (ip < src.len) {
        switch (src[ip]) {
            '0'...'9' => {
                const result = try number(&ip, src);
                ip += 1;
                try tokens.append(Token{ .op = .Number, .lexme = result });
            },
            'a'...'z', 'A'...'Z', '_' => {
                // Currently identifys any identifier as a print operation
                const result = try identifier(&ip, src);
                ip += 1;
                try tokens.append(Token{ .op = .Print, .lexme = result });
            },
            '+' => {
                try tokens.append(Token{ .op = .Add, .lexme = "+" });
                ip += 1;
            },
            ' ' => ip += 1,
            '\n' => ip += 1,
            else => {
                print("error: '{c}'\n", .{src[ip]});
                break;
            },
        }
    }
    return tokens;
}

fn eval(tokens: []const Token) !void {
    const Stack = std.ArrayList(u64);
    var stack: Stack = Stack.init(std.heap.page_allocator);
    for (tokens) |token| {
        switch (token.op) {
            .Add => {
                if (stack.items.len < 2) {
                    return Error.StackUnderflow;
                }
                var lhs = stack.pop();
                var rhs = stack.pop();
                try stack.append(lhs + rhs);
            },
            .Number => {
                var num = try std.fmt.parseInt(u64, token.lexme, 10);
                try stack.append(num);
            },
            .Print => {
                if (stack.items.len < 1) {
                    return Error.StackUnderflow;
                }
                var item = stack.pop();
                print("{d}", .{item});
            },
        }
    }
}

pub fn main() !void {
    print(">> ", .{});
    const reader = std.io.getStdIn().reader();
    // const writer = std.io.getStdIn().writer();
    var buf: [1024]u8 = undefined;
    const len = try reader.read(&buf);
    const tokens = try parser(buf[0..len]);
    try eval(tokens.items);
    print("\n", .{});
}
