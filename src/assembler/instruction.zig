const std = @import("std");
const Directive = @import("directive.zig").Directive;
const printDirective = @import("directive.zig").printDirective;

pub const InstructionSet = std.ArrayList(Instruction);

pub const InstructionType = enum {
    directive,
    label,
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
    directive: Directive,
    label: Label,
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

pub fn printInstruction(instruction: Instruction) void {
    switch (instruction) {
        InstructionType.directive => |i| {
            printDirective(i);
        },
        InstructionType.label => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.load => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.loadimm => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.storeu8 => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.storeu16 => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.storeu32 => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.inc => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.push => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.pop => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.add => |i| {
            std.debug.print("{}\n", .{i});
        },
        InstructionType.syscall => |i| {
            std.debug.print("{}\n", .{i});
        },
    }
}

pub const Register = u8;

pub const Label = struct {
    name: []const u8,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "{s}:", .{self.name});
    }
};

pub const Load = struct {
    loc: Register,
    des: Register,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "load     %{d}    %{d}", .{ self.loc, self.des });
    }
};

pub const LoadImm = struct {
    des: Register,
    num: u32,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "loadimm  %{d}    {d}", .{ self.des, self.num });
    }
};

pub const Storeu8 = struct {
    des: Register,
    src: Register,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "storeu8  %{d}    {d}", .{ self.des, self.src });
    }
};

pub const Storeu16 = struct {
    des: Register,
    src: Register,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "storeu16 %{d}    {d}", .{ self.des, self.src });
    }
};

pub const Storeu32 = struct {
    des: Register,
    src: Register,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "storeu32 %{d}    {d}", .{ self.des, self.src });
    }
};

pub const Increment = struct {
    src: Register,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "inc      %{d}", .{self.src});
    }
};

pub const Push = struct {
    src: Register,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "push     %{d}", .{self.src});
    }
};

pub const Pop = struct {
    des: Register,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "pop      %{d}", .{self.des});
    }
};

pub const Add = struct {
    lhs: Register,
    rhs: Register,
    des: Register,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "add      %{d}    %{d}    %{d}", .{ self.lhs, self.rhs, self.des });
    }
};

pub const SysCall = struct {
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, "syscall", .{});
    }
};
