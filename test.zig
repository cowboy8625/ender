const std = @import("std");

// const Foo = union(enum) {
//     const Self = @This();
//     int: i32,
//     float: f64,
//     fn isA(self: *const Self, t: std.meta.Tag(Self)) bool {
//         switch (self.*) {
//             .int => if (t == .int) {
//                 return true;
//             },
//             .float => if (t == .float) {
//                 return true;
//             },
//         }
//         return false;
//     }
// };
// const foo = Foo{ .int = 1 };
// std.debug.print("{}\n", .{foo});
// std.debug.print("{any}\n", .{foo.isA(.float)});

// fn Iterator(comptime T: type) type {
//     return struct {
//         const Self = @This();
//
//         ip: usize = 0,
//         items: []const T,
//         fn init(items: []const T) Self {
//             return .{
//                 .items = items,
//             };
//         }
//
//         fn next(self: *Self) ?T {
//             if (self.ip >= self.items.len) {
//                 return null;
//             }
//             const ip = self.ip;
//             self.ip += 1;
//             return self.items[ip];
//         }
//
//         fn peek(self: *Self) ?T {
//             if (self.ip + 1 >= self.items.len) {
//                 return null;
//             }
//             return self.items[self.ip + 1];
//         }
//     };
// }
// var iter = Iterator(i32).init(&[_]i32{ 1, 2, 3 });
// while (iter.next()) |i| {
//     std.debug.print("{}\n", .{i});
// }

fn foo() ![]const u8 {
    return error.OutOfMemory;
}
pub fn main() !void {
    const i = foo() catch "WOW";
    std.debug.print("{s}", .{i});
}
