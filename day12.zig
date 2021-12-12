const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.hash_map.HashMap;

const CaveConnections = HashMap([]const u8, ArrayList([]const u8), std.hash_map.StringContext, 80);
const Input = struct {
    string_pool: ArrayList(ArrayList(u8)),
    cave_connections: CaveConnections,

    fn deinit(self: *@This()) void {
        self.string_pool.deinit();
        self.cave_connections.deinit();
    }
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var cave_connections = CaveConnections.init(allocator);
    var string_pool = ArrayList(ArrayList(u8)).init(allocator);
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        var caves: [2][]const u8 = undefined;
        var cave_iter = std.mem.split(line_buffer.items, "-");
        for (caves) |*cave| {
            var cave_owned = ArrayList(u8).init(allocator);
            try cave_owned.appendSlice(cave_iter.next().?);
            try string_pool.append(cave_owned);
            cave.* = cave_owned.items;
        }
        for (caves) |start, i| {
            const end = caves[i ^ 1];
            if (cave_connections.getPtr(start)) |list| {
                try list.append(end);
            } else {
                var list = ArrayList([]const u8).init(allocator);
                try list.append(end);
                try cave_connections.put(start, list);
            }
        }
    }
    return Input{
        .string_pool = string_pool,
        .cave_connections = cave_connections,
    };
}

const Traversed = HashMap([]const u8, u8, std.hash_map.StringContext, 80);

fn traverse(start: []const u8, small_threshold: u8, input: *const Input, traversed: *const Traversed, allocator: *Allocator) std.mem.Allocator.Error!usize {
    var result: usize = 0;
    for (input.cave_connections.get(start).?.items) |new_start| {
        if (std.mem.eql(u8, new_start, "end")) {
            result += 1;
        } else if (std.ascii.isUpper(new_start[0])) {
            result += try traverse(new_start, small_threshold, input, traversed, allocator);
        } else {
            const times_traversed = traversed.get(new_start) orelse 0;
            if (times_traversed < small_threshold) {
                var new_traversed = try traversed.clone();
                defer new_traversed.deinit();
                try new_traversed.put(new_start, times_traversed + 1);
                result += try traverse(new_start, if (times_traversed == 1) 1 else small_threshold, input, &new_traversed, allocator);
            }
        }
    }
    return result;
}

fn traverse_graph(input: Input, small_threshold: u8, allocator: *Allocator) !usize {
    var traversed = Traversed.init(allocator);
    defer traversed.deinit();
    try traversed.put("start", small_threshold);
    return traverse("start", small_threshold, &input, &traversed, allocator);
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
        1 => try traverse_graph(input, 1, allocator),
        2 => try traverse_graph(input, 2, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
