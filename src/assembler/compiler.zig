const std = @import("std");
const Header = @import("header.zig").Header;
const SymbolTable = @import("symbol_table.zig").SymbolTable;
const InstructionSet = @import("instruction.zig").InstructionSet;
const asBytes = @import("instruction.zig").asBytes;

// Compile will take the program code and the symbol table and replace any identifiers with the corresponding addresses
// and write the result to a file
pub fn compile(filePath: []const u8, header: Header, _: SymbolTable, instructionSet: InstructionSet) !void {
    const Vecu8 = std.ArrayList(u8);
    var program = Vecu8.init(std.heap.page_allocator);
    defer program.deinit();

    for (instructionSet.items) |instruction| {
        const bytes: ?[4]u8 = asBytes(instruction);
        if (bytes) |b| {
            try program.append(b[0]);
            try program.append(b[1]);
            try program.append(b[2]);
            try program.append(b[3]);
        }
    }

    // Writing to file
    const binaryFileName = createBinaryFileName(filePath);
    const binaryFile = try std.fs.cwd().createFile(binaryFileName, .{});
    defer binaryFile.close();
    _ = try binaryFile.write(&header.asBytes());
    _ = try binaryFile.write(program.items);
}

fn createBinaryFileName(filePath: []const u8) []const u8 {
    const delimiter = ".";
    var parts = std.mem.split(u8, filePath, delimiter);
    return parts.next() orelse return "";
}
