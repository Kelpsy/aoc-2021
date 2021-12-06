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

const Line = struct {
    start: [2]u16,
    end: [2]u16,
};

fn parse(lines: *ArrayList(Line), line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !void {
    while (true) {
        const line = (try readLine(line_buffer, reader)) orelse break;
        var iter = std.mem.split(line, " -> ");
        var start_iter = std.mem.split(iter.next().?, ",");
        var end_iter = std.mem.split(iter.next().?, ",");
        const start_x = try std.fmt.parseUnsigned(u16, start_iter.next().?, 10);
        const start_y = try std.fmt.parseUnsigned(u16, start_iter.next().?, 10);
        const end_x = try std.fmt.parseUnsigned(u16, end_iter.next().?, 10);
        const end_y = try std.fmt.parseUnsigned(u16, end_iter.next().?, 10);
        try lines.append(.{ .start = .{ start_x, start_y }, .end = .{ end_x, end_y } });
    }
}

fn part1(allocator: *Allocator, line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var lines = ArrayList(Line).init(allocator);
    try parse(&lines, line_buffer, reader);

    {
        var i: usize = 0;
        while (i < lines.items.len) {
            const line = &lines.items[i];
            if (line.start[0] != line.end[0] and line.start[1] != line.end[1]) {
                _ = lines.swapRemove(i);
            } else {
                if (line.start[0] > line.end[0]) {
                    std.mem.swap(u16, &line.start[0], &line.end[0]);
                }
                if (line.start[1] > line.end[1]) {
                    std.mem.swap(u16, &line.start[1], &line.end[1]);
                }
                i += 1;
            }
        }
    }

    var max = [2]u16{ 0, 0 };
    for (lines.items) |line| {
        for (line.end) |coord, i| {
            if (coord + 1 > max[i]) {
                max[i] = coord + 1;
            }
        }
    }

    var grid = ArrayList(ArrayList(u16)).init(allocator);
    while (max[1] != 0) : ({
        max[1] -= 1;
    }) {
        var row = ArrayList(u16).init(allocator);
        try row.appendNTimes(0, max[0]);
        try grid.append(row);
    }

    for (lines.items) |line| {
        var coords = line.start;
        const coord_index: usize = if (coords[0] != line.end[0]) 0 else 1;
        while (coords[coord_index] <= line.end[coord_index]) {
            grid.items[coords[1]].items[coords[0]] += 1;
            coords[coord_index] += 1;
        }
    }

    var intersections: u32 = 0;
    for (grid.items) |row| {
        for (row.items) |cell| {
            if (cell > 1) {
                intersections += 1;
            }
        }
    }

    return intersections;
}

fn part2(allocator: *Allocator, line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var lines = ArrayList(Line).init(allocator);
    try parse(&lines, line_buffer, reader);

    var max = [2]u16{ 0, 0 };
    for (lines.items) |line| {
        for ([2][2]u16{ line.start, line.end }) |coords| {
            for (coords) |coord, i| {
                if (coord + 1 > max[i]) {
                    max[i] = coord + 1;
                }
            }
        }
    }

    var grid = ArrayList(ArrayList(u16)).init(allocator);
    while (max[1] != 0) : ({
        max[1] -= 1;
    }) {
        var row = ArrayList(u16).init(allocator);
        try row.appendNTimes(0, max[0]);
        try grid.append(row);
    }

    for (lines.items) |line| {
        const x_same = line.start[0] == line.end[0];
        const y_same = line.start[1] == line.end[1];
        if (x_same or y_same) {
            const coord_index: usize = if (x_same) 1 else 0;
            const increment: i16 = if (line.end[coord_index] > line.start[coord_index]) 1 else -1;
            var coords = line.start;
            while (true) {
                grid.items[coords[1]].items[coords[0]] += 1;
                if (coords[coord_index] == line.end[coord_index]) {
                    break;
                }
                coords[coord_index] = @bitCast(u16, @bitCast(i16, coords[coord_index]) + increment);
            }
        } else {
            const increment = [2]i16{
                if (line.end[0] > line.start[0]) 1 else -1,
                if (line.end[1] > line.start[1]) 1 else -1,
            };
            var coords = line.start;
            while (true) {
                grid.items[coords[1]].items[coords[0]] += 1;
                if (coords[0] == line.end[0]) {
                    break;
                }
                coords[0] = @bitCast(u16, @bitCast(i16, coords[0]) + increment[0]);
                coords[1] = @bitCast(u16, @bitCast(i16, coords[1]) + increment[1]);
            }
        }
    }

    var intersections: u32 = 0;
    for (grid.items) |row| {
        for (row.items) |cell| {
            if (cell > 1) {
                intersections += 1;
            }
        }
    }

    return intersections;
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
    const intersections = switch (part) {
        1 => try part1(allocator, &line_buffer, input_file.reader()),
        2 => try part2(allocator, &line_buffer, input_file.reader()),
        else => unreachable,
    };
    std.debug.print("Intersections: {}", .{intersections});
}
