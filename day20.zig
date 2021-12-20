const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Image = struct {
    pixels: ArrayList(u1),
    border: u1,
    size: [2]usize,

    fn deinit(self: *@This()) void {
        self.pixels.deinit();
    }

    fn getPixel(self: *const @This(), x: usize, y: usize) u1 {
        return if (x < self.size[0] and y < self.size[1]) self.pixels.items[y * self.size[0] + x] else self.border;
    }
};

const AlgorithmData = [512]u1;

const Input = struct {
    algo_data: AlgorithmData,
    image: Image,

    fn deinit(self: *@This()) void {
        self.image.deinit();
    }
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    var algo_data = std.mem.zeroes([512]u1);
    try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);
    for (line_buffer.items) |char, i| {
        if (char == '#') {
            algo_data[i] = 1;
        }
    }

    try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);

    var pixels = ArrayList(u1).init(allocator);
    var size = [2]usize{ 0, 0 };
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        size[0] = line_buffer.items.len;
        size[1] += 1;
        for (line_buffer.items) |char, i| {
            try pixels.append(if (char == '#') 1 else 0);
        }
    }

    return Input{
        .algo_data = algo_data,
        .image = Image{
            .pixels = pixels,
            .border = 0,
            .size = size,
        },
    };
}

fn applyAlgorithm(image: *Image, algo_data: *const AlgorithmData, allocator: *Allocator) !Image {
    const new_size = [2]usize{ image.size[0] + 2, image.size[1] + 2 };
    var new_pixels = try ArrayList(u1).initCapacity(allocator, new_size[0] * new_size[1]);

    var y: usize = 0;
    while (y < new_size[1]) : ({
        y += 1;
    }) {
        var x: usize = 0;
        while (x < new_size[0]) : ({
            x += 1;
        }) {
            var algo_index: usize = 0;
            inline for ([9][2]u8{
                .{ 2, 2 }, .{ 1, 2 }, .{ 0, 2 },
                .{ 2, 1 }, .{ 1, 1 }, .{ 0, 1 },
                .{ 2, 0 }, .{ 1, 0 }, .{ 0, 0 },
            }) |offset, i| {
                algo_index |= @as(usize, image.getPixel(x -% offset[0], y -% offset[1])) << (8 - i);
            }
            try new_pixels.append(algo_data[algo_index]);
        }
    }

    return Image{
        .pixels = new_pixels,
        .border = algo_data[@as(usize, @bitCast(u9, @as(i9, @bitCast(i1, image.border))))],
        .size = new_size,
    };
}

fn enhance(input: Input, iterations: u8, allocator: *Allocator) !usize {
    var image = input.image;
    defer image.deinit();
    var iteration: u8 = 0;
    while (iteration < iterations) : ({
        iteration += 1;
    }) {
        const new_image = try applyAlgorithm(&image, &input.algo_data, allocator);
        image.deinit();
        image = new_image;
    }
    var result: usize = 0;
    for (image.pixels.items) |pixel| {
        if (pixel != 0) {
            result += 1;
        }
    }
    return result;
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
    const result = switch (part) {
        1 => try enhance(input, 2, allocator),
        2 => try enhance(input, 50, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
