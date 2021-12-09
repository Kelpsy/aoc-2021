const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Input = struct {
    entries: ArrayList(u8),
    size: [2]usize,
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var entries = ArrayList(u8).init(allocator);
    var size = [2]usize{ 0, 0 };
    var line_buffer = ArrayList(u8).init(allocator);
    var finished = false;
    while (!finished) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        size[0] = line_buffer.items.len;
        size[1] += 1;
        for (line_buffer.items) |char| {
            try entries.append(char - '0');
        }
    }
    return Input{ .entries = entries, .size = size };
}

fn part1(entries: []const u8, size: [2]usize) !usize {
    var sum: usize = 0;
    var y: usize = 0;
    while (y < size[1]) : ({
        y += 1;
    }) {
        var x: usize = 0;
        while (x < size[0]) : ({
            x += 1;
        }) {
            const i = y * size[0] + x;
            const entry = entries[i];
            if ((x > 0 and entries[i - 1] <= entry) or (x < size[0] - 1 and entries[i + 1] <= entry) or (y > 0 and entries[i - size[0]] <= entry) or (y < size[1] - 1 and entries[i + size[0]] <= entry)) {
                continue;
            }
            sum += 1 + entry;
        }
    }
    return sum;
}

fn part2(entries: []const u8, size: [2]usize, allocator: *Allocator) !usize {
    var basins = ArrayList(usize).init(allocator);
    var traversed = ArrayList(bool).init(allocator);
    try traversed.appendNTimes(false, size[0] * size[1]);
    for (entries) |entry, i| {
        if (entry == 9) {
            traversed.items[i] = true;
        }
    }

    var y: usize = 0;
    while (y < size[1]) : ({
        y += 1;
    }) {
        var x: usize = 0;
        while (x < size[0]) : ({
            x += 1;
        }) {
            {
                const i = y * size[0] + x;
                const entry = entries[i];
                if ((x > 0 and entries[i - 1] <= entry) or (x < size[0] - 1 and entries[i + 1] <= entry) or (y > 0 and entries[i - size[0]] <= entry) or (y < size[1] - 1 and entries[i + size[0]] <= entry)) {
                    continue;
                }
                traversed.items[i] = true;
            }
            var basin_size: usize = 0;
            var to_traverse = ArrayList([2]usize).init(allocator);
            try to_traverse.append(.{ x, y });
            while (to_traverse.items.len != 0) {
                const coords = to_traverse.swapRemove(to_traverse.items.len - 1);
                basin_size += 1;
                const i = coords[1] * size[0] + coords[0];
                traversed.items[i] = true;
                if (coords[0] > 0 and !traversed.items[i - 1]) {
                    traversed.items[i - 1] = true;
                    try to_traverse.append(.{ coords[0] - 1, coords[1] });
                }
                if (coords[0] < size[0] - 1 and !traversed.items[i + 1]) {
                    traversed.items[i + 1] = true;
                    try to_traverse.append(.{ coords[0] + 1, coords[1] });
                }
                if (coords[1] > 0 and !traversed.items[i - size[0]]) {
                    traversed.items[i - size[0]] = true;
                    try to_traverse.append(.{ coords[0], coords[1] - 1 });
                }
                if (coords[1] < size[1] - 1 and !traversed.items[i + size[0]]) {
                    traversed.items[i + size[0]] = true;
                    try to_traverse.append(.{ coords[0], coords[1] + 1 });
                }
            }
            try basins.append(basin_size);
        }
    }

    std.sort.sort(usize, basins.items, {}, comptime std.sort.desc(usize));
    return basins.items[0] * basins.items[1] * basins.items[2];
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
        1 => try part1(input.entries.items, input.size),
        2 => try part2(input.entries.items, input.size, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
