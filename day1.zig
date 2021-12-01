const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn readLine(lineBuffer: *ArrayList(u8), reader: std.fs.File.Reader) !?[]u8 {
    try lineBuffer.resize(0);
    reader.readUntilDelimiterArrayList(lineBuffer, '\n', std.math.inf_u64) catch |e| switch (e) {
        error.EndOfStream => return null,
        else => return e,
    };
    return lineBuffer.items;
}

fn part1(lineBuffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var prevValue: ?u32 = null;
    var increments: u32 = 0;
    while (true) {
        const newValue = try std.fmt.parseUnsigned(u32, (try readLine(lineBuffer, reader)) orelse break, 10);
        if (prevValue) |value| {
            if (newValue > value) {
                increments += 1;
            }
        }
        prevValue = newValue;
    }
    return increments;
}

fn part2(lineBuffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var prevSum: ?u32 = null;
    var window = [2]?u32{ null, null };
    var increments: u32 = 0;
    while (true) {
        const newValue = try std.fmt.parseUnsigned(u32, (try readLine(lineBuffer, reader)) orelse break, 10);
        if (window[0] != null and window[1] != null) {
            const newSum = window[0].? + window[1].? + newValue;
            if (prevSum) |sum| {
                if (newSum > sum) {
                    increments += 1;
                }
            }
            prevSum = newSum;
        }
        window[0] = window[1];
        window[1] = newValue;
    }
    return increments;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip();
    const part = try std.fmt.parseUnsigned(u8, try args.next(allocator).?, 10);
    const path = try args.next(allocator).?;
    const inputFile = try std.fs.cwd().openFile(path, .{ .read = true });
    defer inputFile.close();
    var lineBuffer = ArrayList(u8).init(allocator);
    const increments = switch (part) {
        1 => try part1(&lineBuffer, inputFile.reader()),
        2 => try part2(&lineBuffer, inputFile.reader()),
        else => unreachable,
    };
    std.debug.print("Increments: {}", .{increments});
}
