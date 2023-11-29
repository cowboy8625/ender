const std = @import("std");
const Header = @import("header.zig").Header;
const SymbolTable = @import("symbol_table.zig").SymbolTable;
const InstructionSet = @import("instruction.zig").InstructionSet;
const asBytes = @import("instruction.zig").asBytes;
const Allocator = std.mem.Allocator;
const lexer = @import("lexer.zig").lexer;
const parser = @import("parser.zig").parser;
const printInstruction = @import("instruction.zig").printInstruction;
const createSymbolTable = @import("symbol_table.zig").createSymbolTable;
pub const Program = std.ArrayList(u8);

pub fn compile(allocator: Allocator, filePath: []const u8) !Program {
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

    var program = try compileProgram(&header, &symbolTable, &instructionSet);
    for (0.., header.asBytes()) |idx, byte| {
        try program.insert(idx, byte);
    }

    return program;
}

// Compile will take the program code and the symbol table and replace any identifiers with the corresponding addresses
// and write the result to a file
pub fn compileProgram(header: *const Header, _: *const SymbolTable, instructionSet: *const InstructionSet) !Program {
    _ = header;
    var program = Program.init(std.heap.page_allocator);

    for (instructionSet.items) |instruction| {
        const bytes: ?[4]u8 = asBytes(&instruction);
        if (bytes) |b| {
            try program.append(b[0]);
            try program.append(b[1]);
            try program.append(b[2]);
            try program.append(b[3]);
        }
    }
    return program;
}
