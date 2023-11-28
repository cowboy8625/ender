const std = @import("std");
const Allocator = std.mem.Allocator;
const InstructionSet = @import("instruction.zig").InstructionSet;
const Instruction = @import("instruction.zig").Instruction;
const IT = @import("instruction.zig").InstructionType;
const Directive = @import("directive.zig").Directive;
const DT = @import("directive.zig").DirectiveType;
const Text = @import("directive.zig").Text;
pub const HashMap = std.StringHashMap(usize);

const Error = error{
    EntryAlreadySet,
};

pub const SymbolTable = struct {
    const Self = @This();
    const headerSize: usize = 64;
    entryPointName: []const u8,
    programSize: usize,
    textSegment: usize,
    dataSegment: usize,
    table: HashMap,
    allocator: Allocator,

    pub fn init(allocator: Allocator, table: HashMap, entryPointName: []const u8, programSize: usize, textSegment: usize, dataSegment: usize) SymbolTable {
        return SymbolTable{
            .allocator = allocator,
            .table = table,
            .entryPointName = entryPointName,
            .programSize = programSize,
            .textSegment = textSegment,
            .dataSegment = dataSegment,
        };
    }

    pub fn deinit(self: *Self) void {
        self.table.deinit();
    }
};

pub fn createSymbolTable(allocator: Allocator, instructions: InstructionSet) !SymbolTable {
    var entryPointName: ?[]const u8 = null;
    var dataSegment: usize = 0;
    var textSegment: usize = 0;
    var programCounter: usize = 0;
    var ip: usize = 0;

    var table: HashMap = HashMap.init(allocator);
    while (ip < instructions.items.len) {
        const instruction = instructions.items[ip];
        switch (instruction) {
            IT.directive => |it| {
                switch (it) {
                    Directive.text => |_| {
                        textSegment = programCounter;
                    },
                    Directive.data => |_| {
                        dataSegment = programCounter;
                    },
                    Directive.entry => |dt| {
                        std.debug.print("entry: {s} at {x}\n", .{ dt.name, ip });
                        if (entryPointName != null) {
                            return error.EntryAlreadySet;
                        }
                        entryPointName = dt.name;
                    },
                }
            },
            IT.label => |it| {
                try table.put(it.name, programCounter);
            },
            else => {
                programCounter += 4;
            },
        }
        ip += 1;
    }
    return SymbolTable.init(allocator, table, entryPointName.?, programCounter, textSegment, dataSegment);
}
