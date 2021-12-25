const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.hash_map.HashMap;

const Input = struct {
    grid: ArrayList(u2),
    size: [2]usize,
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var size = [2]usize{ 0, 0 };
    var grid = ArrayList(u2).init(allocator);
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        size[0] = line_buffer.items.len;
        size[1] += 1;
        for (line_buffer.items) |char| {
            try grid.append(switch (char) {
                '>' => 0,
                'v' => 1,
                '.' => 2,
                else => unreachable,
            });
        }
    }
    return Input{ .grid = grid, .size = size };
}

fn solveInput(input: Input, allocator: *Allocator) !usize {
    const size = input.size;
    var grids = [2]ArrayList(u2){ input.grid, try ArrayList(u2).initCapacity(allocator, input.grid.items.len) };
    defer grids[0].deinit();
    defer grids[1].deinit();
    var steps: usize = 0;
    while (true) {
        steps += 1;
        var moved = false;
        inline for ([2]u1{ 0, 1 }) |i| {
            const src = &grids[i];
            const dst = &grids[1 - i];
            dst.clearRetainingCapacity();
            try dst.appendNTimes(2, input.grid.items.len);
            var y: usize = 0;
            while (y < size[1]) {
                const y_base = y * size[0];
                var x: usize = 0;
                while (x < size[0]) {
                    const src_off = y_base + x;
                    switch (src.items[src_off] ^ i) {
                        0 => {
                            const dst_off: usize = if (i == 0) y_base + (x + 1) % size[0] else ((y + 1) % size[1]) * size[0] + x;
                            if (src.items[dst_off] == 2) {
                                dst.items[dst_off] = i;
                                moved = true;
                            } else {
                                dst.items[src_off] = i;
                            }
                        },
                        1 => {
                            dst.items[src_off] = i ^ 1;
                        },
                        else => {},
                    }
                    x += 1;
                }
                y += 1;
            }
        }
        if (!moved) {
            break;
        }
    }
    return steps;
}

pub fn main() !void {
    // Merry Christmas!
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip();
    const path = try args.next(allocator).?;
    const input_file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer input_file.close();
    var input = try parseInput(allocator, input_file.reader());
    const result = try solveInput(input, allocator);
    std.debug.print("Result: {}", .{result});
}
