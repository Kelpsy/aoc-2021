const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Input = struct {
    template: ArrayList(u5),
    rules: ArrayList(u5),

    fn deinit(self: *@This()) void {
        self.template.deinit();
        self.rules.deinit();
    }
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var template = ArrayList(u5).init(allocator);
    {
        try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);
        for (line_buffer.items) |char, i| {
            try template.append(@truncate(u5, char - 'A'));
        }
        _ = try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);
    }
    var rules = ArrayList(u5).init(allocator);
    try rules.appendNTimes(0, 1 << 10);
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        var data_iter = std.mem.split(line_buffer.items, " -> ");
        const pair = data_iter.next().?;
        rules.items[@as(usize, pair[0] - 'A') << 5 | (pair[1] - 'A')] = @truncate(u5, data_iter.next().?[0] - 'A');
    }
    return Input{
        .template = template,
        .rules = rules,
    };
}

fn expand(input: *Input, steps_: u8, allocator: *Allocator) !u64 {
    var steps = steps_;

    var pair_counts = ArrayList(u64).init(allocator);
    defer pair_counts.deinit();
    try pair_counts.appendNTimes(0, 1 << 10);

    var counts = std.mem.zeroes([32]u64);
    counts[input.template.items[0]] = 1;
    counts[input.template.items[input.template.items.len - 1]] = 1;

    {
        var i: usize = 0;
        while (i < input.template.items.len - 1) : ({
            i += 1;
        }) {
            const pair_index = @as(usize, input.template.items[i]) << 5 | input.template.items[i + 1];
            pair_counts.items[pair_index] += 1;
        }
    }

    while (steps != 0) : ({
        steps -= 1;
    }) {
        var new_pair_counts = ArrayList(u64).init(allocator);
        try new_pair_counts.appendNTimes(0, 1 << 10);
        for (pair_counts.items) |pair_count, pair| {
            const middle = @as(usize, input.rules.items[pair]);
            new_pair_counts.items[(pair & ~@as(usize, 0x1F)) | middle] += pair_count;
            new_pair_counts.items[middle << 5 | (pair & 0x1F)] += pair_count;
        }
        pair_counts.deinit();
        pair_counts = new_pair_counts;
    }

    for (pair_counts.items) |pair_count, pair| {
        counts[pair >> 5] += pair_count;
        counts[pair & 0x1F] += pair_count;
    }

    var max: u64 = 0;
    var min = std.math.inf_u64;
    for (counts) |count| {
        if (count > max) {
            max = count;
        }
        if (count < min and count != 0) {
            min = count;
        }
    }

    return (max - min) >> 1;
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
    const result = switch (part) {
        1 => try expand(&input, 10, allocator),
        2 => try expand(&input, 40, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}", .{result});
}
