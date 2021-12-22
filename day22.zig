const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.HashMap;

const Cube = [3][2]i32;

const CubeContext = struct {
    pub fn eql(self: @This(), a: Cube, b: Cube) bool {
        return std.mem.eql(i32, &a[0], &b[0]) and std.mem.eql(i32, &a[1], &b[1]) and std.mem.eql(i32, &a[2], &b[2]);
    }
    pub fn hash(self: @This(), s: Cube) u64 {
        var result: u64 = 0;
        inline for (.{ 1, 0 }) |i| {
            result <<= 32;
            result |= @bitCast(u32, s[2][i] ^ s[1][i] ^ s[0][i]);
        }
        return result;
    }
};

const Step = struct {
    cube: Cube,
    enable: bool,
};

const Input = ArrayList(Step);
const ResultCubes = HashMap(Cube, void, CubeContext, 80);

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var result = ArrayList(Step).init(allocator);
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        var iter = std.mem.split(line_buffer.items, " ");
        var step = Step{
            .cube = std.mem.zeroes(Cube),
            .enable = std.mem.eql(u8, iter.next().?, "on"),
        };
        var coord_range_iter = std.mem.split(iter.next().?, ",");
        for (step.cube) |*coord_range| {
            var bound_iter = std.mem.split(coord_range_iter.next().?[2..], "..");
            for (coord_range) |*bound| {
                bound.* = try std.fmt.parseInt(i32, bound_iter.next().?, 10);
            }
        }
        try result.append(step);
    }
    return result;
}

fn applyInput(input: *const Input, allocator: *Allocator) !ResultCubes {
    var enabled_cubes = ResultCubes.init(allocator);

    for (input.items) |step, i| {
        var new_enabled_cubes = ResultCubes.init(allocator);
        var iter = enabled_cubes.keyIterator();
        cube_loop: while (iter.next()) |cube| {
            for (cube) |coord_range, j| {
                if (step.cube[j][1] < coord_range[0] or step.cube[j][0] > coord_range[1]) {
                    try new_enabled_cubes.put(cube.*, {});
                    continue :cube_loop;
                }
            }
            for ([3][2]i32{
                .{ cube[0][0], step.cube[0][0] - 1 },
                .{ std.math.max(step.cube[0][0], cube[0][0]), std.math.min(step.cube[0][1], cube[0][1]) },
                .{ step.cube[0][1] + 1, cube[0][1] },
            }) |x_range, x_i| {
                if (x_range[1] < x_range[0]) {
                    continue;
                }
                for ([3][2]i32{
                    .{ cube[1][0], step.cube[1][0] - 1 },
                    .{ std.math.max(step.cube[1][0], cube[1][0]), std.math.min(step.cube[1][1], cube[1][1]) },
                    .{ step.cube[1][1] + 1, cube[1][1] },
                }) |y_range, y_i| {
                    if (y_range[1] < y_range[0]) {
                        continue;
                    }
                    for ([3][2]i32{
                        .{ cube[2][0], step.cube[2][0] - 1 },
                        .{ std.math.max(step.cube[2][0], cube[2][0]), std.math.min(step.cube[2][1], cube[2][1]) },
                        .{ step.cube[2][1] + 1, cube[2][1] },
                    }) |z_range, z_i| {
                        if ((x_i == 1 and y_i == 1 and z_i == 1) or z_range[1] < z_range[0]) {
                            continue;
                        }
                        try new_enabled_cubes.put(.{ x_range, y_range, z_range }, {});
                    }
                }
            }
        }

        if (step.enable) {
            try new_enabled_cubes.put(step.cube, {});
        }

        enabled_cubes.deinit();
        enabled_cubes = new_enabled_cubes;
    }

    return enabled_cubes;
}

fn clamp(v: i32, min: i32, max: i32) i32 {
    if (v < min) {
        return min;
    } else if (v > max) {
        return max;
    } else {
        return v;
    }
}

fn part1(result_cubes: *const ResultCubes) i64 {
    var result: i64 = 0;
    var iter = result_cubes.keyIterator();
    outer: while (iter.next()) |cube| {
        for (cube) |coord_range| {
            if (coord_range[0] > 50 or coord_range[1] < -50) {
                continue :outer;
            }
        }
        var new_cube = std.mem.zeroes(Cube);
        for (new_cube) |*new_range, i| {
            for (new_range) |*new_bound, j| {
                new_bound.* = clamp(cube[i][j], -50, 50);
            }
        }
        result += @as(i64, new_cube[0][1] - new_cube[0][0] + 1) * @as(i64, new_cube[1][1] - new_cube[1][0] + 1) * @as(i64, new_cube[2][1] - new_cube[2][0] + 1);
    }
    return result;
}

fn part2(result_cubes: *const ResultCubes) i64 {
    var result: i64 = 0;
    var iter = result_cubes.keyIterator();
    while (iter.next()) |cube| {
        result += @as(i64, cube[0][1] - cube[0][0] + 1) * @as(i64, cube[1][1] - cube[1][0] + 1) * @as(i64, cube[2][1] - cube[2][0] + 1);
    }
    return result;
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
    var result_cubes = try applyInput(&input, allocator);
    defer result_cubes.deinit();
    const result = switch (part) {
        1 => part1(&result_cubes),
        2 => part2(&result_cubes),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
