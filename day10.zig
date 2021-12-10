const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !ArrayList(ArrayList(u8)) {
    var result = ArrayList(ArrayList(u8)).init(allocator);
    while (true) {
        var line = ArrayList(u8).init(allocator);
        reader.readUntilDelimiterArrayList(&line, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        try result.append(line);
    }
    return result;
}

fn delimMap() [256]u8 {
    var delim_map = std.mem.zeroes([256]u8);
    delim_map['('] = ')';
    delim_map['['] = ']';
    delim_map['{'] = '}';
    delim_map['<'] = '>';
    return delim_map;
}

fn part1(input: []const ArrayList(u8), allocator: *Allocator) !u64 {
    const delim_map = delimMap();
    var score: u64 = 0;
    var stack = ArrayList(u8).init(allocator);
    for (input) |line| {
        try stack.resize(0);
        for (line.items) |char| {
            if (delim_map[char] != 0) {
                try stack.append(delim_map[char]);
            } else if (stack.items.len > 0 and stack.items[stack.items.len - 1] == char) {
                _ = stack.pop();
            } else {
                score += @as(u64, switch (char) {
                    ')' => 3,
                    ']' => 57,
                    '}' => 1197,
                    '>' => 25137,
                    else => unreachable,
                });
                break;
            }
        }
    }
    return score;
}

fn part2(input: []const ArrayList(u8), allocator: *Allocator) !u64 {
    const delim_map = delimMap();
    var scores = ArrayList(u64).init(allocator);
    var stack = ArrayList(u8).init(allocator);
    outer: for (input) |line| {
        try stack.resize(0);
        for (line.items) |char| {
            if (delim_map[char] != 0) {
                try stack.append(delim_map[char]);
            } else if (stack.items.len > 0 and stack.items[stack.items.len - 1] == char) {
                _ = stack.pop();
            } else {
                continue :outer;
            }
        }
        var score: u64 = 0;
        while (stack.items.len != 0) {
            score = score * 5 + @as(u64, switch (stack.pop()) {
                ')' => 1,
                ']' => 2,
                '}' => 3,
                '>' => 4,
                else => unreachable,
            });
        }
        try scores.append(score);
    }
    std.sort.sort(u64, scores.items, {}, comptime std.sort.asc(u64));
    return scores.items[scores.items.len / 2];
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
        1 => try part1(input.items, allocator),
        2 => try part2(input.items, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
