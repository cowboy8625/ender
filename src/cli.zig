const std = @import("std");

const VecUsize = std.ArrayList(usize);

const Command = struct {
    name: []const u8,
    help: []const u8,
    args: []const Arg,
};

const Arg = struct {
    name: []const u8,
    short: ?u8,
    long: ?[]const u8,
    help: []const u8,
    hasValue: bool,
    required: bool,
    action: fn () anyerror!void,
};

const App = struct {
    name: []const u8,
    commands: []const Command,
    args: []const Arg,
};

const CliApp = struct {
    allocator: std.mem.Allocator,
    app: App,
    args: VecUsize,
    commands: VecUsize,

    fn init(app: App, allocator: std.mem.Allocator) CliApp {
        return CliApp{
            .app = app,
            .allocator = allocator,
        };
    }

    fn hasArg(self: CliApp, longName: []const u8, shortName: ?u8) !bool {
        for (0.., self.app.args) |i, arg| {
            const long = try std.fmt.allocPrint(
                self.allocator,
                "--{s}",
                .{longName},
            );
            defer self.allocator.free(long);
            const short = try std.fmt.allocPrint(
                self.allocator,
                "-{s}",
                .{shortName},
            );
            defer self.allocator.free(short);
            if (std.mem.eql(u8, arg, long)) {
                try self.args.append(i);
                return true;
            } else if (std.mem.eql(u8, arg, short)) {
                try self.args.append(i);
                return true;
            }
        }
    }
};

fn cli(app: App, allocator: std.mem.Allocator) !void {
    const cliApp = CliApp.init(app, allacator);
    _ = app;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    for (args) |arg| {
        if (std.mem.eql(
            u8,
            arg,
        )) {}
    }
}
