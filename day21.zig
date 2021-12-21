const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Input = [2]u8;

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var result = std.mem.zeroes([2]u8);
    for (result) |*pos| {
        try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);
        var iter = std.mem.split(line_buffer.items, ": ");
        _ = iter.next();
        pos.* = try std.fmt.parseUnsigned(u8, iter.next().?, 10);
    }
    return result;
}

fn part1(input: Input) usize {
    var dice_rolls: usize = 0;
    var positions: [2]u8 = input;
    var scores: [2]usize = .{ 0, 0 };
    var dice_step: u16 = 1;
    var i: u1 = 0;

    while (true) {
        var steps: usize = 0;
        if (dice_step < 997) {
            steps = @as(usize, dice_step + 1) * 3;
            dice_step += 3;
        } else {
            inline for ([3]void{ {}, {}, {} }) |_| {
                steps += dice_step;
                dice_step += 1;
                if (dice_step == 1000) {
                    dice_step = 1;
                }
            }
        }
        dice_rolls += 3;
        positions[i] = @truncate(u8, (positions[i] + steps - 1) % 10 + 1);
        scores[i] += positions[i];
        if (scores[i] >= 1000) {
            break;
        }
        i ^= 1;
    }

    return scores[i ^ 1] * dice_rolls;
}

fn calc_winning_universes(i: u1, positions: [2]u8, scores: [2]usize) [2]usize {
    var result: [2]usize = .{ 0, 0 };
    var new_positions = positions;
    var new_scores = scores;
    for ([7]u8{ 1, 3, 6, 7, 6, 3, 1 }) |count, j| {
        new_positions[i] = @truncate(u8, (positions[i] + j + 2) % 10 + 1);
        new_scores[i] = scores[i] + new_positions[i];
        if (new_scores[i] >= 21) {
            result[i] += count;
        } else {
            const rec_result = calc_winning_universes(i ^ 1, new_positions, new_scores);
            result[0] += count * rec_result[0];
            result[1] += count * rec_result[1];
        }
    }
    return result;
}

fn part2(input: Input) usize {
    const result = calc_winning_universes(0, input, [2]usize{ 0, 0 });
    return std.math.max(result[0], result[1]);
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
