const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !ArrayList(u16) {
    var result = ArrayList(u16).init(allocator);
    var line_buffer = ArrayList(u8).init(allocator);
    var finished = false;
    while (!finished) {
        reader.readUntilDelimiterArrayList(&line_buffer, ',', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => {
                finished = true;
            },
            else => return e,
        };
        const slice = if (line_buffer.items[line_buffer.items.len - 1] == '\n') line_buffer.items[0 .. line_buffer.items.len - 1] else line_buffer.items;
        try result.append(try std.fmt.parseUnsigned(u16, slice, 10));
    }
    return result;
}

fn part1(crabs: []const u16) !u64 {
    var min_x: u16 = std.math.inf_u16;
    var max_x: u16 = 0;
    for (crabs) |crab_pos| {
        if (crab_pos < min_x) {
            min_x = crab_pos;
        }
        if (crab_pos > max_x) {
            max_x = crab_pos;
        }
    }

    var min_fuel: u64 = std.math.inf_u64;
    var x: u16 = min_x;
    while (x <= max_x) : ({
        x += 1;
    }) {
        var fuel: u64 = 0;
        for (crabs) |crab_pos| {
            fuel += if (crab_pos >= x) crab_pos - x else x - crab_pos;
        }
        if (fuel < min_fuel) {
            min_fuel = fuel;
        }
    }

    return min_fuel;
}

fn part2(crabs: []const u16) !u64 {
    var min_x: u16 = std.math.inf_u16;
    var max_x: u16 = 0;
    for (crabs) |crab_pos| {
        if (crab_pos < min_x) {
            min_x = crab_pos;
        }
        if (crab_pos > max_x) {
            max_x = crab_pos;
        }
    }

    var min_fuel: u64 = std.math.inf_u64;
    var x: u16 = min_x;
    while (x <= max_x) : ({
        x += 1;
    }) {
        var fuel: u64 = 0;
        for (crabs) |crab| {
            var diff = if (crab >= x) crab - x else x - crab;
            while (diff != 0) {
                fuel += diff;
                diff -= 1;
            }
        }
        if (fuel < min_fuel) {
            min_fuel = fuel;
        }
    }

    return min_fuel;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip();
    const part = try std.fmt.parseUnsigned(u8, try args.next(allocator).?, 10);
    const path = try args.next(allocator).?;
    const input_file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer input_file.close();
    const crabs = try parseInput(allocator, input_file.reader());
    const result = switch (part) {
        1 => try part1(crabs.items),
        2 => try part2(crabs.items),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
