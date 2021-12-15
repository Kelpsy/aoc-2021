const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const PriorityQueue = std.PriorityQueue;

const Grid = struct {
    risks: ArrayList(u8),
    size: [2]usize,

    fn deinit(self: *@This()) void {
        self.risks.deinit();
    }
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Grid {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var risks = ArrayList(u8).init(allocator);
    var size = [2]usize{ 0, 0 };
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        size[0] = line_buffer.items.len;
        size[1] += 1;
        for (line_buffer.items) |char, i| {
            try risks.append(char - '0');
        }
    }
    return Grid{
        .risks = risks,
        .size = size,
    };
}

const Cell = struct {
    coords: [2]usize,
    risk: u32,
};

fn cellLessThan(a: Cell, b: Cell) std.math.Order {
    return std.math.order(a.risk, b.risk);
}

fn addCell(x: usize, y: usize, baseRisk: u32, visited: []bool, queue: *PriorityQueue(Cell), grid: *Grid) !void {
    const gridIndex = y * grid.size[0] + x;
    if (visited[gridIndex]) {
        return;
    }
    visited[gridIndex] = true;
    try queue.add(Cell{
        .coords = .{ x, y },
        .risk = baseRisk + grid.risks.items[gridIndex],
    });
}

fn findLowestRiskPath(grid: *Grid, allocator: *Allocator) !u32 {
    var visited = ArrayList(bool).init(allocator);
    try visited.appendNTimes(false, grid.size[0] * grid.size[1]);
    visited.items[0] = true;
    var queue = PriorityQueue(Cell).init(allocator, cellLessThan);
    try queue.add(Cell{ .coords = .{ 0, 0 }, .risk = 0 });
    const max_coords = [2]usize{ grid.size[0] - 1, grid.size[1] - 1 };
    while (queue.removeOrNull()) |cell| {
        const x = cell.coords[0];
        const y = cell.coords[1];
        if (x == max_coords[0] and y == max_coords[1]) {
            return cell.risk;
        }
        if (x > 0) {
            try addCell(x - 1, y, cell.risk, visited.items, &queue, grid);
        }
        if (x < max_coords[0]) {
            try addCell(x + 1, y, cell.risk, visited.items, &queue, grid);
        }
        if (y > 0) {
            try addCell(x, y - 1, cell.risk, visited.items, &queue, grid);
        }
        if (y < max_coords[1]) {
            try addCell(x, y + 1, cell.risk, visited.items, &queue, grid);
        }
    }
    unreachable;
}

fn part1(input: *Grid, allocator: *Allocator) !u32 {
    return findLowestRiskPath(input, allocator);
}

fn part2(input: *Grid, allocator: *Allocator) !u32 {
    const new_size = [2]usize{ input.size[0] * 5, input.size[1] * 5 };
    var new_risks = ArrayList(u8).init(allocator);
    try new_risks.ensureTotalCapacity(new_size[0] * new_size[1]);
    var y: usize = 0;
    while (y < new_size[1]) : ({
        y += 1;
    }) {
        const y_contribution = @truncate(u8, y / input.size[1]);
        const orig_y = y % input.size[1];
        var x: usize = 0;
        while (x < new_size[1]) : ({
            x += 1;
        }) {
            const x_contribution = @truncate(u8, x / input.size[0]);
            const orig_x = x % input.size[0];
            try new_risks.append((input.risks.items[orig_y * input.size[1] + orig_x] + x_contribution + y_contribution - 1) % 9 + 1);
        }
    }
    var new_grid = Grid{ .risks = new_risks, .size = new_size };
    defer new_grid.deinit();
    return findLowestRiskPath(&new_grid, allocator);
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
        1 => try part1(&input, allocator),
        2 => try part2(&input, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}", .{result});
}
