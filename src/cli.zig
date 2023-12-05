const std = @import("std");

const VecUsize = std.ArrayList(usize);

pub const Command = struct {
    name: []const u8,
    help: []const u8,
    args: []const Arg,
};

pub const Arg = struct {
    name: []const u8,
    short: ?u8,
    long: ?[]const u8,
    help: []const u8,
    hasValue: bool = true,
    required: bool = false,
    action: fn () anyerror!void,
};

pub const App = struct {
    name: []const u8,
    commands: []const Command,
    args: []const Arg,
};

pub fn cli(allocator: std.mem.Allocator, comptime app: App) !void {
    std.debug.print("app name: {s}\n", .{app.name});
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    for (args) |arg| {
        std.debug.print("{s}\n", .{arg});
    }
}
