const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Fold = struct {
    vertical: bool,
    center: u16,
};

const Input = struct {
    dots: ArrayList([2]u16),
    folds: ArrayList(Fold),

    fn deinit(self: *@This()) void {
        self.dots.deinit();
        self.folds.deinit();
    }
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var dots = ArrayList([2]u16).init(allocator);
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        if (line_buffer.items.len == 0) {
            break;
        }
        var coords: [2]u16 = undefined;
        var coord_iter = std.mem.split(line_buffer.items, ",");
        for (coords) |*coord| {
            coord.* = try std.fmt.parseUnsigned(u16, coord_iter.next().?, 10);
        }
        try dots.append(coords);
    }
    var folds = ArrayList(Fold).init(allocator);
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        var data_iter = std.mem.split(line_buffer.items[11..], "=");
        try folds.append(Fold{
            .vertical = data_iter.next().?[0] == 'y',
            .center = try std.fmt.parseUnsigned(u16, data_iter.next().?, 10),
        });
    }
    return Input{
        .dots = dots,
        .folds = folds,
    };
}

fn do_fold(dots: *ArrayList([2]u16), fold: Fold) void {
    var i: usize = 0;
    outer: while (i < dots.items.len) {
        var dot = dots.items[i];
        var coord = &dot[@boolToInt(fold.vertical)];
        if (coord.* > fold.center) {
            coord.* = 2 * fold.center - coord.*;
            for (dots.items) |other_dot| {
                if (std.mem.eql(u16, &other_dot, &dot)) {
                    _ = dots.swapRemove(i);
                    continue :outer;
                }
            }
            dots.items[i] = dot;
        }
        i += 1;
    }
}

fn part1(input: *Input) void {
    do_fold(&input.dots, input.folds.items[0]);
    std.debug.print("Result: {}\n", .{input.dots.items.len});
}

fn part2(input: *Input, allocator: *Allocator) !void {
    for (input.folds.items) |fold| {
        do_fold(&input.dots, fold);
    }

    var size = [2]usize{ 0, 0 };
    for (input.dots.items) |dot| {
        for (dot) |coord, i| {
            if (coord + 1 > size[i]) {
                size[i] = coord + 1;
            }
        }
    }

    var grid = ArrayList(bool).init(allocator);
    try grid.appendNTimes(false, size[0] * size[1]);

    for (input.dots.items) |dot| {
        grid.items[dot[1] * size[0] + dot[0]] = true;
    }

    var y: usize = 0;
    while (y < size[1]) : ({
        y += 1;
    }) {
        var x: usize = 0;
        while (x < size[0]) : ({
            x += 1;
        }) {
            const char: u8 = if (grid.items[y * size[0] + x]) '#' else ' ';
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
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
        1 => part1(&input),
        2 => try part2(&input, allocator),
        else => unreachable,
    };
}
