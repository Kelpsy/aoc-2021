const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Entry = struct {
    digits: [10]u7,
    value: [4]u7,
};

fn convertLinesToMask(lines: []const u8) u7 {
    var result: u7 = 0;
    for (lines) |line| {
        result |= @as(u7, 1) << @truncate(u3, line - 'a');
    }
    return result;
}

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !ArrayList(Entry) {
    var result = ArrayList(Entry).init(allocator);
    var entry_buffer = ArrayList(u8).init(allocator);
    var finished = false;
    while (!finished) {
        reader.readUntilDelimiterArrayList(&entry_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        var digits_value_iter = std.mem.split(entry_buffer.items, " | ");
        var entry = std.mem.zeroes(Entry);
        var digits = std.mem.split(digits_value_iter.next().?, " ");
        for (entry.digits) |*digit| {
            digit.* = convertLinesToMask(digits.next().?);
        }
        var value_digits = std.mem.split(digits_value_iter.next().?, " ");
        for (entry.value) |*digit| {
            digit.* = convertLinesToMask(value_digits.next().?);
        }
        try result.append(entry);
    }
    return result;
}

fn part1(entries: []const Entry) !u32 {
    var result: u32 = 0;
    for (entries) |entry| {
        for (entry.value) |digit| {
            switch (@popCount(u7, digit)) {
                2, 3, 4, 7 => {
                    result += 1;
                },
                else => {},
            }
        }
    }
    return result;
}

fn part2(entries: []const Entry) !u32 {
    var sum: u32 = 0;
    for (entries) |entry| {
        var possible_mappings = [7]u7{ 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F };
        for (entry.digits) |digit| {
            const lines = @popCount(u7, digit);
            const to_include = [8][]const u3{
                &.{},
                &.{},
                &.{ 2, 5 },
                &.{ 0, 2, 5 },
                &.{ 1, 2, 3, 5 },
                &.{ 0, 3, 6 },
                &.{ 0, 1, 5, 6 },
                &.{},
            };
            const to_exclude = [8][]const u3{
                &.{},
                &.{},
                &.{ 0, 1, 3, 4, 6 },
                &.{ 1, 3, 4, 6 },
                &.{ 0, 4, 6 },
                &.{},
                &.{},
                &.{},
            };
            for (to_include[lines]) |i| {
                possible_mappings[i] &= digit;
            }
            for (to_exclude[lines]) |i| {
                possible_mappings[i] &= ~digit;
            }
        }
        for (possible_mappings) |mapping, i| {
            if (@popCount(u7, mapping) == 1) {
                for (possible_mappings) |*other_mapping, j| {
                    if (j == i) {
                        continue;
                    }
                    other_mapping.* &= ~mapping;
                }
            }
        }

        const number_lines = [10]u7{
            0x77,
            0x24,
            0x5D,
            0x6D,
            0x2E,
            0x6B,
            0x7B,
            0x25,
            0x7F,
            0x6F,
        };

        var multiplier: u32 = 1000;
        for (entry.value) |value_digit| {
            var orig_lines: u7 = 0;
            for (possible_mappings) |mapping, i| {
                if (value_digit & mapping != 0) {
                    orig_lines |= @as(u7, 1) << @truncate(u3, i);
                }
            }
            sum += (for (number_lines) |lines, number| {
                if (orig_lines == lines) {
                    break @truncate(u32, number);
                }
            } else unreachable) * multiplier;
            multiplier /= 10;
        }
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
    const entries = try parseInput(allocator, input_file.reader());
    const result = switch (part) {
        1 => try part1(entries.items),
        2 => try part2(entries.items),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
