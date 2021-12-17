const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Input = [2][2]i16;

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);

    const line_slice = line_buffer.items[15..];
    var coord_iter = std.mem.split(line_slice, ", y=");

    var result = std.mem.zeroes([2][2]i16);
    for (result) |*coord_range| {
        var range_iter = std.mem.split(coord_iter.next().?, "..");
        for (coord_range.*) |*range_coord| {
            range_coord.* = try std.fmt.parseInt(i16, range_iter.next().?, 10);
        }
    }

    return result;
}

fn part1(input: Input) u32 {
    return @bitCast(u32, (@as(i32, -input[1][0]) * @as(i32, (-input[1][0] - 1)))) / 2;
}

fn part2(input: Input) u32 {
    var result: u32 = 0;
    var init_y_velocity = -input[1][0] - 1;
    while (init_y_velocity >= input[1][0]) : ({
        init_y_velocity -= 1;
    }) {
        var init_x_velocity: i16 = 1;
        while (init_x_velocity <= input[0][1]) : ({
            init_x_velocity += 1;
        }) {
            var pos = [2]i16{ 0, 0 };
            var velocity = [2]i16{ init_x_velocity, init_y_velocity };
            while (pos[1] >= input[1][0]) {
                pos[0] += velocity[0];
                pos[1] += velocity[1];
                if (pos[0] >= input[0][0] and pos[0] <= input[0][1] and pos[1] >= input[1][0] and pos[1] <= input[1][1]) {
                    result += 1;
                    break;
                }
                if (velocity[0] != 0) {
                    velocity[0] -= 1;
                }
                velocity[1] -= 1;
            }
        }
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
    const result = switch (part) {
        1 => part1(input),
        2 => part2(input),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
