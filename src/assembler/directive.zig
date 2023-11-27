const std = @import("std");

pub const DirectiveType = enum {
    text,
    data,
    entry,
};

pub const Directive = union(DirectiveType) {
    text: Text,
    data: Data,
    entry: Entry,
    // TODO: add more
    // .data
    // .ascii
    // .length
};

pub fn printDirective(directive: Directive) void {
    switch (directive) {
        DirectiveType.text => |t| {
            std.debug.print("{}\n", .{t});
        },
        DirectiveType.data => |d| {
            std.debug.print("{}\n", .{d});
        },
        DirectiveType.entry => |e| {
            std.debug.print("{}\n", .{e});
        },
    }
}

pub const Text = struct {
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, ".text", .{});
    }
};

pub const Data = struct {
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, ".data", .{});
    }
};

pub const Entry = struct {
    name: []const u8,

    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        try std.fmt.format(out_stream, ".entry {s}", .{self.name});
    }
};
