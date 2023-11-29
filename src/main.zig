const VERSION = "0.0.1";
const std = @import("std");
const assember = @import("assembler/compiler.zig").compile;
const vm = @import("vm/machine.zig");
// const print = std.debug.print;
//
// const Stack = std.ArrayList(u64);
//
// const Error = error{
//     CannotPop,
//     StackUnderflow,
//     InvalidNumber,
// };
//
// const Op = enum {
//     Add,
//     Number,
//     Print,
// };
//
// const ReplCommand = enum {
//     Exit,
//     Help,
//     ShowStack,
// };
//
// const Token = struct {
//     op: Op,
//     lexme: []const u8,
//     fn format(self: Token, comptime _: []const u8, _: std.fmt.FormatOptions, writer: std.io.Writer) !void {
//         writer.writeAll("Token(op: {s}, lexme: {s})", .{ @tagName(self.op), self.lexme });
//     }
// };
//
// fn number(ip: *usize, buf: []const u8) ![]const u8 {
//     const String = std.ArrayList(u8);
//     var string: String = String.init(std.heap.page_allocator);
//     while (std.ascii.isDigit(buf[ip.*])) {
//         try string.append(buf[ip.*]);
//         ip.* += 1;
//     }
//     ip.* -= 1;
//     return string.items;
// }
//
// fn identifier(ip: *usize, buf: []const u8) ![]const u8 {
//     const String = std.ArrayList(u8);
//     var string: String = String.init(std.heap.page_allocator);
//     while (std.ascii.isAlphanumeric(buf[ip.*])) {
//         try string.append(buf[ip.*]);
//         ip.* += 1;
//     }
//     ip.* -= 1;
//     return string.items;
// }
//
// fn peek(ip: usize, buf: []const u8) ?u8 {
//     if (ip < buf.len) {
//         return buf[ip];
//     } else {
//         return null;
//     }
// }
//
// fn parser(src: []const u8) !std.ArrayList(Token) {
//     var ip: usize = 0;
//
//     const VecToken = std.ArrayList(Token);
//     var tokens: VecToken = VecToken.init(std.heap.page_allocator);
//
//     while (ip < src.len) {
//         if (std.ascii.isDigit(src[ip])) {
//             const result = try number(&ip, src);
//             ip += 1;
//             try tokens.append(Token{ .op = .Number, .lexme = result });
//         } else if (std.ascii.isAlphabetic(src[ip]) or src[ip] == '_') {
//             // Currently identifys any identifier as a print operation
//             const result = try identifier(&ip, src);
//             ip += 1;
//             try tokens.append(Token{ .op = .Print, .lexme = result });
//         } else if (src[ip] == '+') {
//             try tokens.append(Token{ .op = .Add, .lexme = "+" });
//             ip += 1;
//         } else if (std.ascii.isWhitespace(src[ip])) {
//             ip += 1;
//         } else {
//             print("error: '{c}'\n", .{src[ip]});
//             break;
//         }
//     }
//     return tokens;
// }
//
// fn eval(tokens: []const Token, stack: *Stack) !void {
//     for (tokens) |token| {
//         switch (token.op) {
//             .Add => {
//                 if (stack.items.len < 2) {
//                     return Error.StackUnderflow;
//                 }
//                 var lhs = stack.pop();
//                 var rhs = stack.pop();
//                 try stack.append(lhs + rhs);
//             },
//             .Number => {
//                 var num = try std.fmt.parseInt(u64, token.lexme, 10);
//                 try stack.append(num);
//             },
//             .Print => {
//                 if (stack.items.len < 1) {
//                     return Error.StackUnderflow;
//                 }
//                 var item = stack.pop();
//                 print("{d}", .{item});
//             },
//         }
//     }
// }
//
// fn parseForCommand(src: []const u8) ?ReplCommand {
//     const input = std.mem.trim(u8, src, "\n");
//     if (std.mem.eql(u8, input, ":exit")) {
//         return ReplCommand.Exit;
//     } else if (std.mem.eql(u8, input, ":help")) {
//         return ReplCommand.Help;
//     } else if (std.mem.eql(u8, input, ":stack")) {
//         return ReplCommand.ShowStack;
//     }
//     return null;
// }
//
// fn runCommand(src: []const u8, len: usize, isRunning: *bool, stack: *Stack) !bool {
//     _ = stack;
//     const command = parseForCommand(src[0..len]) orelse return false;
//     switch (command) {
//         .Exit => {
//             isRunning.* = false;
//         },
//         .Help => {
//             print("Commands:\n", .{});
//             print("  :exit         exits the repl\n", .{});
//             print("  :help         shows this help\n", .{});
//         },
//         .ShowStack => {
//             // print("Stack:\n", .{});
//             // for (stack.items) |item| {
//             //     try std.fmt.formatInt(item, 2, .lower, .{ .width = 64, .fill = '0' }, std.io.getStdIn().writer());
//             // }
//         },
//     }
//     return true;
// }
//
// fn repl() !void {
//     const reader = std.io.getStdIn().reader();
//     var stack: Stack = Stack.init(std.heap.page_allocator);
//     var isRunning = true;
//     while (isRunning) {
//         print(">> ", .{});
//         var buf: [1024]u8 = undefined;
//         const len = try reader.read(&buf);
//         const hasCommand = try runCommand(buf[0..len], len, &isRunning, &stack);
//         if (hasCommand) {
//             continue;
//         }
//         const tokens = try parser(buf[0..len]);
//         try eval(tokens.items, &stack);
//         print("\n", .{});
//     }
// }

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        std.debug.print("Usage: {s} <filename>\n", .{args[0]});
        std.debug.print("    expected a filename\n", .{});
        return;
    }
    const filePath = args[1];
    std.debug.print("Compiling {s}...\n", .{filePath});

    const program = try assember(allocator, filePath);
    defer program.deinit();

    // var row: usize = 0;
    // for (1.., program.items) |i, b| {
    //     if (i % 4 == 1) {
    //         std.debug.print("{d} - ", .{row});
    //     }
    //     if (i != 0 and i % 4 == 0) {
    //         const bytes = [4]u8{
    //             program.items[(row * 4) + 0],
    //             program.items[(row * 4) + 1],
    //             program.items[(row * 4) + 2],
    //             program.items[(row * 4) + 3],
    //         };
    //         const num = std.mem.readInt(u32, &bytes, .Big);
    //         std.debug.print("{x:0>2} - {d}\n", .{ b, num });
    //         row += 1;
    //         continue;
    //     }
    //     std.debug.print("{x:0>2} ", .{b});
    // }

    var machine = vm.Machine.init(program.items);
    machine.run();
}
