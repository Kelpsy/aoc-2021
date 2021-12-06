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

fn part1(line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !i32 {
    var x: i32 = 0;
    var y: i32 = 0;
    while (true) {
        const line = (try readLine(line_buffer, reader)) orelse break;
        const space_index = std.mem.indexOfScalar(u8, line, ' ').?;
        const command = line[0..space_index];
        const increment = try std.fmt.parseInt(i32, line[space_index + 1 ..], 10);
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

fn part2(line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !i32 {
    var x: i32 = 0;
    var y: i32 = 0;
    var aim: i32 = 0;
    while (true) {
        const line = (try readLine(line_buffer, reader)) orelse break;
        const space_index = std.mem.indexOfScalar(u8, line, ' ').?;
        const command = line[0..space_index];
        const increment = try std.fmt.parseInt(i32, line[space_index + 1 ..], 10);
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
    const input_file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer input_file.close();
    var line_buffer = ArrayList(u8).init(allocator);
    const product = switch (part) {
        1 => try part1(&line_buffer, input_file.reader()),
        2 => try part2(&line_buffer, input_file.reader()),
        else => unreachable,
    };
    std.debug.print("Product: {}", .{product});
}
