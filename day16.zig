const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const BitStream = struct {
    contents: []const u8,
    pos: usize,
    shift: u3,

    fn deinit(self: *@This()) void {
        self.contents.deinit();
    }

    fn read(self: *@This(), comptime T: type, bits: *u32) ?T {
        // NOTE: Assumes @bitSizeOf(T) <= 63
        var result: u64 = 0;
        var res_shift: u6 = @bitSizeOf(T);
        while (res_shift > 0) {
            const remaining_bits_in_byte = @as(usize, 8) - self.shift;
            const read_bits = @truncate(u4, std.math.min(remaining_bits_in_byte, res_shift));
            if (read_bits > bits.*) {
                return null;
            }
            res_shift -= read_bits;
            bits.* -= read_bits;
            const shift_in_byte = @truncate(u3, remaining_bits_in_byte - read_bits);
            const mask = @truncate(u8, (@as(u16, 1) << read_bits) - 1);
            result |= @intCast(u64, self.contents[self.pos] >> shift_in_byte & mask) << res_shift;
            self.shift = @truncate(u3, self.shift + read_bits);
            if (self.shift == 0) {
                self.pos += 1;
            }
        }
        return @truncate(T, result);
    }
};

const Packet = struct {
    version: u3,
    ty: u3,
    contents: union {
        value: u64,
        packets: ArrayList(Packet),
    },

    fn deinit(self: *@This()) void {
        if (self.ty != 4) {
            self.contents.packets.deinit();
        }
    }

    fn decode(stream: *BitStream, bits: *u32, allocator: *Allocator) std.mem.Allocator.Error!Packet {
        const version = stream.read(u3, bits).?;
        const ty = stream.read(u3, bits).?;
        if (ty == 4) {
            var value: u64 = 0;
            while (true) {
                const part = stream.read(u5, bits).?;
                value = value << 4 | (part & 0xF);
                if (part & 0x10 == 0) {
                    break;
                }
            }
            return Packet{ .version = version, .ty = ty, .contents = .{ .value = value } };
        } else {
            const length_ty = stream.read(u1, bits).?;
            var packets = ArrayList(Packet).init(allocator);
            if (length_ty == 0) {
                var bits_: u32 = stream.read(u15, bits).?;
                bits.* -= bits_;
                while (bits_ != 0) {
                    try packets.append(try Packet.decode(stream, &bits_, allocator));
                }
            } else {
                var packet_count = stream.read(u11, bits).?;
                while (packet_count != 0) : ({
                    packet_count -= 1;
                }) {
                    try packets.append(try Packet.decode(stream, bits, allocator));
                }
            }
            return Packet{ .version = version, .ty = ty, .contents = .{ .packets = packets } };
        }
    }
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Packet {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);

    var raw = ArrayList(u8).init(allocator);
    try raw.appendNTimes(0, (line_buffer.items.len + 1) >> 1);

    var bits: u32 = 0;
    for (line_buffer.items) |hex_char, i| {
        const value = if (hex_char >= 'A') hex_char - 'A' + 10 else hex_char - '0';
        raw.items[i >> 1] |= (value & 0xF) << @truncate(u3, (i ^ 1) << 2);
        bits += 4;
    }

    var stream = BitStream{
        .contents = raw.items,
        .pos = 0,
        .shift = 0,
    };
    return try Packet.decode(&stream, &bits, allocator);
}

fn part1(packet: *const Packet) u64 {
    var result: u64 = 0;
    result += packet.version;
    if (packet.ty != 4) {
        for (packet.contents.packets.items) |*subpacket| {
            result += part1(subpacket);
        }
    }
    return result;
}

fn part2(packet: *const Packet) u64 {
    switch (packet.ty) {
        0 => {
            var result: u64 = 0;
            for (packet.contents.packets.items) |*subpacket| {
                result += part2(subpacket);
            }
            return result;
        },
        1 => {
            var result: u64 = 1;
            for (packet.contents.packets.items) |*subpacket| {
                result *= part2(subpacket);
            }
            return result;
        },
        2 => {
            var result: u64 = std.math.inf_u64;
            for (packet.contents.packets.items) |*subpacket| {
                result = std.math.min(result, part2(subpacket));
            }
            return result;
        },
        3 => {
            var result: u64 = 0;
            for (packet.contents.packets.items) |*subpacket| {
                result = std.math.max(result, part2(subpacket));
            }
            return result;
        },
        4 => {
            return packet.contents.value;
        },
        5 => {
            const values = [2]u64{
                part2(&packet.contents.packets.items[0]),
                part2(&packet.contents.packets.items[1]),
            };
            return @boolToInt(values[0] > values[1]);
        },
        6 => {
            const values = [2]u64{
                part2(&packet.contents.packets.items[0]),
                part2(&packet.contents.packets.items[1]),
            };
            return @boolToInt(values[0] < values[1]);
        },
        7 => {
            const values = [2]u64{
                part2(&packet.contents.packets.items[0]),
                part2(&packet.contents.packets.items[1]),
            };
            return @boolToInt(values[0] == values[1]);
        },
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip();
    const part = try std.fmt.parseUnsigned(u8, try args.next(allocator).?, 10);
    const path = try args.next(allocator).?;
    const input_file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer input_file.close();
    var input = try parseInput(allocator, input_file.reader());
    defer input.deinit();
    const result = switch (part) {
        1 => part1(&input),
        2 => part2(&input),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
