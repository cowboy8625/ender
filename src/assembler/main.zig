const std = @import("std");
const Allocator = std.mem.Allocator;
const lexer = @import("lexer.zig").lexer;
const parser = @import("parser.zig").parser;
const printInstruction = @import("instruction.zig").printInstruction;
const createSymbolTable = @import("symbol_table.zig").createSymbolTable;
const SymbolTable = @import("symbol_table.zig").SymbolTable;
const Header = @import("header.zig").Header;
const compile = @import("compiler.zig").compile;

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

    const file = try std.fs.cwd().openFile(filePath, .{});
    defer file.close();
    const fileSize = try file.getEndPos();
    const buffer = try file.readToEndAlloc(allocator, fileSize);
    defer allocator.free(buffer);

    const tokens = try lexer(buffer);
    const instructionSet = try parser(tokens);
    defer instructionSet.deinit();

    var symbolTable: SymbolTable = try createSymbolTable(allocator, instructionSet);
    defer symbolTable.deinit();

    const header = Header.init(&symbolTable);

    try compile(filePath, header, symbolTable, instructionSet);
}
