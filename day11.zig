const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Input = struct {
    octopi: ArrayList(u8),
    size: [2]usize,
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var octopi = ArrayList(u8).init(allocator);
    var size = [2]usize{ 0, 0 };
    var line_buffer = ArrayList(u8).init(allocator);
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        size[0] = line_buffer.items.len;
        size[1] += 1;
        for (line_buffer.items) |char| {
            try octopi.append(char - '0');
        }
    }
    return Input{ .octopi = octopi, .size = size };
}

fn step(octopi: []u8, size: [2]usize) usize {
    var flashes: usize = 0;

    {
        var y: usize = 0;
        while (y < size[1]) : ({
            y += 1;
        }) {
            var x: usize = 0;
            while (x < size[0]) : ({
                x += 1;
            }) {
                const i = y * size[0] + x;
                octopi[i] += 1;
            }
        }
    }

    var finished = false;
    while (!finished) {
        finished = true;
        var y: usize = 0;
        while (y < size[1]) : ({
            y += 1;
        }) {
            var x: usize = 0;
            while (x < size[0]) : ({
                x += 1;
            }) {
                const i = y * size[0] + x;
                if (octopi[i] > 9 and octopi[i] != 255) {
                    octopi[i] = 255;
                    flashes += 1;
                    var bounds = [2][2]usize{ .{ 0, 0 }, .{ 0, 0 } };
                    for ([2]usize{ x, y }) |coord, coord_i| {
                        bounds[0][coord_i] = std.math.max(coord, 1) - 1;
                        bounds[1][coord_i] = std.math.min(coord, size[coord_i] - 2) + 1;
                    }
                    var adj_y: usize = bounds[0][1];
                    while (adj_y <= bounds[1][1]) : ({
                        adj_y += 1;
                    }) {
                        var adj_x: usize = bounds[0][0];
                        while (adj_x <= bounds[1][0]) : ({
                            adj_x += 1;
                        }) {
                            const adj_i = adj_y * size[0] + adj_x;
                            if (adj_i == i or octopi[adj_i] == 255) {
                                continue;
                            }
                            octopi[adj_i] += 1;
                            finished = finished and octopi[adj_i] <= 9;
                        }
                    }
                }
            }
        }
    }

    for (octopi) |*octopus| {
        if (octopus.* == 255) {
            octopus.* = 0;
        }
    }

    {
        var y: usize = 0;
        while (y < size[1]) : ({
            y += 1;
        }) {
            var x: usize = 0;
            while (x < size[0]) : ({
                x += 1;
            }) {
                const i = y * size[0] + x;
            }
        }
    }

    return flashes;
}

fn part1(octopi: []u8, size: [2]usize) !usize {
    var flashes: usize = 0;

    var step_index: usize = 0;
    while (step_index < 100) : ({
        step_index += 1;
    }) {
        flashes += step(octopi, size);
    }

    return flashes;
}

fn part2(octopi: []u8, size: [2]usize) !usize {
    var step_index: usize = 0;
    const needed_flashes = size[0] * size[1];
    while (true) {
        step_index += 1;
        const flashes = step(octopi, size);
        if (flashes == needed_flashes) {
            return step_index;
        }
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
    const input = try parseInput(allocator, input_file.reader());
    const result = switch (part) {
        1 => try part1(input.octopi.items, input.size),
        2 => try part2(input.octopi.items, input.size),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
