const ray = @cImport({
    @cInclude("raylib.h");
});
const input = @cImport({
    @cInclude("fcntl.h");
});
const unistd = @cImport({
    @cInclude("unistd.h");
});
const stdio = @cImport({
    @cInclude("unistd.h");
});

const std = @import("std");

const screenWidth = 800;
const screenHeight = 450;
const pixelsize = 20;

const map_width = screenWidth / pixelsize;
const map_height = screenHeight / pixelsize;
var snake_size: u16 = 6;
var snake_head: [2]i16 = [_]i16{ 0, 0 };
var food_position: [2]i16 = [_]i16{ 1, 1 };

const linked_list = std.DoublyLinkedList([]i16);
var snake_tail = linked_list{};

const dir_right: [2]i2 = [_]i2{ 1, 0 };
var dir_left: [2]i2 = [_]i2{ -1, 0 };
var dir_up: [2]i2 = [_]i2{ 0, -1 };
var dir_down: [2]i2 = [_]i2{ 0, 1 };

var current_dir: [2]i2 = dir_right;

var x_pos: i16 = 0;
var y_pos: i16 = 0;

const allocator = std.heap.page_allocator;
fn draw_map() void {
    for (0..map_width) |x| {
        for (0..map_height) |y| {
            var mapxy = [_]i16{ @intCast(x), @intCast(y) };
            draw_pixel(&mapxy, false, ray.GREEN);
        }
    }
}
fn draw_pixel(location: []i16, fill: bool, color: ray.struct_Color) void {
    if (fill) {
        ray.DrawRectangle(@intCast(location[0] *% pixelsize), @intCast(location[1] *% pixelsize), pixelsize, pixelsize, color);
    } else {
        ray.DrawRectangleLines(@intCast(location[0] *% pixelsize), @intCast(location[1] *% pixelsize), pixelsize, pixelsize, color);
    }
}
fn push_tail(new_tail: [2]i16) !void {
    var tail_cpy = try allocator.alloc(i16, new_tail.len);
    tail_cpy[0] = new_tail[0];
    tail_cpy[1] = new_tail[1];

    var tail_node: *linked_list.Node = try allocator.create(linked_list.Node);
    tail_node.data = tail_cpy;
    snake_tail.append(tail_node);

    if (snake_tail.len < snake_size - 1)
        return;

    const removed_tail = snake_tail.popFirst();
    if (removed_tail) |node| {
        draw_pixel(node.data, true, ray.BLACK);
        draw_pixel(node.data, false, ray.GREEN);
    }
}
fn run_snake() !void {
    try push_tail(snake_head);

    snake_head[0] += current_dir[0];
    snake_head[1] += current_dir[1];

    draw_pixel(&snake_head, true, ray.GREEN);
}

fn handle_key_input() void {
    while (true) {
        const key_in: c_int = ray.GetKeyPressed();
        if ((key_in == 'k') or (key_in == 'K')) {
            if (std.mem.eql(i2, &current_dir, &dir_down))
                return;
            std.debug.print("up", .{});
            current_dir = dir_up;
        } else if ((key_in == 'j') or (key_in == 'J')) {
            if (std.mem.eql(i2, &current_dir, &dir_up))
                return;

            std.debug.print("down", .{});
            current_dir = dir_down;
        } else if ((key_in == 'h') or (key_in == 'H')) {
            if (std.mem.eql(i2, &current_dir, &dir_right))
                return;

            std.debug.print("left", .{});
            current_dir = dir_left;
        } else if ((key_in == 'l') or (key_in == 'L')) {
            if (std.mem.eql(i2, &current_dir, &dir_left))
                return;

            std.debug.print("right", .{});
            current_dir = dir_right;
        }
        ray.WaitTime(0.001);
    }
}

fn feed_food() void {
    if (std.mem.eql(i16, &snake_head, &food_position)) {
        food_position = [2]i16{ std.crypto.random.intRangeLessThan(i16, 0, map_width), std.crypto.random.intRangeLessThan(i16, 0, map_height) };
        snake_size += 1;
    }
    draw_pixel(&food_position, true, ray.RED);
}
pub fn main() !void {
    ray.InitWindow(screenWidth, screenHeight, "raylib [core] example - basic window");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);
    const input_listener: std.Thread = try std.Thread.spawn(.{}, handle_key_input, .{});
    draw_map();
    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        try run_snake();
        feed_food();
        defer ray.EndDrawing();
        ray.WaitTime(0.1);
    }
    input_listener.join();
}
