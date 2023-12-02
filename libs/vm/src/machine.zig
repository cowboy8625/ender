// 1. Fix Compiled Program to account for all the offsets.
// Problem: The offset to the entry point is wrong cause of the header and data size.
// Solution: Add the header and data size to the offset to fix it in compiled code.
const std = @import("std");

pub const OpCodeType = enum {
    //  0.  load %0 %1
    Load,
    //  1.  loadimm %0 123
    LoadImm,
    //  2.  store %0 %1 stores only the first 8 bits of the register
    Storeu8,
    //  3. store %0 %1 stores only the first 16 bits of the register
    Storeu16,
    //  4. store %0 %1 stores all of the register into the heap
    Storeu32,
    //  5. inc %0
    Inc,
    //  6. push %0
    Push,
    //  7. pop %0
    Pop,
    //  8. add %0 %1 %0
    Add,
    //  9. syscall does not take any arguments
    // Exit program          %0 = 0, %1 = 0
    // Wrtie to stdout       %0 = 1, %1 = (string location on heap), %2 = length, %3 = (0 for data, 1 for heap)
    // Wrtie to stderr       %0 = 1, %1 = (string location on heap), %2 = length
    SysCall,
};

const OpCode = struct {
    type: OpCodeType,
    arg1: u8,
    arg2: u8,
    arg3: u8,

    fn decode(rawCode: u32) OpCode {
        return OpCode{
            .type = @as(OpCodeType, @enumFromInt(rawCode >> 24)),
            .arg1 = @as(u8, @truncate(rawCode >> 16)),
            .arg2 = @as(u8, @truncate(rawCode >> 8)),
            .arg3 = @as(u8, @truncate(rawCode >> 0)),
        };
    }

    fn registerFromArg1(self: OpCode) usize {
        return @as(usize, self.arg1);
    }

    fn registerFromArg2(self: OpCode) usize {
        return @as(usize, self.arg2);
    }

    fn registerFromArg3(self: OpCode) usize {
        return @as(usize, self.arg3);
    }

    fn u16FromArg2AndArg3(self: OpCode) u16 {
        return @as(u16, self.arg2) << 8 | @as(u16, self.arg3);
    }
};

pub const Machine = struct {
    program: []const u8,
    ip: usize,
    stack: [1024]u32,
    heap: [1024]u8,
    registers: [32]u32,
    isRunning: bool,
    exitCode: u32,

    const Self = @This();

    pub fn init(program: []const u8) Self {
        return Machine{
            .program = program,
            .ip = 0,
            .stack = [_]u32{0} ** 1024,
            .heap = [_]u8{0} ** 1024,
            .registers = [_]u32{0} ** 32,
            .isRunning = true,
            .exitCode = 0,
        };
    }

    pub fn runOnce(self: *Self, code: OpCodeType) void {
        switch (code) {
            OpCodeType.Load => {
                const reg = self.getNextu8();
                const loc = self.getNextu8();
                _ = self.getNextu8();
                self.load(reg, loc);
            },
            OpCodeType.LoadImm => {
                const reg = self.getNextu8();
                const num = @as(u32, self.getNextu16());
                self.loadImm(reg, num);
            },
            OpCodeType.Storeu8 => {
                const reg1 = self.getNextu8();
                const reg2 = self.getNextu8();
                _ = self.getNextu8();
                self.storeu8(reg1, reg2);
            },
            OpCodeType.Storeu16 => {
                const reg1 = self.getNextu8();
                const reg2 = self.getNextu8();
                _ = self.getNextu8();
                self.storeu16(reg1, reg2);
            },
            OpCodeType.Storeu32 => {
                const reg1 = self.getNextu8();
                const reg2 = self.getNextu8();
                _ = self.getNextu8();
                self.storeu32(reg1, reg2);
            },
            OpCodeType.Add => {
                const lhsReg = @as(usize, self.getNextu8());
                const rhsReg = @as(usize, self.getNextu8());
                const des = self.getNextu8();
                const lhs = self.getRegister(lhsReg);
                const rhs = self.getRegister(rhsReg);
                self.loadImm(des, lhs + rhs);
            },
            OpCodeType.Inc => {
                const reg = self.getNextu8();
                _ = self.getNextu8();
                _ = self.getNextu8();
                self.inc(reg);
            },
            OpCodeType.Push => {
                std.debug.panic("Push not implemented", .{});
            },
            OpCodeType.Pop => {
                std.debug.panic("Pop not implemented", .{});
            },
            OpCodeType.SysCall => {
                _ = self.getNextu8();
                _ = self.getNextu8();
                _ = self.getNextu8();
                self.syscall();
            },
        }
    }

    pub fn run(self: *Self) void {
        self.ip = self.getEntryPoint();
        while (self.isRunning and self.ip < self.program.len) {
            const byte = self.getNextu8();
            const opCodeType = @as(OpCodeType, @enumFromInt(byte));
            self.runOnce(opCodeType);
        }
    }

    fn getMagicNumber(self: *Self) []const u8 {
        return self.program[0..4];
    }

    fn getVersionNumber(self: *Self) usize {
        const bytes = self.program[4..8].*;
        const num = std.mem.readInt(u32, &bytes, .Big);
        return @as(usize, num);
    }

    fn getDataSectionSize(self: *Self) usize {
        const bytes = self.program[8..12].*;
        const num = std.mem.readInt(u32, &bytes, .Big);
        return @as(usize, num);
    }

    fn getTextSectionStart(self: *Self) usize {
        const bytes = self.program[12..16].*;
        const num = std.mem.readInt(u32, &bytes, .Big);
        return @as(usize, num);
    }

    fn getEntryPoint(self: *Self) usize {
        const bytes = self.program[16..20].*;
        const num = std.mem.readInt(u32, &bytes, .Big);
        return @as(usize, num);
    }

    fn getProgramSize(self: *Self) usize {
        const bytes = []const u8{
            self.program[20],
            self.program[21],
            self.program[22],
            self.program[23],
        };
        const size = @as(usize, bytes);
        return size;
    }

    fn getNextu8(self: *Self) u8 {
        const val = self.program[self.ip];
        self.ip += 1;
        return val;
    }

    fn getNextu16(self: *Self) u16 {
        const arg1 = self.getNextu8();
        const arg2 = self.getNextu8();
        return @as(u16, arg1) << 8 | @as(u16, arg2);
    }

    fn print_registers(self: *Self) void {
        std.debug.print("registers: ", .{});
        for (self.registers) |reg| {
            std.debug.print("{d} ", .{reg});
        }
        std.debug.print("\n", .{});
    }

    fn print_heap(self: *Self) void {
        std.debug.print("heap: ", .{});
        for (self.heap) |reg| {
            std.debug.print("{d} ", .{reg});
        }
        std.debug.print("\n", .{});
    }

    fn getRegister(self: *Self, register: usize) u32 {
        return self.registers[register];
    }

    fn storeu8(self: *Self, register: usize, source: usize) void {
        const num = self.registers[source];
        const des = self.registers[register];
        const value = @as(u8, @truncate(num << 0));
        self.heap[des] = value;
    }

    fn storeu16(self: *Self, register: usize, source: usize) void {
        const num = self.registers[source];
        const des = self.registers[register];
        const value1 = @as(u8, @truncate(num << 8));
        self.heap[des + 0] = value1;
        const value2 = @as(u8, @truncate(num << 0));
        self.heap[des + 1] = value2;
    }

    fn storeu32(self: *Self, register: usize, source: usize) void {
        const num = self.registers[source];
        const des = self.registers[register];
        const value1 = @as(u8, @truncate(num << 24));
        self.heap[des + 0] = value1;
        const value2 = @as(u8, @truncate(num << 16));
        self.heap[des + 1] = value2;
        const value3 = @as(u8, @truncate(num << 8));
        self.heap[des + 2] = value3;
        const value4 = @as(u8, @truncate(num << 0));
        self.heap[des + 3] = value4;
    }

    fn load(self: *Self, location: usize, destination: usize) void {
        self.registers[destination] = self.heap[location];
    }

    fn loadImm(self: *Self, register: usize, value: u32) void {
        self.registers[register] = value;
    }

    fn inc(self: *Self, register: usize) void {
        self.registers[register] += 1;
    }

    fn push() void {
        std.debug.panic("Opcode.Push for VM is not implemented", .{});
    }

    fn pop() void {
        std.debug.panic("Opcode.Push for VM is not implemented", .{});
    }

    fn syscall(self: *Self) void {
        const syscallType = self.getRegister(0);
        switch (syscallType) {
            0 => self.syscall_exit(),
            1 => self.syscall_print_stdout(),
            2 => self.syscall_print_stderr(),
            else => unreachable,
        }
    }

    fn syscall_exit(self: *Self) void {
        self.isRunning = false;
        self.exitCode = self.getRegister(1);
    }

    fn syscall_print_stdout(self: *Self) void {
        const start = self.getRegister(1);
        const len = self.getRegister(2);
        const pointerLocation = self.getRegister(3);
        const bytes = if (pointerLocation == 0) self.program[start .. start + len] else self.heap[start .. start + len];
        const stdout = std.io.getStdOut().writer();
        stdout.print("{s}", .{bytes}) catch unreachable;
    }

    fn syscall_print_stderr(_: *Self) void {
        // const start = self.getRegister(reg2);
        // _ = start;
        // const len = self.getRegister(reg3);
        // _ = len;
        // std.io.getStdErr().writer().print("{c}", self.heap[start .. start + len]) catch unreachable;
    }
};

test "load immediate value" {
    const program = [_]u32{
        0x01_01_00_7B, // ensure that register 1 is empty
    };
    var machine = Machine.init(program);
    machine.runOnce();
    try std.testing.expectEqual(@as(u32, 123), machine.getRegister(1));
}

test "hello world" {
    const program = [_]u32{
        0x01_01_00_00, // ensure that register 1 is empty
        0x01_00_00_48, // input 'H' in register 0
        0x02_01_00_00, // put 'H' on heap
        0x05_01_00_00, // increment register 1
        0x01_00_00_65, // input 'e' in register 0
        0x02_01_00_00, // put 'e' on heap
        0x05_01_00_00, // increment register 1
        0x01_00_00_6C, // input 'l' in register 0
        0x02_01_00_00, // put 'l' on heap
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put 'l' on heap
        0x01_00_00_6f, // input 'o' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put 'o' on heap
        0x01_00_00_20, // input ' ' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put ' ' on heap
        0x01_00_00_57, // input 'W' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put 'W' on heap
        0x01_00_00_6f, // input 'o' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put 'o' on heap
        0x01_00_00_72, // input 'r' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put 'r' on heap
        0x01_00_00_6c, // input 'l' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put 'l' on heap
        0x01_00_00_64, // input 'd' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put 'd' on heap
        0x01_00_00_21, // input '!' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put 'd' on heap
        0x01_00_00_0A, // input '\n' in register 0
        0x05_01_00_00, // increment register 1
        0x02_01_00_00, // put '\n' on heap
        0x01_00_00_01, // load register 0 with 1 for a write syscall
        0x01_01_00_00, // load register 1 with the string location
        0x01_02_00_0D, // load 13 into register 2 aka the length of the string
        0x09_00_00_00, // syscall
        0x01_00_00_00, // load register 0 with 0 for a write syscall
        0x01_01_00_0A, // load register 0 with 10 for the exit code
        0x09_00_00_00, // syscall
    };
    var machine = Machine.init(&program);
    machine.run();
    try std.testing.expectEqual(@as(u8, 'H'), machine.heap[0]);
    try std.testing.expectEqual(@as(u8, 'e'), machine.heap[1]);
    try std.testing.expectEqual(@as(u8, 'l'), machine.heap[2]);
    try std.testing.expectEqual(@as(u8, 'l'), machine.heap[3]);
    try std.testing.expectEqual(@as(u8, 'o'), machine.heap[4]);
    try std.testing.expectEqual(@as(u8, ' '), machine.heap[5]);
    try std.testing.expectEqual(@as(u8, 'W'), machine.heap[6]);
    try std.testing.expectEqual(@as(u8, 'o'), machine.heap[7]);
    try std.testing.expectEqual(@as(u8, 'r'), machine.heap[8]);
    try std.testing.expectEqual(@as(u8, 'l'), machine.heap[9]);
    try std.testing.expectEqual(@as(u8, 'd'), machine.heap[10]);
    try std.testing.expectEqual(@as(u8, '!'), machine.heap[11]);
    try std.testing.expectEqual(@as(u8, '\n'), machine.heap[12]);
}
