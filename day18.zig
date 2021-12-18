const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const ElementType = enum {
    PairStart,
    PairEnd,
    Number,
};

const Element = struct {
    ty: ElementType,
    value: ?u8,

    fn pairStart() @This() {
        return Element{
            .ty = ElementType.PairStart,
            .value = null,
        };
    }

    fn pairEnd() @This() {
        return Element{
            .ty = ElementType.PairEnd,
            .value = null,
        };
    }

    fn number(value: u8) @This() {
        return Element{
            .ty = ElementType.Number,
            .value = value,
        };
    }
};

const Input = ArrayList(ArrayList(Element));

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var result = ArrayList(ArrayList(Element)).init(allocator);
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        var pair = ArrayList(Element).init(allocator);
        for (line_buffer.items) |char| {
            if (char == '[') {
                try pair.append(Element.pairStart());
            } else if (char == ']') {
                try pair.append(Element.pairEnd());
            } else if (char != ',') {
                try pair.append(Element.number(char - '0'));
            }
        }
        try result.append(pair);
    }
    return result;
}

fn add(a: []const Element, b: []const Element, allocator: *Allocator) !ArrayList(Element) {
    var result = ArrayList(Element).init(allocator);
    try result.insert(0, Element.pairStart());
    try result.appendSlice(a);
    try result.appendSlice(b);
    try result.append(Element.pairEnd());
    outer: while (true) {
        var depth: u8 = 0;

        for (result.items) |element, i| {
            switch (element.ty) {
                ElementType.PairStart => {
                    depth += 1;
                },
                ElementType.PairEnd => {
                    depth -= 1;
                },
                ElementType.Number => {
                    if (depth < 5) {
                        continue;
                    }
                    const next_element = result.items[i + 1];
                    if (next_element.value == null) {
                        continue;
                    }
                    var j = i - 2;
                    while (true) : ({
                        j -= 1;
                    }) {
                        if (result.items[j].ty == ElementType.Number) {
                            result.items[j].value.? += element.value.?;
                            break;
                        }
                        if (j == 0) {
                            break;
                        }
                    }
                    j = i + 3;
                    while (j < result.items.len) : ({
                        j += 1;
                    }) {
                        if (result.items[j].ty == ElementType.Number) {
                            result.items[j].value.? += next_element.value.?;
                            break;
                        }
                    }
                    try result.replaceRange(i - 1, 4, &.{Element.number(0)});
                    continue :outer;
                },
            }
        }
        for (result.items) |element, i| {
            if (element.ty == ElementType.Number and element.value.? > 9) {
                try result.replaceRange(i, 1, &[4]Element{
                    Element.pairStart(),
                    Element.number(element.value.? / 2),
                    Element.number((element.value.? + 1) / 2),
                    Element.pairEnd(),
                });
                continue :outer;
            }
        }
        break;
    }
    return result;
}

fn magnitude(number: []const Element, allocator: *Allocator) !u64 {
    var factor: u64 = 1;
    var indices = ArrayList(u1).init(allocator);
    defer indices.deinit();
    var pair_index: u1 = 0;
    var result: u64 = 0;
    for (number) |element| {
        switch (element.ty) {
            ElementType.PairStart => {
                factor *= 3;
                try indices.append(pair_index);
                pair_index = 0;
                continue;
            },
            ElementType.PairEnd => {
                factor /= 2;
                pair_index = indices.pop();
            },
            ElementType.Number => {
                result += element.value.? * factor;
            },
        }
        pair_index ^= 1;
        if (pair_index == 1) {
            factor = (factor / 3) * 2;
        }
    }
    return result;
}

fn part1(input: *const Input, allocator: *Allocator) !u64 {
    var number = ArrayList(Element).init(allocator);
    try number.appendSlice(input.items[0].items);
    defer number.deinit();
    for (input.items[1..]) |other_number| {
        const new_number = try add(number.items, other_number.items, allocator);
        number.deinit();
        number = new_number;
    }
    return magnitude(number.items, allocator);
}

fn part2(input: *const Input, allocator: *Allocator) !u64 {
    var max_mag: u64 = 0;
    for (input.items) |a, i| {
        for (input.items) |b, j| {
            if (i == j) {
                continue;
            }
            const sum = try add(a.items, b.items, allocator);
            defer sum.deinit();
            const mag = try magnitude(sum.items, allocator);
            if (mag > max_mag) {
                max_mag = mag;
            }
        }
    }
    return max_mag;
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
    defer {
        for (input.items) |pair| {
            pair.deinit();
        }
        input.deinit();
    }
    const result = switch (part) {
        1 => part1(&input, allocator),
        2 => part2(&input, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
