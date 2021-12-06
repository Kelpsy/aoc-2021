const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn readLine(line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !?[]u8 {
    reader.readUntilDelimiterArrayList(line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
        error.EndOfStream => return null,
        else => return e,
    };
    return line_buffer.items;
}

fn part1(allocator: *Allocator, line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var occurrences = ArrayList(u32).init(allocator);
    var len: u32 = 0;
    while (true) {
        const line = (try readLine(line_buffer, reader)) orelse break;
        if (occurrences.items.len < line.len) {
            try occurrences.appendNTimes(0, line.len - occurrences.items.len);
        }
        for (line) |char, i| {
            if (char == '1') {
                occurrences.items[i] += 1;
            }
        }
        len += 1;
    }
    var gamma: u32 = 0;
    var epsilon: u32 = 0;
    for (occurrences.items) |occurrences_for_bit, i| {
        const bit_mask = @as(u32, 1) << @truncate(u5, occurrences.items.len - 1 - i);
        if (occurrences_for_bit * 2 >= len) {
            gamma |= bit_mask;
        } else {
            epsilon |= bit_mask;
        }
    }
    return gamma * epsilon;
}

fn filter(list: *ArrayList(u32), bit_index: u5, most_common: comptime bool) void {
    var occurrences: u32 = 0;
    for (list.items) |value| {
        occurrences += @intCast(u32, value >> bit_index & 1);
    }
    const keep_1 = if ((occurrences * 2 >= list.items.len) == most_common) true else false;
    var i: usize = 0;
    while (i < list.items.len) {
        if (((list.items[i] >> bit_index & 1) != 0) != keep_1) {
            _ = list.swapRemove(i);
        } else {
            i += 1;
        }
    }
}

fn part2(allocator: *Allocator, line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var oxygen = ArrayList(u32).init(allocator);
    var co2 = ArrayList(u32).init(allocator);
    var bits: usize = 0;
    while (true) {
        const line = (try readLine(line_buffer, reader)) orelse break;
        if (line.len > bits) {
            bits = line.len;
        }
        const value = try std.fmt.parseUnsigned(u32, line, 2);
        try oxygen.append(value);
        try co2.append(value);
    }
    var bit_index = @truncate(u5, bits);
    while (bit_index > 0) {
        bit_index -= 1;
        if (oxygen.items.len > 1) {
            filter(&oxygen, bit_index, true);
        }
        if (co2.items.len > 1) {
            filter(&co2, bit_index, false);
        }
    }
    return oxygen.items[0] * co2.items[0];
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip();
    const part = try std.fmt.parseUnsigned(u8, try args.next(allocator).?, 10);
    const path = try args.next(allocator).?;
    const input_file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer input_file.close();
    var line_buffer = ArrayList(u8).init(allocator);
    const product = switch (part) {
        1 => try part1(allocator, &line_buffer, input_file.reader()),
        2 => try part2(allocator, &line_buffer, input_file.reader()),
        else => unreachable,
    };
    std.debug.print("Product: {}", .{product});
}
