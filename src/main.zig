const VERSION = "0.0.1";
const std = @import("std");
const assember = @import("assembler").compile;
const vm = @import("vm");

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
    std.debug.print("Compiling {s}...\n", .{filePath});

    const program = try assember(allocator, filePath);
    defer program.deinit();

    // var row: usize = 0;
    // for (1.., program.items) |i, b| {
    //     if (i % 4 == 1) {
    //         std.debug.print("{d} - ", .{row});
    //     }
    //     if (i != 0 and i % 4 == 0) {
    //         const bytes = [4]u8{
    //             program.items[(row * 4) + 0],
    //             program.items[(row * 4) + 1],
    //             program.items[(row * 4) + 2],
    //             program.items[(row * 4) + 3],
    //         };
    //         const num = std.mem.readInt(u32, &bytes, .Big);
    //         std.debug.print("{x:0>2} - {d}\n", .{ b, num });
    //         row += 1;
    //         continue;
    //     }
    //     std.debug.print("{x:0>2} ", .{b});
    // }

    var machine = vm.Machine.init(program.items);
    machine.run();
}
