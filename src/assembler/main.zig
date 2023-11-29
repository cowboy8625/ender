const std = @import("std");
const compile = @import("compiler.zig").compile;
const Program = @import("compiler.zig").Program;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        std.debug.print("Usage: {s} <filename>\n", .{args[0]});
        std.debug.print("    expected a filename\n", .{});
        return;
    }
    const filePath = args[1];

    const program = try compile(allocator, filePath);
    defer program.deinit();

    for (1.., program.items) |i, b| {
        if (i != 0 and i % 4 == 0) {
            std.debug.print("{x:0>2}\n", .{b});
            continue;
        }
        std.debug.print("{x:0>2} ", .{b});
    }
    // Writing to file
    const binaryFileName = createBinaryFileName(filePath);
    const binaryFile = try std.fs.cwd().createFile(binaryFileName, .{});
    defer binaryFile.close();
    _ = try binaryFile.write(program.items);
}

fn createBinaryFileName(filePath: []const u8) []const u8 {
    const delimiter = ".";
    var parts = std.mem.split(u8, filePath, delimiter);
    return parts.next() orelse return "";
}
