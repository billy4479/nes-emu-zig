const std = @import("std");
const text = @import("text.zig");
const SDL = @import("SDL.zig");
const TTF = SDL.TTF;

const font_file: []const u8 = @embedFile("assets/PressStart2P/PressStart2P.ttf");

fn drawFPS(lastFrameTime: f64, font: TTF.Font, renderer: SDL.Renderer) !void {
    const S = struct {
        var text_buf: [256]u8 = undefined;
    };
    const color = SDL.Color{
        .r = 0,
        .g = 0,
        .b = 0,
        .a = 0xff,
    };
    const scale_factor = 2;
    const offset = 25;

    const fps: f64 = 1.0 / lastFrameTime * 1e9;

    const str = try std.fmt.bufPrint(
        &S.text_buf,
        "FPS: {d:.0}\nFrameTime: {d:.2}ms \x00",
        .{ fps, lastFrameTime * 1e-6 },
    );
    const text_surface = try TTF.renderSolidWrapped(font, @ptrCast(str), color, 10000);

    var text_rect = text_surface.getRect();
    text_rect.w *= scale_factor;
    text_rect.h *= scale_factor;
    text_rect.x = offset;
    text_rect.y = offset;

    const text_texture = try SDL.Texture.fromSurface(renderer, text_surface);
    defer text_texture.deinit();
    text_surface.deinit();

    try renderer.copy(text_texture, null, &text_rect);
}

fn drawScreen(renderer: SDL.Renderer, nes_screen: SDL.Surface, counter: usize) !void {
    const blue = SDL.Color{ .r = 0x00, .g = 0x00, .b = 0xff, .a = 0xff };
    const green = SDL.Color{ .r = 0x00, .g = 0xff, .b = 0x00, .a = 0xff };
    const red = SDL.Color{ .r = 0xff, .g = 0x00, .b = 0x00, .a = 0xff };
    const size = nes_screen.size();

    {
        const pixels = try nes_screen.getPixels();
        defer pixels.deinit();
        var i: usize = 0;
        while (i < size.x) {
            var j: usize = 0;
            while (j < size.y) {
                const color = pixels.at(i, j);
                color.* = switch ((i + j * size.x + counter) % 3) {
                    0 => red,
                    1 => green,
                    2 => blue,
                    else => unreachable,
                };

                j += 1;
            }
            i += 1;
        }
    }
    const screen_texture = try SDL.Texture.fromSurface(renderer, nes_screen);

    const scale_factor = 4;
    var rect = nes_screen.getRect();
    rect.x = 300;
    rect.y = 0;
    rect.w *= scale_factor;
    rect.h *= scale_factor;

    try renderer.copy(screen_texture, null, &rect);
}

pub fn main() !void {
    try SDL.init(.{
        .video = true,
    });
    defer SDL.quit();

    try TTF.init();
    defer TTF.quit();

    const font_size = 8;
    const font = try TTF.Font.openFromConstMem(font_file, font_size);
    defer font.deinit();

    const window = try SDL.Window.init(
        "zig sdl",
        .{ .default = {} },
        .{ .default = {} },
        1800,
        1300,
        .{
            .vis = .shown,
            .resizable = true,
        },
    );
    defer window.deinit();

    const renderer = try SDL.Renderer.init(window, -1, .{ .accelerated = true });
    defer renderer.deinit();

    try renderer.setDrawColor(SDL.Color{ .r = 0xff, .g = 0xff, .b = 0xff, .a = 0xff });

    var timer = try std.time.Timer.start();
    var lastFrameTime: f64 = -1;

    const nes_screen = try SDL.Surface.createRGBA(256, 240);

    var counter: usize = 0;

    mainloop: while (true) {
        while (SDL.Events.pollEvent()) |event| {
            switch (event) {
                .quit => break :mainloop,
                else => {},
            }
        }

        try renderer.clear();

        try drawScreen(renderer, nes_screen, counter);
        try drawFPS(lastFrameTime, font, renderer);

        renderer.present();
        lastFrameTime = @floatFromInt(timer.lap());
        counter += 1;
    }
}
