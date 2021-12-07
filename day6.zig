const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !ArrayList(u8) {
    var result = ArrayList(u8).init(allocator);
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
        try result.append(try std.fmt.parseUnsigned(u8, slice, 10));
    }
    return result;
}

fn inner(memoized: []?usize, remaining_days_: usize) usize {
    var remaining_days = remaining_days_;
    var sum: usize = 1;
    while (remaining_days > 0) {
        const new_days = std.math.max(remaining_days, 9) - 9;
        if (memoized[new_days]) |memoized_value| {
            sum += memoized_value;
        } else {
            const value = inner(memoized, new_days);
            memoized[new_days] = value;
            sum += value;
        }
        remaining_days = std.math.max(remaining_days, 7) - 7;
    }
    return sum;
}

fn calc(days: usize, fish: []const u8, allocator: *Allocator) !usize {
    var memoized = ArrayList(?usize).init(allocator);
    try memoized.appendNTimes(null, days);
    var sum: usize = 0;
    for (fish) |fish_| {
        sum += inner(memoized.items, days - fish_);
    }
    return sum;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip();
    const part = try std.fmt.parseUnsigned(u8, try args.next(allocator).?, 10);
    const path = try args.next(allocator).?;
    const input_file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer input_file.close();
    const fish = try parseInput(allocator, input_file.reader());
    const final_fish = switch (part) {
        1 => try calc(80, fish.items, allocator),
        2 => try calc(256, fish.items, allocator),
        else => unreachable,
    };
    std.debug.print("Fish: {}\n", .{final_fish});
}
