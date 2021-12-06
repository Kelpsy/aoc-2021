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

fn part1(line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var prev_value: ?u32 = null;
    var increments: u32 = 0;
    while (true) {
        const new_value = try std.fmt.parseUnsigned(u32, (try readLine(line_buffer, reader)) orelse break, 10);
        if (prev_value) |value| {
            if (new_value > value) {
                increments += 1;
            }
        }
        prev_value = new_value;
    }
    return increments;
}

fn part2(line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var prev_sum: ?u32 = null;
    var window = [2]?u32{ null, null };
    var increments: u32 = 0;
    while (true) {
        const new_value = try std.fmt.parseUnsigned(u32, (try readLine(line_buffer, reader)) orelse break, 10);
        if (window[0] != null and window[1] != null) {
            const new_sum = window[0].? + window[1].? + new_value;
            if (prev_sum) |sum| {
                if (new_sum > sum) {
                    increments += 1;
                }
            }
            prev_sum = new_sum;
        }
        window[0] = window[1];
        window[1] = new_value;
    }
    return increments;
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
    const increments = switch (part) {
        1 => try part1(&line_buffer, input_file.reader()),
        2 => try part2(&line_buffer, input_file.reader()),
        else => unreachable,
    };
    std.debug.print("Increments: {}", .{increments});
}
