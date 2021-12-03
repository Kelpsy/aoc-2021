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

fn part1(lineBuffer: *ArrayList(u8), reader: std.fs.File.Reader) !i32 {
    var x: i32 = 0;
    var y: i32 = 0;
    while (true) {
        const line = (try readLine(lineBuffer, reader)) orelse break;
        const spaceIndex = std.mem.indexOfScalar(u8, line, ' ').?;
        const command = line[0..spaceIndex];
        const increment = try std.fmt.parseInt(i32, line[spaceIndex + 1 ..], 10);
        if (std.mem.eql(u8, command, "forward")) {
            x += increment;
        } else if (std.mem.eql(u8, command, "up")) {
            y -= increment;
        } else if (std.mem.eql(u8, command, "down")) {
            y += increment;
        }
    }
    return x * y;
}

fn part2(lineBuffer: *ArrayList(u8), reader: std.fs.File.Reader) !i32 {
    var x: i32 = 0;
    var y: i32 = 0;
    var aim: i32 = 0;
    while (true) {
        const line = (try readLine(lineBuffer, reader)) orelse break;
        const spaceIndex = std.mem.indexOfScalar(u8, line, ' ').?;
        const command = line[0..spaceIndex];
        const increment = try std.fmt.parseInt(i32, line[spaceIndex + 1 ..], 10);
        if (std.mem.eql(u8, command, "forward")) {
            x += increment;
            y += aim * increment;
        } else if (std.mem.eql(u8, command, "up")) {
            aim -= increment;
        } else if (std.mem.eql(u8, command, "down")) {
            aim += increment;
        }
    }
    return x * y;
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
    const product = switch (part) {
        1 => try part1(&lineBuffer, inputFile.reader()),
        2 => try part2(&lineBuffer, inputFile.reader()),
        else => unreachable,
    };
    std.debug.print("Product: {}", .{product});
}
