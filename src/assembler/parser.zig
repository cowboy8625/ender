const std = @import("std");
const VecToken = @import("lexer.zig").VecToken;
const TT = @import("lexer.zig").TokenType;
const Keyword = @import("lexer.zig").Keyword;
const Token = @import("lexer.zig").Token;

pub const Error = error{
    ExpectedRegister,
    ExpectedNumber,
    ExpectedPercentSign,
};

pub const InstructionSet = std.ArrayList(Instruction);

pub const InstructionType = enum {
    load,
    loadimm,
    storeu8,
    storeu16,
    storeu32,
    inc,
    push,
    pop,
    add,
    syscall,
};

pub const Instruction = union(InstructionType) {
    load: Load,
    loadimm: LoadImm,
    storeu8: Storeu8,
    storeu16: Storeu16,
    storeu32: Storeu32,
    inc: Increment,
    push: Push,
    pop: Pop,
    add: Add,
    syscall: SysCall,
};

pub const Register = u8;

pub const Load = struct {
    loc: Register,
    des: Register,
};

pub const LoadImm = struct {
    des: Register,
    num: u32,
};

pub const Storeu8 = struct {
    des: Register,
    src: Register,
};

pub const Storeu16 = struct {
    des: Register,
    src: Register,
};

pub const Storeu32 = struct {
    des: Register,
    src: Register,
};

pub const Increment = struct {
    src: Register,
};

pub const Push = struct {
    src: Register,
};

pub const Pop = struct {
    des: Register,
};

pub const Add = struct {
    lhs: Register,
    rhs: Register,
    des: Register,
};

pub const SysCall = struct {};

pub fn parser(tokens: VecToken) !InstructionSet {
    var instructionSet = InstructionSet.init(std.heap.page_allocator);
    var ip: usize = 0;
    while (ip < tokens.items.len) {
        switch (tokens.items[ip].kind) {
            TT.Keyword => try keyword(&ip, tokens, &instructionSet),
            // else => unreachable,
            else => {
                std.debug.print("{d}: {s}\n", .{ ip, tokens.items[ip].lexme });
                ip += 1;
            },
        }
    }
    return instructionSet;
}

fn keyword(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const token = tokens.items[ip.*];
    ip.* += 1;
    switch (token.keyword().?) {
        Keyword.Load => try load(ip, tokens, instructionSet),
        Keyword.LoadImm => try loadimm(ip, tokens, instructionSet),
        Keyword.Storeu8 => try storeu8(ip, tokens, instructionSet),
        Keyword.Storeu16 => try storeu16(ip, tokens, instructionSet),
        Keyword.Storeu32 => try storeu32(ip, tokens, instructionSet),
        Keyword.Inc => try inc(ip, tokens, instructionSet),
        Keyword.Push => try push(ip, tokens, instructionSet),
        Keyword.Pop => try pop(ip, tokens, instructionSet),
        Keyword.Add => try add(ip, tokens, instructionSet),
        Keyword.SysCall => try syscall(ip, tokens, instructionSet),
    }
}

fn nextIf(ip: *usize, tokens: VecToken, func: *const fn (*const Token) bool) ?Token {
    const token = tokens.items[ip.*];
    if (func(&token)) {
        ip.* += 1;
        return token;
    }
    return null;
}

fn isPercent(t: *const Token) bool {
    return t.kind == TT.PercentSign;
}

fn isNumber(t: *const Token) bool {
    return t.kind == TT.Number;
}

fn parseRegister(ip: *usize, tokens: VecToken) !Register {
    _ = nextIf(ip, tokens, isPercent) orelse return Error.ExpectedPercentSign;
    const token = nextIf(ip, tokens, isNumber) orelse return Error.ExpectedNumber;
    return try std.fmt.parseInt(u8, token.lexme, 10);
}

fn load(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const loc = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const des = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const instruction = Instruction{ .load = Load{
        .loc = loc,
        .des = des,
    } };
    try instructionSet.append(instruction);
}

fn loadimm(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const des = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const num = std.fmt.parseInt(u32, tokens.items[ip.*].lexme, 10) catch return Error.ExpectedNumber;
    const instruction = Instruction{ .loadimm = LoadImm{
        .des = des,
        .num = num,
    } };
    try instructionSet.append(instruction);
}

fn storeu8(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const des = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const src = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const instruction = Instruction{ .storeu8 = Storeu8{
        .des = des,
        .src = src,
    } };
    try instructionSet.append(instruction);
}

fn storeu16(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const des = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const src = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const instruction = Instruction{ .storeu16 = Storeu16{
        .des = des,
        .src = src,
    } };
    try instructionSet.append(instruction);
}

fn storeu32(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const des = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const src = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const instruction = Instruction{ .storeu32 = Storeu32{
        .des = des,
        .src = src,
    } };
    try instructionSet.append(instruction);
}

fn inc(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const src = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const instruction = Instruction{ .inc = Increment{
        .src = src,
    } };
    try instructionSet.append(instruction);
}

fn push(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const src = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const instruction = Instruction{ .push = Push{
        .src = src,
    } };
    try instructionSet.append(instruction);
}

fn pop(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const des = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const instruction = Instruction{ .pop = Pop{
        .des = des,
    } };
    try instructionSet.append(instruction);
}

fn add(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const lhs = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const rhs = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const des = parseRegister(ip, tokens) catch return Error.ExpectedRegister;
    const instruction = Instruction{ .add = Add{
        .lhs = lhs,
        .rhs = rhs,
        .des = des,
    } };
    try instructionSet.append(instruction);
}

fn syscall(ip: *usize, _: VecToken, instructionSet: *InstructionSet) !void {
    ip.* += 1;
    const instruction = Instruction{ .syscall = SysCall{} };
    try instructionSet.append(instruction);
}
