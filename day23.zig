const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const PriorityQueue = std.PriorityQueue;

fn Room(comptime size: usize) type {
    return struct {
        contents: [size]u2,
        occupied: u3,

        fn containsOnly(self: *const @This(), value: u2) bool {
            for (self.contents[0..self.occupied]) |amphipod| {
                if (amphipod != value) {
                    return false;
                }
            }
            return true;
        }
    };
}

fn Space(comptime room_size: u3) type {
    return struct {
        is_room: bool,
        contents: union {
            hallway: ?u2,
            room: Room(room_size),
        },

        fn canBeEnteredBy(self: *const @This(), value: u2) bool {
            if (self.is_room) {
                return self.contents.room.containsOnly(value);
            } else {
                return self.contents.hallway == null;
            }
        }
    };
}

const SpaceAndDistance = struct {
    i: usize,
    d: u8,

    fn lessThan(a: @This(), b: @This()) std.math.Order {
        return std.math.order(a.d, b.d);
    }
};

const space_connections = [11][]const SpaceAndDistance{
    &.{ .{ .i = 5, .d = 2 }, .{ .i = 6, .d = 2 } }, // 0: Room A
    &.{ .{ .i = 6, .d = 2 }, .{ .i = 7, .d = 2 } }, // 1: Room B
    &.{ .{ .i = 7, .d = 2 }, .{ .i = 8, .d = 2 } }, // 2: Room C
    &.{ .{ .i = 8, .d = 2 }, .{ .i = 9, .d = 2 } }, // 3: Room D
    &.{.{ .i = 5, .d = 1 }}, // 4: Hallway space 0
    &.{ .{ .i = 4, .d = 1 }, .{ .i = 6, .d = 2 }, .{ .i = 0, .d = 2 } }, // 5: Hallway space 1
    &.{ .{ .i = 5, .d = 2 }, .{ .i = 7, .d = 2 }, .{ .i = 0, .d = 2 }, .{ .i = 1, .d = 2 } }, // 6: Hallway space 2
    &.{ .{ .i = 6, .d = 2 }, .{ .i = 8, .d = 2 }, .{ .i = 1, .d = 2 }, .{ .i = 2, .d = 2 } }, // 7: Hallway space 3
    &.{ .{ .i = 7, .d = 2 }, .{ .i = 9, .d = 2 }, .{ .i = 2, .d = 2 }, .{ .i = 3, .d = 2 } }, // 8: Hallway space 4
    &.{ .{ .i = 8, .d = 2 }, .{ .i = 10, .d = 1 }, .{ .i = 3, .d = 2 } }, // 9: Hallway space 5
    &.{.{ .i = 9, .d = 1 }}, // 1: Hallway space 6
};

const Path = ArrayList(SpaceAndDistance);

const Paths = struct {
    contents: [11][11]Path,

    fn deinit(self: *@This()) void {
        for (self.contents) |space_solutions| {
            for (space_solutions) |space_solution| {
                space_solution.deinit();
            }
        }
    }
};

fn computePaths(allocator: *Allocator) !Paths {
    var result: Paths = Paths{ .contents = undefined };
    for (result.contents) |*solutions, dst_space_index| {
        for (solutions) |*solution, src_space_index| {
            var came_from: [11]?SpaceAndDistance = undefined;
            for (came_from) |*element| {
                element.* = null;
            }
            var queue = PriorityQueue(SpaceAndDistance).init(allocator, SpaceAndDistance.lessThan);
            defer queue.deinit();
            try queue.add(.{ .i = src_space_index, .d = 0 });
            came_from[src_space_index] = .{ .i = src_space_index, .d = 0 };
            while (queue.removeOrNull()) |space| {
                if (space.i == dst_space_index) {
                    break;
                }
                for (space_connections[space.i]) |connection| {
                    if (came_from[connection.i] == null) {
                        came_from[connection.i] = SpaceAndDistance{ .i = space.i, .d = connection.d };
                        try queue.add(connection);
                    }
                }
            }
            var path = Path.init(allocator);
            var node = came_from[dst_space_index].?;
            while (node.d != 0) {
                try path.insert(0, node);
                node = came_from[node.i].?;
            }
            solution.* = path;
        }
    }
    return result;
}

const energy_multipliers = [4]u32{
    1,
    10,
    100,
    1000,
};

fn State(comptime room_size: u3) type {
    return struct {
        energy: u32,
        spaces: [11]Space(room_size),

        fn lessThan(a: @This(), b: @This()) std.math.Order {
            return std.math.order(a.energy, b.energy);
        }

        fn canFollowPath(self: *const @This(), path: *const Path, room_index: usize, amphipod: u2) bool {
            if (!self.spaces[room_index].canBeEnteredBy(amphipod)) {
                return false;
            }
            for (path.items[1..path.items.len]) |space_and_distance| {
                if (!self.spaces[space_and_distance.i].canBeEnteredBy(amphipod)) {
                    return false;
                }
            }
            return true;
        }

        fn addAllHallwayPaths(self: *const @This(), room_index: usize, amphipod: u2, paths: *const Paths, queue: *PriorityQueue(@This())) !void {
            const base_distance = room_size - self.spaces[room_index].contents.room.occupied;
            var i: usize = 4;
            while (i < 11) : ({
                i += 1;
            }) {
                const path = &paths.contents[i][room_index];
                if (self.canFollowPath(path, i, amphipod)) {
                    const multiplier = energy_multipliers[amphipod];
                    var new_state = self.*;
                    for (path.items) |new_space| {
                        new_state.energy += new_space.d * multiplier;
                    }
                    new_state.energy += base_distance * multiplier;
                    new_state.spaces[room_index].contents.room.occupied -= 1;
                    new_state.spaces[i].contents.hallway = amphipod;
                    try queue.add(new_state);
                }
            }
        }
    };
}

fn parseInput(comptime room_size: u3, allocator: *Allocator, reader: std.fs.File.Reader) !State(room_size) {
    var line_buffer = ArrayList(u8).init(allocator);
    defer line_buffer.deinit();
    var spaces: [11]Space(room_size) = undefined;
    for (spaces[0..4]) |*space| {
        space.* = Space(room_size){
            .is_room = true,
            .contents = .{ .room = Room(room_size){
                .contents = std.mem.zeroes([room_size]u2),
                .occupied = room_size,
            } },
        };
    }
    for (spaces[4..]) |*space| {
        space.* = Space(room_size){
            .is_room = false,
            .contents = .{ .hallway = null },
        };
    }

    try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);
    try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);
    const trimmed = line_buffer.items[3..];
    for ([2]u3{ room_size - 1, 0 }) |i| {
        try reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.inf_u64);
        for (spaces[0..4]) |*space, j| {
            space.contents.room.contents[i] = @truncate(u2, trimmed[j * 2] - 'A');
        }
    }

    if (room_size == 4) {
        spaces[0].contents.room.contents[2] = 3;
        spaces[0].contents.room.contents[1] = 3;
        spaces[1].contents.room.contents[2] = 2;
        spaces[1].contents.room.contents[1] = 1;
        spaces[2].contents.room.contents[2] = 1;
        spaces[2].contents.room.contents[1] = 0;
        spaces[3].contents.room.contents[2] = 0;
        spaces[3].contents.room.contents[1] = 2;
    }

    return State(room_size){
        .energy = 0,
        .spaces = spaces,
    };
}

fn solveInput(comptime room_size: u3, input: State(room_size), paths: *const Paths, allocator: *Allocator) !u32 {
    var state_queue = PriorityQueue(State(room_size)).init(allocator, State(room_size).lessThan);
    try state_queue.add(input);
    outer: while (state_queue.removeOrNull()) |state_| {
        var state = state_;

        const all_filled = for (state.spaces[0..4]) |space, space_index| {
            const room = &space.contents.room;
            if (room.occupied != room_size or !room.containsOnly(@truncate(u2, space_index))) {
                break false;
            }
        } else true;
        if (all_filled) {
            return state.energy;
        }

        fill_rooms: while (true) {
            var filled_spaces: usize = 0;
            for (state.spaces) |*space, space_index| {
                if (space.is_room) {
                    var room = &space.contents.room;
                    if (room.containsOnly(@truncate(u2, space_index))) {
                        if (room.occupied == room_size) {
                            filled_spaces += 1;
                            if (filled_spaces == 4) {
                                try state_queue.add(state);
                                continue :outer;
                            }
                        }
                    } else {
                        const amphipod = room.contents[room.occupied - 1];
                        const path = &paths.contents[amphipod][space_index];
                        if (state.canFollowPath(path, amphipod, amphipod)) {
                            const multiplier = energy_multipliers[amphipod];
                            for (path.items) |new_space| {
                                state.energy += new_space.d * multiplier;
                            }
                            state.energy += (room_size - room.occupied) * multiplier;
                            room.occupied -= 1;
                            var new_room = &state.spaces[amphipod].contents.room;
                            new_room.contents[new_room.occupied] = amphipod;
                            new_room.occupied += 1;
                            state.energy += (room_size - new_room.occupied) * multiplier;
                            continue :fill_rooms;
                        }
                    }
                } else {
                    if (space.contents.hallway) |amphipod| {
                        const path = &paths.contents[amphipod][space_index];
                        if (state.canFollowPath(path, amphipod, amphipod)) {
                            const multiplier = energy_multipliers[amphipod];
                            for (path.items) |new_space| {
                                state.energy += new_space.d * multiplier;
                            }
                            space.contents.hallway = null;
                            var new_room = &state.spaces[amphipod].contents.room;
                            new_room.contents[new_room.occupied] = amphipod;
                            new_room.occupied += 1;
                            state.energy += (room_size - new_room.occupied) * multiplier;
                            continue :fill_rooms;
                        }
                    }
                }
            }
            break;
        }

        for (state.spaces[0..4]) |space, space_index| {
            var room = &space.contents.room;
            if (room.containsOnly(@truncate(u2, space_index))) {
                continue;
            }
            try state.addAllHallwayPaths(space_index, room.contents[room.occupied - 1], paths, &state_queue);
        }
    }
    unreachable;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip();
    const part = try std.fmt.parseUnsigned(u8, try args.next(allocator).?, 10);
    const path = try args.next(allocator).?;
    const input_file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer input_file.close();
    var paths = try computePaths(allocator);
    defer paths.deinit();
    const result = switch (part) {
        1 => try solveInput(2, try parseInput(2, allocator, input_file.reader()), &paths, allocator),
        2 => try solveInput(4, try parseInput(4, allocator, input_file.reader()), &paths, allocator),
        else => unreachable,
    };
    std.debug.print("Result: {}\n", .{result});
}
