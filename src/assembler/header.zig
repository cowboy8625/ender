const std = @import("std");
// 0x00 First 4 bytes are the Magic Number of 'ZAGI'
// 0x04 Second 4 bytes are the version number
// 0x08 Data segment starts at offset 8
// 0x0C Text segment starts at offset 12
// 0x10 Entry point is at offset 16
// 0x14 Program size is at offset 20
// 0x18 to 0x40 are reserved
//
// 0x40 Data segment
// 0x__ Text segment

pub const Header = struct {
    const Self = @This();
    const magicNumber: []const u8 = "ZAGI";
    const version: u32 = 1;
    dataSegment: u32,
    textSegment: u32,
    entryPoint: u32,
    programSize: u32,

    pub fn init(
        programSize: u32,
        dataSegment: u32,
        textSegment: u32,
        entryPoint: u32,
    ) Header {
        return Header{
            .programSize = programSize,
            .dataSegment = dataSegment,
            .textSegment = textSegment,
            .entryPoint = entryPoint,
        };
    }

    pub fn asBytes(self: *const Self) [64]u8 {
        const Version: [4]u8 = @bitCast(version);
        const dataSegment: [4]u8 = @bitCast(self.dataSegment);
        const textSegment: [4]u8 = @bitCast(self.dataSegment);
        const entryPoint: [4]u8 = @bitCast(self.entryPoint);
        const programSize: [4]u8 = @bitCast(self.programSize);
        // TODO: figure out how to concat these arrays
        const header = [_]u8{
            magicNumber[0],
            magicNumber[1],
            magicNumber[2],
            magicNumber[3],
            Version[0],
            Version[1],
            Version[2],
            Version[3],
            dataSegment[0],
            dataSegment[1],
            dataSegment[2],
            dataSegment[3],
            textSegment[0],
            textSegment[1],
            textSegment[2],
            textSegment[3],
            entryPoint[0],
            entryPoint[1],
            entryPoint[2],
            entryPoint[3],
            programSize[0],
            programSize[1],
            programSize[2],
            programSize[3],
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
        };
        return header;
    }
};