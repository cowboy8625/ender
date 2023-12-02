const std = @import("std");
const VecToken = @import("lexer.zig").VecToken;
const TT = @import("lexer.zig").TokenType;
const Keyword = @import("lexer.zig").Keyword;
const Token = @import("lexer.zig").Token;

const Register = @import("instruction.zig").Register;
const Label = @import("instruction.zig").Label;
const Load = @import("instruction.zig").Load;
const LoadImm = @import("instruction.zig").LoadImm;
const Storeu8 = @import("instruction.zig").Storeu8;
const Storeu16 = @import("instruction.zig").Storeu16;
const Storeu32 = @import("instruction.zig").Storeu32;
const Increment = @import("instruction.zig").Increment;
const Push = @import("instruction.zig").Push;
const Pop = @import("instruction.zig").Pop;
const Add = @import("instruction.zig").Add;
const SysCall = @import("instruction.zig").SysCall;
const Instruction = @import("instruction.zig").Instruction;
const InstructionType = @import("instruction.zig").InstructionType;
const InstructionSet = @import("instruction.zig").InstructionSet;
const Directive = @import("directive.zig").Directive;
const Text = @import("directive.zig").Text;
const Data = @import("directive.zig").Data;
const Entry = @import("directive.zig").Entry;

pub const Error = error{
    ExpectedRegister,
    ExpectedNumber,
    ExpectedPercentSign,
    ExpectedIdentifier,
    ExpectedColon,
    ExpectedDirective,
};
pub fn parser(tokens: VecToken) !InstructionSet {
    var instructionSet = InstructionSet.init(std.heap.page_allocator);
    var ip: usize = 0;
    while (ip < tokens.items.len) {
        const kind = tokens.items[ip].kind;
        if (kind == TT.Keyword) {
            try keyword(&ip, tokens, &instructionSet);
            continue;
        } else if (kind == TT.Identifier and isNextToken(ip, tokens, TT.Colon)) {
            const nameToken = nextIf(&ip, tokens, TT.Identifier) orelse return Error.ExpectedIdentifier;
            _ = nextIf(&ip, tokens, TT.Colon) orelse return Error.ExpectedColon;
            const instruction = Instruction{ .label = Label{
                .name = nameToken.lexme,
            } };
            try instructionSet.append(instruction);
            continue;
        } else if (kind == TT.Dot) {
            ip += 1;
            try directive(&ip, tokens, &instructionSet);
            continue;
        }

        std.debug.print("error {d}: {s} {} {s}\n", .{ ip, tokens.items[ip].lexme, tokens.items[ip].kind, tokens.items[ip].lexme });
        // for (tokens.items) |t| {
        //     std.debug.print("{d}: {s} {}\n", .{ ip, t.lexme, t.kind });
        // }
        break;
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

fn peek(ip: usize, tokens: VecToken, expected: TT) ?Token {
    const token = tokens.items[ip + 1];
    if (token.kind == expected) {
        return token;
    }
    return null;
}

fn nextIf(ip: *usize, tokens: VecToken, expected: TT) ?Token {
    const token = tokens.items[ip.*];
    if (token.kind == expected) {
        ip.* += 1;
        return token;
    }
    return null;
}

fn isNextToken(ip: usize, tokens: VecToken, kind: TT) bool {
    _ = peek(ip, tokens, kind) orelse return false;
    return true;
}

fn parseRegister(ip: *usize, tokens: VecToken) !Register {
    _ = nextIf(ip, tokens, TT.PercentSign) orelse return Error.ExpectedPercentSign;
    const token = nextIf(ip, tokens, TT.Number) orelse return Error.ExpectedNumber;
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
    const numToken = nextIf(ip, tokens, TT.Number) orelse return Error.ExpectedNumber;
    const num = try std.fmt.parseInt(u32, numToken.lexme, 10);
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

fn syscall(_: *usize, _: VecToken, instructionSet: *InstructionSet) !void {
    const instruction = Instruction{ .syscall = SysCall{} };
    try instructionSet.append(instruction);
}

fn directive(ip: *usize, tokens: VecToken, instructionSet: *InstructionSet) !void {
    const directiveToken = nextIf(ip, tokens, TT.Identifier) orelse return Error.ExpectedIdentifier;
    const lexme = directiveToken.lexme;
    if (std.mem.eql(u8, lexme, "text")) {
        const dir = Instruction{ .directive = Directive{ .text = Text{} } };
        try instructionSet.append(dir);
        return;
    } else if (std.mem.eql(u8, lexme, "data")) {
        const dir = Instruction{ .directive = Directive{ .data = Data{} } };
        try instructionSet.append(dir);
        return;
    } else if (std.mem.eql(u8, lexme, "entry")) {
        const token = nextIf(ip, tokens, TT.Identifier) orelse return Error.ExpectedIdentifier;
        const dir = Instruction{ .directive = Directive{ .entry = Entry{
            .name = token.lexme,
        } } };
        try instructionSet.append(dir);
        return;
    }

    return Error.ExpectedDirective;
}
