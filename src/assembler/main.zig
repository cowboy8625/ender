const std = @import("std");
const Allocator = std.mem.Allocator;
const lexer = @import("lexer.zig").lexer;
const parser = @import("parser.zig").parser;
const printInstruction = @import("instruction.zig").printInstruction;
const createSymbolTable = @import("symbol_table.zig").createSymbolTable;
const SymbolTable = @import("symbol_table.zig").SymbolTable;
const Header = @import("header.zig").Header;

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
    defer instructionSet.deinit();
    std.debug.print("{}\n", .{instructionSet.items.len});
    var symbolTable: SymbolTable = try createSymbolTable(allocator, instructionSet);
    defer symbolTable.deinit();
    var iter = symbolTable.table.iterator();
    std.debug.print("programSize: {}\n", .{symbolTable.programSize});
    while (iter.next()) |entry| {
        std.debug.print("key: {s}, value: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    const programSize = @as(u32, @truncate(symbolTable.programSize));
    const textSegment = @as(u32, @truncate(symbolTable.textSegment));
    const dataSegment = @as(u32, @truncate(symbolTable.dataSegment));
    const entryPointName = symbolTable.entryPointName;
    const entryPoint = @as(u32, @truncate(symbolTable.table.get(entryPointName).?));

    // Add programSize to header
    // save header and program to binary
    const header = Header.init(programSize, dataSegment, textSegment, entryPoint);

    const binaryFileName = createBinaryFileName(filePath);
    std.debug.print("filename: {s}\n", .{binaryFileName});

    const binaryFile = try std.fs.cwd().createFile(binaryFileName, .{});
    defer binaryFile.close();
    _ = try binaryFile.write(&header.asBytes());
}

fn createBinaryFileName(filePath: []const u8) []const u8 {
    const delimiter = ".";
    var parts = std.mem.split(u8, filePath, delimiter);
    return parts.next() orelse return "";
}
