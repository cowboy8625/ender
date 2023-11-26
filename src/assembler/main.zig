const std = @import("std");
const lexer = @import("lexer.zig").lexer;
const parser = @import("parser.zig").parser;

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
    std.debug.print("{s}\n", .{filePath});

    const file = try std.fs.cwd().openFile(filePath, .{});
    defer file.close();
    const fileSize = try file.getEndPos();
    const buffer = try file.readToEndAlloc(allocator, fileSize);
    defer allocator.free(buffer);

    const tokens = try lexer(buffer);
    const instructionSet = try parser(tokens);
    std.debug.print("{}\n", .{instructionSet.items.len});
    for (instructionSet.items) |instruction| {
        std.debug.print("{}\n", .{instruction});
    }
}
