const vm = @import("./machine.zig");

pub fn main() !void {
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
    var machine = vm.Machine.init(&program);
    machine.run();
}
