const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.hash_map.HashMap;

const OperandTy = enum {
    Value,
    Reg,
};

const Operand = struct { ty: OperandTy, contents: union {
    value: i64,
    reg: u2,
} };

const InstrTy = enum {
    Add,
    Mul,
    Div,
    Mod,
    Eql,
};

const Instr = struct {
    ty: InstrTy,
    reg: u2,
    op: Operand,
};

const Input = struct {
    instrs: ArrayList(ArrayList(Instr)),

    fn deinit(self: *@This()) void {
        for (self.instrs.items) |digit_instrs| {
            digit_instrs.deinit();
        }
        self.instrs.deinit();
    }
};

fn parseInput(allocator: *Allocator, reader: std.fs.File.Reader) !Input {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var instrs = ArrayList(ArrayList(Instr)).init(allocator);
    var cur_digit_instrs: ?ArrayList(Instr) = null;
    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        if (std.mem.eql(u8, line_buffer.items, "inp w")) {
            if (cur_digit_instrs) |cur_digit_instrs_| {
                try instrs.append(cur_digit_instrs_);
            }
            cur_digit_instrs = ArrayList(Instr).init(allocator);
        } else {
            var ty: InstrTy = undefined;
            if (std.mem.startsWith(u8, line_buffer.items, "add")) {
                ty = InstrTy.Add;
            } else if (std.mem.startsWith(u8, line_buffer.items, "mul")) {
                ty = InstrTy.Mul;
            } else if (std.mem.startsWith(u8, line_buffer.items, "mod")) {
                ty = InstrTy.Mod;
            } else if (std.mem.startsWith(u8, line_buffer.items, "div")) {
                ty = InstrTy.Div;
            } else if (std.mem.startsWith(u8, line_buffer.items, "eql")) {
                ty = InstrTy.Eql;
            } else {
                @panic("Unexpected instruction");
            }
            const op_reg = line_buffer.items[6] -% 'w';
            var op: Operand = undefined;
            if (op_reg < 4) {
                op = Operand{
                    .ty = OperandTy.Reg,
                    .contents = .{
                        .reg = @truncate(u2, op_reg),
                    },
                };
            } else {
                op = Operand{
                    .ty = OperandTy.Value,
                    .contents = .{
                        .value = try std.fmt.parseInt(i64, line_buffer.items[6..], 10),
                    },
                };
            }
            try cur_digit_instrs.?.append(Instr{
                .ty = ty,
                .reg = @truncate(u2, line_buffer.items[4] - 'w'),
                .op = op,
            });
        }
    }
    if (cur_digit_instrs) |cur_digit_instrs_| {
        try instrs.append(cur_digit_instrs_);
    }
    return Input{ .instrs = instrs };
}

fn solveInput(comptime max: bool, input: *Input, allocator: *Allocator) !u64 {
    var states = HashMap(i64, u64, std.hash_map.AutoContext(i64), 80).init(allocator);
    defer states.deinit();
    try states.put(0, 0);
    var result: u64 = if (max) 0 else @bitCast(u64, @as(i64, -1));
    for (input.instrs.items) |block_instrs, i| {
        var new_states = HashMap(i64, u64, std.hash_map.AutoContext(i64), 80).init(allocator);
        try new_states.ensureCapacity(states.count() * 9);
        var iter = states.iterator();
        while (iter.next()) |state_and_result| {
            var digit: u4 = if (max) 9 else 1;
            const end: u4 = if (max) 0 else 10;
            while (digit != end) : ({
                if (max) {
                    digit -= 1;
                } else {
                    digit += 1;
                }
            }) {
                var regs = [4]i64{ digit, 0, 0, state_and_result.key_ptr.* };
                for (block_instrs.items) |instr| {
                    const a = regs[instr.reg];
                    const b = if (instr.op.ty == OperandTy.Reg) regs[instr.op.contents.reg] else instr.op.contents.value;
                    regs[instr.reg] = switch (instr.ty) {
                        InstrTy.Add => a + b,
                        InstrTy.Mul => a * b,
                        InstrTy.Div => @divTrunc(a, b),
                        InstrTy.Mod => @mod(a, b),
                        InstrTy.Eql => @boolToInt(a == b),
                    };
                }
                if (i == 13) {
                    if (regs[3] == 0) {
                        const output = state_and_result.value_ptr.* * 10 + digit;
                        if (max) {
                            if (output > result) {
                                result = output;
                            }
                        } else if (output < result) {
                            result = output;
                        }
                    }
                } else {
                    const output = state_and_result.value_ptr.* * 10 + digit;
                    if (!new_states.contains(regs[3]) or if (max) new_states.get(regs[3]).? < output else new_states.get(regs[3]).? > output) {
                        try new_states.put(regs[3], output);
                    }
                }
            }
        }
        states.deinit();
        states = new_states;
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
    defer input.deinit();
    const result = switch (part) {
        1 => try solveInput(true, &input, allocator),
        2 => try solveInput(false, &input, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}", .{result});
}
