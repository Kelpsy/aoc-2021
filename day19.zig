const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Scanner = ArrayList([3]i16);
const SolvedScanner = struct {
    beacons: ArrayList([3]i16),
    pos: [3]i16,
};
const Input = ArrayList(Scanner);

const CoordContext = struct {
    pub fn eql(self: @This(), a: [3]i16, b: [3]i16) bool {
        return std.mem.eql(i16, &a, &b);
    }
    pub fn hash(self: @This(), s: [3]i16) u64 {
        return @as(u64, @bitCast(u16, s[2])) << 32 | @as(u64, @bitCast(u16, s[1])) << 16 | @as(u64, @bitCast(u16, s[0]));
    }
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var result = Input.init(allocator);
    var cur_scanner = Scanner.init(allocator);
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        if (line_buffer.items.len == 0) {
            try result.append(cur_scanner);
            cur_scanner = Scanner.init(allocator);
            continue;
        } else if (std.mem.startsWith(u8, line_buffer.items, "---")) {
            continue;
        }
        var coords_iter = std.mem.split(line_buffer.items, ",");
        var coords = std.mem.zeroes([3]i16);
        for (coords) |*coord, i| {
            coord.* = try std.fmt.parseInt(i16, coords_iter.next().?, 10);
        }
        try cur_scanner.append(coords);
    }
    try result.append(cur_scanner);
    return result;
}

fn solveInput(input: Input, allocator: *Allocator) !ArrayList(SolvedScanner) {
    defer {
        for (input.items) |scanner| {
            scanner.deinit();
        }
        input.deinit();
    }

    var remaining_scanners = ArrayList(*const Scanner).init(allocator);
    defer remaining_scanners.deinit();
    for (input.items[1..]) |*scanner| {
        try remaining_scanners.append(scanner);
    }

    var solved_scanners = ArrayList(SolvedScanner).init(allocator);
    {
        var beacons = Scanner.init(allocator);
        try beacons.appendSlice(input.items[0].items);
        try solved_scanners.append(SolvedScanner{ .beacons = beacons, .pos = [3]i16{ 0, 0, 0 } });
    }

    var rel_coords_list = ArrayList([3]i16).init(allocator);
    var distance_counts = std.HashMap([3]i16, u16, CoordContext, 80).init(allocator);

    outer: while (remaining_scanners.items.len != 0) {
        for (remaining_scanners.items) |scanner, i| {
            for ([4]u8{ 0, 1, 2, 3 }) |x_rot| {
                for ([4]u8{ 0, 1, 2, 3 }) |y_rot| {
                    for ([4]u8{ 0, 1, 2, 3 }) |z_rot| {
                        try rel_coords_list.resize(0);
                        for (scanner.items) |coords| {
                            var new_coords = coords;
                            var j: usize = 0;
                            var tmp: i16 = 0;
                            while (j < x_rot) {
                                tmp = new_coords[1];
                                new_coords[1] = new_coords[2];
                                new_coords[2] = -tmp;
                                j += 1;
                            }
                            j = 0;
                            while (j < y_rot) {
                                tmp = new_coords[0];
                                new_coords[0] = new_coords[2];
                                new_coords[2] = -tmp;
                                j += 1;
                            }
                            j = 0;
                            while (j < z_rot) {
                                tmp = new_coords[0];
                                new_coords[0] = new_coords[1];
                                new_coords[1] = -tmp;
                                j += 1;
                            }
                            try rel_coords_list.append(new_coords);
                        }
                        const distance = distance_search: for (solved_scanners.items) |solved_scanner| {
                            distance_counts.clearRetainingCapacity();
                            for (rel_coords_list.items) |rel_coords| {
                                for (solved_scanner.beacons.items) |solved_coords| {
                                    const distance = [3]i16{
                                        solved_coords[0] - rel_coords[0],
                                        solved_coords[1] - rel_coords[1],
                                        solved_coords[2] - rel_coords[2],
                                    };
                                    const new_count = (distance_counts.get(distance) orelse 0) + 1;
                                    if (new_count >= 12) {
                                        break :distance_search distance;
                                    }
                                    try distance_counts.put(distance, new_count);
                                }
                            }
                        } else continue;
                        var beacons = Scanner.init(allocator);
                        for (rel_coords_list.items) |rel_coords| {
                            const abs_coords = [3]i16{
                                rel_coords[0] + distance[0],
                                rel_coords[1] + distance[1],
                                rel_coords[2] + distance[2],
                            };
                            try beacons.append(abs_coords);
                        }
                        _ = remaining_scanners.swapRemove(i);
                        try solved_scanners.append(SolvedScanner{ .beacons = beacons, .pos = distance });
                        continue :outer;
                    }
                }
            }
        }
    }

    return solved_scanners;
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
    var scanners = try solveInput(input, allocator);
    defer {
        for (scanners.items) |scanner| {
            scanner.beacons.deinit();
        }
        scanners.deinit();
    }
    var result: usize = 0;
    switch (part) {
        1 => {
            var abs_coords_list = std.HashMap([3]i16, void, CoordContext, 80).init(allocator);
            defer abs_coords_list.deinit();
            for (scanners.items) |scanner| {
                for (scanner.beacons.items) |coords| {
                    try abs_coords_list.put(coords, {});
                }
            }
            result = abs_coords_list.count();
        },
        2 => {
            for (scanners.items) |scanner| {
                for (scanners.items) |other_scanner| {
                    var distance: usize = 0;
                    for (scanner.pos) |a, i| {
                        const b = other_scanner.pos[i];
                        distance += @bitCast(u16, if (a > b) a - b else b - a);
                    }
                    if (distance > result) {
                        result = distance;
                    }
                }
            }
        },
        else => unreachable,
    }
    std.debug.print("Result: {}\n", .{result});
}
