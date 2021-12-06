const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn readLine(line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !?[]u8 {
    reader.readUntilDelimiterArrayList(line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
        error.EndOfStream => return null,
        else => return e,
    };
    return line_buffer.items;
}

const BoardNumber = struct {
    number: u8,
    called: bool,
};

const Board = struct { numbers: [5][5]BoardNumber };

fn checkBoard(board: *const Board) bool {
    for (board.numbers) |row| {
        if (for (row) |number| {
            if (!number.called) {
                break false;
            }
        } else true) {
            return true;
        }
    }

    var col_index: usize = 0;
    return while (col_index < 5) : ({
        col_index += 1;
    }) {
        if (for (board.numbers) |row| {
            if (!row[col_index].called) {
                break false;
            }
        } else true) {
            break true;
        }
    } else false;
}

fn parse(numbers: *ArrayList(u8), boards: *ArrayList(Board), line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !void {
    const numbers_line = (try readLine(line_buffer, reader)) orelse unreachable;
    {
        var iter = std.mem.split(numbers_line, ",");
        while (true) {
            try numbers.append(try std.fmt.parseUnsigned(u8, iter.next() orelse break, 10));
        }
    }

    outer: while (true) {
        _ = try readLine(line_buffer, reader);
        var board = Board{ .numbers = std.mem.zeroes([5][5]BoardNumber) };
        var i: usize = 0;
        while (i < 5) : ({
            i += 1;
        }) {
            const line = (try readLine(line_buffer, reader)) orelse break :outer;
            var iter = std.mem.split(line, " ");
            var j: usize = 0;
            while (j < 5) {
                const str = iter.next() orelse break;
                if (str.len == 0) {
                    continue;
                }
                board.numbers[i][j] = .{ .number = try std.fmt.parseUnsigned(u8, str, 10), .called = false };
                j += 1;
            }
        }
        try boards.append(board);
    }
}

fn part1(allocator: *Allocator, line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var numbers = ArrayList(u8).init(allocator);
    var boards = ArrayList(Board).init(allocator);
    try parse(&numbers, &boards, line_buffer, reader);

    for (numbers.items) |number| {
        for (boards.items) |*board| {
            for (board.numbers) |*row| {
                for (row) |*board_number| {
                    if (board_number.number == number) {
                        board_number.called = true;
                    }
                }
            }

            if (checkBoard(board)) {
                var sum: u32 = 0;
                for (board.numbers) |row| {
                    for (row) |board_number| {
                        if (!board_number.called) {
                            sum += board_number.number;
                        }
                    }
                }
                return sum * number;
            }
        }
    }

    unreachable;
}

fn part2(allocator: *Allocator, line_buffer: *ArrayList(u8), reader: std.fs.File.Reader) !u32 {
    var numbers = ArrayList(u8).init(allocator);
    var boards = ArrayList(Board).init(allocator);
    var last_product: ?u32 = null;
    try parse(&numbers, &boards, line_buffer, reader);

    for (numbers.items) |number| {
        var i: usize = 0;
        while (i < boards.items.len) {
            const board = &boards.items[i];
            for (board.numbers) |*row| {
                for (row) |*board_number| {
                    if (board_number.number == number) {
                        board_number.called = true;
                    }
                }
            }

            if (checkBoard(board)) {
                var sum: u32 = 0;
                for (board.numbers) |row| {
                    for (row) |board_number| {
                        if (!board_number.called) {
                            sum += board_number.number;
                        }
                    }
                }
                last_product = sum * number;
                _ = boards.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    return last_product.?;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip();
    const part = try std.fmt.parseUnsigned(u8, try args.next(allocator).?, 10);
    const path = try args.next(allocator).?;
    const input_file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer input_file.close();
    var line_buffer = ArrayList(u8).init(allocator);
    const product = switch (part) {
        1 => try part1(allocator, &line_buffer, input_file.reader()),
        2 => try part2(allocator, &line_buffer, input_file.reader()),
        else => unreachable,
    };
    std.debug.print("Product: {}", .{product});
}
