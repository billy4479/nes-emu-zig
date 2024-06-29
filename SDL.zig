const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

const std = @import("std");

pub const SDLError = error{
    InitSystem,
    InitWindow,
    InitRenderer,
    InitTTF,
    OpenFont,
    TextRender,
    CreateTexture,
    SetRenderColor,
    RenderClear,
    RenderCopy,
    RWFromMem,
    CreateSurface,
    OutOfSurfaceBounds,
    LockSurface,
    FillRect,
};

fn printSDLError(err: SDLError) SDLError {
    const err_str = c.SDL_GetError();
    if (err_str == null) {
        std.log.err("SDL Error [{any}]: {s}", .{ err, err_str });
    } else {
        std.log.err("SDL Error [{any}]", .{err});
    }

    c.SDL_ClearError();

    return err;
}

fn errIfNotZero(code: c_int, err: SDLError) SDLError!void {
    if (code != 0) {
        return printSDLError(err);
    }
    return;
}

pub const InitFlags = struct {
    timer: bool = false,
    audio: bool = false,
    video: bool = false,
    joystick: bool = false,
    haptic: bool = false,
    gamecontroller: bool = false,
    events: bool = false,
    everything: bool = false,
};

pub fn init(flags: InitFlags) SDLError!void {
    var raw_flags: u32 = 0;

    if (flags.timer) raw_flags |= c.SDL_INIT_TIMER;
    if (flags.audio) raw_flags |= c.SDL_INIT_AUDIO;
    if (flags.video) raw_flags |= c.SDL_INIT_VIDEO;
    if (flags.joystick) raw_flags |= c.SDL_INIT_JOYSTICK;
    if (flags.haptic) raw_flags |= c.SDL_INIT_HAPTIC;
    if (flags.gamecontroller) raw_flags |= c.SDL_INIT_GAMECONTROLLER;
    if (flags.events) raw_flags |= c.SDL_INIT_EVENTS;
    if (flags.everything) raw_flags |= c.SDL_INIT_EVERYTHING;

    return errIfNotZero(c.SDL_Init(raw_flags), SDLError.InitSystem);
}

pub fn quit() void {
    c.SDL_Quit();
}

pub const WindowPosition = union(enum) {
    default: void,
    centered: void,
    absolute: c_int,
};

// https://github.com/ikskuh/SDL.zig/blob/master/src/wrapper/sdl.zig
pub const Window = struct {
    ptr: *c.SDL_Window,

    pub const Flags = struct {
        /// Window dimension
        dim: Dimension = .default,

        /// Window context
        context: Context = .default,

        /// Window visibility
        vis: Visibility = .default,

        /// no window decoration
        borderless: bool = false, // SDL_WINDOW_BORDERLESS,

        /// window can be resized
        resizable: bool = false, // SDL_WINDOW_RESIZABLE,

        ///  window has grabbed input focus
        input_grabbed: bool = false, // SDL_WINDOW_INPUT_GRABBED,

        /// window has input focus
        input_focus: bool = false, //SDL_WINDOW_INPUT_FOCUS,

        ///  window has mouse focus
        mouse_focus: bool = false, //SDL_WINDOW_MOUSE_FOCUS,

        /// window not created by SDL
        foreign: bool = false, //SDL_WINDOW_FOREIGN,

        /// window should be created in high-DPI mode if supported (>= SDL 2.0.1)
        allow_high_dpi: bool = false, //SDL_WINDOW_ALLOW_HIGHDPI,

        /// window has mouse captured (unrelated to INPUT_GRABBED, >= SDL 2.0.4)
        mouse_capture: bool = false, //SDL_WINDOW_MOUSE_CAPTURE,

        /// window should always be above others (X11 only, >= SDL 2.0.5)
        always_on_top: bool = false, //SDL_WINDOW_ALWAYS_ON_TOP,

        /// window should not be added to the taskbar (X11 only, >= SDL 2.0.5)
        skip_taskbar: bool = false, //SDL_WINDOW_SKIP_TASKBAR,

        /// window should be treated as a utility window (X11 only, >= SDL 2.0.5)
        utility: bool = false, //SDL_WINDOW_UTILITY,

        /// window should be treated as a tooltip (X11 only, >= SDL 2.0.5)
        tooltip: bool = false, //SDL_WINDOW_TOOLTIP,

        /// window should be treated as a popup menu (X11 only, >= SDL 2.0.5)
        popup_menu: bool = false, //SDL_WINDOW_POPUP_MENU,

        /// Context window should be usable with
        pub const Context = enum {
            opengl, //SDL_WINDOW_OPENGL
            vulkan, //SDL_WINDOW_VULKAN
            metal, // SDL_WINDOW_METAL
            default,
        };

        /// If window should be hidden or shown
        pub const Visibility = enum {
            shown, // SDL_WINDOW_SHOWN
            hidden, // SDL_WINDOW_HIDDEN
            default,
        };

        /// Dimension with which the window is created with
        pub const Dimension = enum {
            fullscreen, // SDL_WINDOW_FULLSCREEN
            /// Fullscreen window at current resolution
            fullscreen_desktop, // SDL_WINDOW_FULLSCREEN_DESKTOP
            maximized, // SDL_WINDOW_MAXIMIZED
            minimized, // SDL_WINDOW_MINIMIZED
            default,
        };

        fn toInteger(self: Flags) c_int {
            var val: c_int = 0;
            switch (self.dim) {
                .fullscreen => val |= c.SDL_WINDOW_FULLSCREEN,
                .fullscreen_desktop => val |= c.SDL_WINDOW_FULLSCREEN_DESKTOP,
                .maximized => val |= c.SDL_WINDOW_MAXIMIZED,
                .minimized => val |= c.SDL_WINDOW_MINIMIZED,
                .default => {},
            }
            switch (self.context) {
                .vulkan => val |= c.SDL_WINDOW_VULKAN,
                .opengl => val |= c.SDL_WINDOW_OPENGL,
                .metal => val |= c.SDL_WINDOW_METAL,
                .default => {},
            }
            switch (self.vis) {
                .shown => val |= c.SDL_WINDOW_SHOWN,
                .hidden => val |= c.SDL_WINDOW_HIDDEN,
                .default => {},
            }
            if (self.borderless) val |= c.SDL_WINDOW_BORDERLESS;
            if (self.resizable) val |= c.SDL_WINDOW_RESIZABLE;
            if (self.input_grabbed) val |= c.SDL_WINDOW_INPUT_GRABBED;
            if (self.input_focus) val |= c.SDL_WINDOW_INPUT_FOCUS;
            if (self.mouse_focus) val |= c.SDL_WINDOW_MOUSE_FOCUS;
            if (self.foreign) val |= c.SDL_WINDOW_FOREIGN;
            if (self.allow_high_dpi) val |= c.SDL_WINDOW_ALLOW_HIGHDPI;
            if (self.mouse_capture) val |= c.SDL_WINDOW_MOUSE_CAPTURE;
            if (self.always_on_top) val |= c.SDL_WINDOW_ALWAYS_ON_TOP;
            if (self.skip_taskbar) val |= c.SDL_WINDOW_SKIP_TASKBAR;
            if (self.utility) val |= c.SDL_WINDOW_UTILITY;
            if (self.tooltip) val |= c.SDL_WINDOW_TOOLTIP;
            if (self.popup_menu) val |= c.SDL_WINDOW_POPUP_MENU;
            return val;
        }
    };

    pub fn init(
        title: [:0]const u8,
        x: WindowPosition,
        y: WindowPosition,
        width: usize,
        height: usize,
        flags: Flags,
    ) SDLError!Window {
        return Window{
            .ptr = c.SDL_CreateWindow(
                title.ptr,
                switch (x) {
                    .default => c.SDL_WINDOWPOS_UNDEFINED_MASK,
                    .centered => c.SDL_WINDOWPOS_CENTERED_MASK,
                    .absolute => |v| v,
                },
                switch (y) {
                    .default => c.SDL_WINDOWPOS_UNDEFINED_MASK,
                    .centered => c.SDL_WINDOWPOS_CENTERED_MASK,
                    .absolute => |v| v,
                },
                @intCast(width),
                @intCast(height),
                @intCast(flags.toInteger()),
            ) orelse return printSDLError(SDLError.InitWindow),
        };
    }

    pub fn deinit(self: Window) void {
        c.SDL_DestroyWindow(self.ptr);
    }
};

pub const Renderer = struct {
    ptr: *c.SDL_Renderer,

    pub const Flags = packed struct {
        software: bool = false,
        accelerated: bool = false,
        presentvsync: bool = false,
        targettexture: bool = false,

        fn toInteger(self: Flags) u32 {
            var int_flags: u32 = 0;
            if (self.software) int_flags |= c.SDL_RENDERER_SOFTWARE;
            if (self.accelerated) int_flags |= c.SDL_RENDERER_ACCELERATED;
            if (self.presentvsync) int_flags |= c.SDL_RENDERER_PRESENTVSYNC;
            if (self.targettexture) int_flags |= c.SDL_RENDERER_TARGETTEXTURE;
            return int_flags;
        }
    };

    pub fn init(window: Window, index: i32, flags: Flags) SDLError!Renderer {
        return Renderer{
            .ptr = try (c.SDL_CreateRenderer(
                window.ptr,
                index,
                flags.toInteger(),
            ) orelse printSDLError(SDLError.InitRenderer)),
        };
    }

    pub fn deinit(self: Renderer) void {
        c.SDL_DestroyRenderer(self.ptr);
    }

    pub fn setDrawColor(self: Renderer, color: Color) SDLError!void {
        return errIfNotZero(
            c.SDL_SetRenderDrawColor(self.ptr, color.r, color.g, color.b, color.a),
            SDLError.SetRenderColor,
        );
    }

    pub fn clear(self: Renderer) SDLError!void {
        return errIfNotZero(c.SDL_RenderClear(self.ptr), SDLError.RenderClear);
    }

    pub fn copy(self: Renderer, texture: Texture, src_rect: ?*const Rect, dest_rect: ?*const Rect) SDLError!void {
        return errIfNotZero(c.SDL_RenderCopy(
            self.ptr,
            texture.ptr,
            src_rect,
            dest_rect,
        ), SDLError.RenderCopy);
    }

    pub fn present(self: Renderer) void {
        c.SDL_RenderPresent(self.ptr);
    }
};

pub const Rect = c.SDL_Rect;
pub const Color = c.SDL_Color;

pub const Surface = struct {
    ptr: *c.SDL_Surface,

    pub fn deinit(self: Surface) void {
        c.SDL_FreeSurface(self.ptr);
    }

    pub fn getRect(self: Surface) Rect {
        return Rect{
            .x = 0,
            .y = 0,
            .w = self.ptr.*.w,
            .h = self.ptr.*.h,
        };
    }

    pub fn createRGBA(width: i32, height: i32) SDLError!Surface {
        const ptr = c.SDL_CreateRGBSurfaceWithFormat(0, width, height, 32, c.SDL_PIXELFORMAT_RGBA32);
        if (ptr == null) {
            return printSDLError(SDLError.CreateSurface);
        }
        return Surface{ .ptr = ptr };
    }

    pub fn fillRect(self: @This(), rect: *const Rect, color: *const Color) SDLError!void {
        return errIfNotZero(c.SDL_FillRect(self.ptr, rect, @bitCast(color.*)), SDLError.FillRect);
    }

    pub fn putPixel(self: @This(), x: i32, y: i32, color: *const Color) SDLError!void {
        const pixels = try self.getPixels();

        const col = pixels.at(x, y);
        col.* = color.*;
        pixels.deinit();
    }

    pub const Pixels = struct {
        surface: Surface,
        pixels: []Color,

        pub fn deinit(self: @This()) void {
            if (c.SDL_MUSTLOCK(self.surface.ptr)) {
                c.SDL_UnlockSurface(self.surface.ptr);
            }
        }

        pub fn at(self: @This(), x: usize, y: usize) *Color {
            const index: usize = @intCast(y * (@divTrunc(@as(usize, @intCast(self.surface.ptr.*.pitch)), @sizeOf(u32))) + x);

            return &self.pixels[index];
        }
    };

    pub fn getPixels(self: Surface) SDLError!Pixels {
        if (c.SDL_MUSTLOCK(self.ptr)) {
            try errIfNotZero(c.SDL_LockSurface(self.ptr), SDLError.LockSurface);
        }

        const len: usize = @intCast(self.ptr.*.h * self.ptr.*.w);
        const col: []Color = @as(
            [*]Color,
            @ptrCast(self.ptr.*.pixels orelse unreachable),
        )[0..len];

        return Pixels{
            .surface = self,
            .pixels = col,
        };
    }

    pub fn clear(self: @This(), color: *const Color) SDLError!void {
        return errIfNotZero(c.SDL_FillRect(self.ptr, null, @bitCast(color.*)), SDLError.FillRect);
    }

    pub fn size(self: Surface) struct { x: usize, y: usize } {
        return .{
            .x = @intCast(self.ptr.*.w),
            .y = @intCast(self.ptr.*.h),
        };
    }
};

pub const Texture = struct {
    ptr: *c.SDL_Texture,

    pub fn fromSurface(renderer: Renderer, surface: Surface) SDLError!Texture {
        return Texture{
            .ptr = try (c.SDL_CreateTextureFromSurface(renderer.ptr, surface.ptr) orelse SDLError.CreateTexture),
        };
    }

    pub fn deinit(self: Texture) void {
        c.SDL_DestroyTexture(self.ptr);
    }
};

pub const Point = c.SDL_Point;
pub const Size = extern struct {
    width: c_int,
    height: c_int,
};

pub const Events = struct {
    pub const WindowEvent = struct {
        const Type = enum(u8) {
            none = c.SDL_WINDOWEVENT_NONE,
            shown = c.SDL_WINDOWEVENT_SHOWN,
            hidden = c.SDL_WINDOWEVENT_HIDDEN,
            exposed = c.SDL_WINDOWEVENT_EXPOSED,
            moved = c.SDL_WINDOWEVENT_MOVED,
            resized = c.SDL_WINDOWEVENT_RESIZED,
            size_changed = c.SDL_WINDOWEVENT_SIZE_CHANGED,
            minimized = c.SDL_WINDOWEVENT_MINIMIZED,
            maximized = c.SDL_WINDOWEVENT_MAXIMIZED,
            restored = c.SDL_WINDOWEVENT_RESTORED,
            enter = c.SDL_WINDOWEVENT_ENTER,
            leave = c.SDL_WINDOWEVENT_LEAVE,
            focus_gained = c.SDL_WINDOWEVENT_FOCUS_GAINED,
            focus_lost = c.SDL_WINDOWEVENT_FOCUS_LOST,
            close = c.SDL_WINDOWEVENT_CLOSE,
            take_focus = c.SDL_WINDOWEVENT_TAKE_FOCUS,
            hit_test = c.SDL_WINDOWEVENT_HIT_TEST,

            _,
        };

        const Data = union(Type) {
            none: void,
            shown: void,
            hidden: void,
            exposed: void,
            moved: Point,
            resized: Size,
            size_changed: Size,
            minimized: void,
            maximized: void,
            restored: void,
            enter: void,
            leave: void,
            focus_gained: void,
            focus_lost: void,
            close: void,
            take_focus: void,
            hit_test: void,
        };

        timestamp: u32,
        window_id: u32,
        type: Data,

        fn fromNative(ev: c.SDL_WindowEvent) WindowEvent {
            return WindowEvent{
                .timestamp = ev.timestamp,
                .window_id = ev.windowID,
                .type = switch (@as(Type, @enumFromInt(ev.event))) {
                    .shown => Data{ .shown = {} },
                    .hidden => Data{ .hidden = {} },
                    .exposed => Data{ .exposed = {} },
                    .moved => Data{ .moved = Point{ .x = ev.data1, .y = ev.data2 } },
                    .resized => Data{ .resized = Size{ .width = ev.data1, .height = ev.data2 } },
                    .size_changed => Data{ .size_changed = Size{ .width = ev.data1, .height = ev.data2 } },
                    .minimized => Data{ .minimized = {} },
                    .maximized => Data{ .maximized = {} },
                    .restored => Data{ .restored = {} },
                    .enter => Data{ .enter = {} },
                    .leave => Data{ .leave = {} },
                    .focus_gained => Data{ .focus_gained = {} },
                    .focus_lost => Data{ .focus_lost = {} },
                    .close => Data{ .close = {} },
                    .take_focus => Data{ .take_focus = {} },
                    .hit_test => Data{ .hit_test = {} },
                    else => Data{ .none = {} },
                },
            };
        }
    };

    pub const KeyModifierBit = enum(u16) {
        left_shift = c.KMOD_LSHIFT,
        right_shift = c.KMOD_RSHIFT,
        left_control = c.KMOD_LCTRL,
        right_control = c.KMOD_RCTRL,
        ///left alternate
        left_alt = c.KMOD_LALT,
        ///right alternate
        right_alt = c.KMOD_RALT,
        left_gui = c.KMOD_LGUI,
        right_gui = c.KMOD_RGUI,
        ///numeric lock
        num_lock = c.KMOD_NUM,
        ///capital letters lock
        caps_lock = c.KMOD_CAPS,
        mode = c.KMOD_MODE,
        ///scroll lock (= previous value c.KMOD_RESERVED)
        scroll_lock = c.KMOD_SCROLL,
    };
    pub const KeyModifierSet = struct {
        storage: u16,

        pub fn fromNative(native: u16) KeyModifierSet {
            return .{ .storage = native };
        }
        pub fn toNative(self: KeyModifierSet) u16 {
            return self.storage;
        }

        pub fn get(self: KeyModifierSet, modifier: KeyModifierBit) bool {
            return (self.storage & @intFromEnum(modifier)) != 0;
        }
        pub fn set(self: *KeyModifierSet, modifier: KeyModifierBit) void {
            self.storage |= @intFromEnum(modifier);
        }
        pub fn clear(self: *KeyModifierSet, modifier: KeyModifierBit) void {
            self.storage &= ~@intFromEnum(modifier);
        }
    };
    pub const Scancode = enum(c.SDL_Scancode) {
        unknown = c.SDL_SCANCODE_UNKNOWN,
        a = c.SDL_SCANCODE_A,
        b = c.SDL_SCANCODE_B,
        c = c.SDL_SCANCODE_C,
        d = c.SDL_SCANCODE_D,
        e = c.SDL_SCANCODE_E,
        f = c.SDL_SCANCODE_F,
        g = c.SDL_SCANCODE_G,
        h = c.SDL_SCANCODE_H,
        i = c.SDL_SCANCODE_I,
        j = c.SDL_SCANCODE_J,
        k = c.SDL_SCANCODE_K,
        l = c.SDL_SCANCODE_L,
        m = c.SDL_SCANCODE_M,
        n = c.SDL_SCANCODE_N,
        o = c.SDL_SCANCODE_O,
        p = c.SDL_SCANCODE_P,
        q = c.SDL_SCANCODE_Q,
        r = c.SDL_SCANCODE_R,
        s = c.SDL_SCANCODE_S,
        t = c.SDL_SCANCODE_T,
        u = c.SDL_SCANCODE_U,
        v = c.SDL_SCANCODE_V,
        w = c.SDL_SCANCODE_W,
        x = c.SDL_SCANCODE_X,
        y = c.SDL_SCANCODE_Y,
        z = c.SDL_SCANCODE_Z,
        @"1" = c.SDL_SCANCODE_1,
        @"2" = c.SDL_SCANCODE_2,
        @"3" = c.SDL_SCANCODE_3,
        @"4" = c.SDL_SCANCODE_4,
        @"5" = c.SDL_SCANCODE_5,
        @"6" = c.SDL_SCANCODE_6,
        @"7" = c.SDL_SCANCODE_7,
        @"8" = c.SDL_SCANCODE_8,
        @"9" = c.SDL_SCANCODE_9,
        @"0" = c.SDL_SCANCODE_0,
        @"return" = c.SDL_SCANCODE_RETURN,
        escape = c.SDL_SCANCODE_ESCAPE,
        backspace = c.SDL_SCANCODE_BACKSPACE,
        tab = c.SDL_SCANCODE_TAB,
        space = c.SDL_SCANCODE_SPACE,
        minus = c.SDL_SCANCODE_MINUS,
        equals = c.SDL_SCANCODE_EQUALS,
        left_bracket = c.SDL_SCANCODE_LEFTBRACKET,
        right_bracket = c.SDL_SCANCODE_RIGHTBRACKET,
        backslash = c.SDL_SCANCODE_BACKSLASH,
        non_us_hash = c.SDL_SCANCODE_NONUSHASH,
        semicolon = c.SDL_SCANCODE_SEMICOLON,
        apostrophe = c.SDL_SCANCODE_APOSTROPHE,
        grave = c.SDL_SCANCODE_GRAVE,
        comma = c.SDL_SCANCODE_COMMA,
        period = c.SDL_SCANCODE_PERIOD,
        slash = c.SDL_SCANCODE_SLASH,
        ///capital letters lock
        caps_lock = c.SDL_SCANCODE_CAPSLOCK,
        f1 = c.SDL_SCANCODE_F1,
        f2 = c.SDL_SCANCODE_F2,
        f3 = c.SDL_SCANCODE_F3,
        f4 = c.SDL_SCANCODE_F4,
        f5 = c.SDL_SCANCODE_F5,
        f6 = c.SDL_SCANCODE_F6,
        f7 = c.SDL_SCANCODE_F7,
        f8 = c.SDL_SCANCODE_F8,
        f9 = c.SDL_SCANCODE_F9,
        f10 = c.SDL_SCANCODE_F10,
        f11 = c.SDL_SCANCODE_F11,
        f12 = c.SDL_SCANCODE_F12,
        print_screen = c.SDL_SCANCODE_PRINTSCREEN,
        scroll_lock = c.SDL_SCANCODE_SCROLLLOCK,
        pause = c.SDL_SCANCODE_PAUSE,
        insert = c.SDL_SCANCODE_INSERT,
        home = c.SDL_SCANCODE_HOME,
        page_up = c.SDL_SCANCODE_PAGEUP,
        delete = c.SDL_SCANCODE_DELETE,
        end = c.SDL_SCANCODE_END,
        page_down = c.SDL_SCANCODE_PAGEDOWN,
        right = c.SDL_SCANCODE_RIGHT,
        left = c.SDL_SCANCODE_LEFT,
        down = c.SDL_SCANCODE_DOWN,
        up = c.SDL_SCANCODE_UP,
        ///numeric lock, "Clear" key on Apple keyboards
        num_lock_clear = c.SDL_SCANCODE_NUMLOCKCLEAR,
        keypad_divide = c.SDL_SCANCODE_KP_DIVIDE,
        keypad_multiply = c.SDL_SCANCODE_KP_MULTIPLY,
        keypad_minus = c.SDL_SCANCODE_KP_MINUS,
        keypad_plus = c.SDL_SCANCODE_KP_PLUS,
        keypad_enter = c.SDL_SCANCODE_KP_ENTER,
        keypad_1 = c.SDL_SCANCODE_KP_1,
        keypad_2 = c.SDL_SCANCODE_KP_2,
        keypad_3 = c.SDL_SCANCODE_KP_3,
        keypad_4 = c.SDL_SCANCODE_KP_4,
        keypad_5 = c.SDL_SCANCODE_KP_5,
        keypad_6 = c.SDL_SCANCODE_KP_6,
        keypad_7 = c.SDL_SCANCODE_KP_7,
        keypad_8 = c.SDL_SCANCODE_KP_8,
        keypad_9 = c.SDL_SCANCODE_KP_9,
        keypad_0 = c.SDL_SCANCODE_KP_0,
        keypad_period = c.SDL_SCANCODE_KP_PERIOD,
        non_us_backslash = c.SDL_SCANCODE_NONUSBACKSLASH,
        application = c.SDL_SCANCODE_APPLICATION,
        power = c.SDL_SCANCODE_POWER,
        keypad_equals = c.SDL_SCANCODE_KP_EQUALS,
        f13 = c.SDL_SCANCODE_F13,
        f14 = c.SDL_SCANCODE_F14,
        f15 = c.SDL_SCANCODE_F15,
        f16 = c.SDL_SCANCODE_F16,
        f17 = c.SDL_SCANCODE_F17,
        f18 = c.SDL_SCANCODE_F18,
        f19 = c.SDL_SCANCODE_F19,
        f20 = c.SDL_SCANCODE_F20,
        f21 = c.SDL_SCANCODE_F21,
        f22 = c.SDL_SCANCODE_F22,
        f23 = c.SDL_SCANCODE_F23,
        f24 = c.SDL_SCANCODE_F24,
        execute = c.SDL_SCANCODE_EXECUTE,
        help = c.SDL_SCANCODE_HELP,
        menu = c.SDL_SCANCODE_MENU,
        select = c.SDL_SCANCODE_SELECT,
        stop = c.SDL_SCANCODE_STOP,
        again = c.SDL_SCANCODE_AGAIN,
        undo = c.SDL_SCANCODE_UNDO,
        cut = c.SDL_SCANCODE_CUT,
        copy = c.SDL_SCANCODE_COPY,
        paste = c.SDL_SCANCODE_PASTE,
        find = c.SDL_SCANCODE_FIND,
        mute = c.SDL_SCANCODE_MUTE,
        volume_up = c.SDL_SCANCODE_VOLUMEUP,
        volume_down = c.SDL_SCANCODE_VOLUMEDOWN,
        keypad_comma = c.SDL_SCANCODE_KP_COMMA,
        keypad_equals_as_400 = c.SDL_SCANCODE_KP_EQUALSAS400,
        international_1 = c.SDL_SCANCODE_INTERNATIONAL1,
        international_2 = c.SDL_SCANCODE_INTERNATIONAL2,
        international_3 = c.SDL_SCANCODE_INTERNATIONAL3,
        international_4 = c.SDL_SCANCODE_INTERNATIONAL4,
        international_5 = c.SDL_SCANCODE_INTERNATIONAL5,
        international_6 = c.SDL_SCANCODE_INTERNATIONAL6,
        international_7 = c.SDL_SCANCODE_INTERNATIONAL7,
        international_8 = c.SDL_SCANCODE_INTERNATIONAL8,
        international_9 = c.SDL_SCANCODE_INTERNATIONAL9,
        language_1 = c.SDL_SCANCODE_LANG1,
        language_2 = c.SDL_SCANCODE_LANG2,
        language_3 = c.SDL_SCANCODE_LANG3,
        language_4 = c.SDL_SCANCODE_LANG4,
        language_5 = c.SDL_SCANCODE_LANG5,
        language_6 = c.SDL_SCANCODE_LANG6,
        language_7 = c.SDL_SCANCODE_LANG7,
        language_8 = c.SDL_SCANCODE_LANG8,
        language_9 = c.SDL_SCANCODE_LANG9,
        alternate_erase = c.SDL_SCANCODE_ALTERASE,
        ///aka "Attention"
        system_request = c.SDL_SCANCODE_SYSREQ,
        cancel = c.SDL_SCANCODE_CANCEL,
        clear = c.SDL_SCANCODE_CLEAR,
        prior = c.SDL_SCANCODE_PRIOR,
        return_2 = c.SDL_SCANCODE_RETURN2,
        separator = c.SDL_SCANCODE_SEPARATOR,
        out = c.SDL_SCANCODE_OUT,
        ///Don't know what this stands for, operator? operation? operating system? Couldn't find it anywhere.
        oper = c.SDL_SCANCODE_OPER,
        ///technically named "Clear/Again"
        clear_again = c.SDL_SCANCODE_CLEARAGAIN,
        ///aka "CrSel/Props" (properties)
        cursor_selection = c.SDL_SCANCODE_CRSEL,
        extend_selection = c.SDL_SCANCODE_EXSEL,
        keypad_00 = c.SDL_SCANCODE_KP_00,
        keypad_000 = c.SDL_SCANCODE_KP_000,
        thousands_separator = c.SDL_SCANCODE_THOUSANDSSEPARATOR,
        decimal_separator = c.SDL_SCANCODE_DECIMALSEPARATOR,
        currency_unit = c.SDL_SCANCODE_CURRENCYUNIT,
        currency_subunit = c.SDL_SCANCODE_CURRENCYSUBUNIT,
        keypad_left_parenthesis = c.SDL_SCANCODE_KP_LEFTPAREN,
        keypad_right_parenthesis = c.SDL_SCANCODE_KP_RIGHTPAREN,
        keypad_left_brace = c.SDL_SCANCODE_KP_LEFTBRACE,
        keypad_right_brace = c.SDL_SCANCODE_KP_RIGHTBRACE,
        keypad_tab = c.SDL_SCANCODE_KP_TAB,
        keypad_backspace = c.SDL_SCANCODE_KP_BACKSPACE,
        keypad_a = c.SDL_SCANCODE_KP_A,
        keypad_b = c.SDL_SCANCODE_KP_B,
        keypad_c = c.SDL_SCANCODE_KP_C,
        keypad_d = c.SDL_SCANCODE_KP_D,
        keypad_e = c.SDL_SCANCODE_KP_E,
        keypad_f = c.SDL_SCANCODE_KP_F,
        ///keypad exclusive or
        keypad_xor = c.SDL_SCANCODE_KP_XOR,
        keypad_power = c.SDL_SCANCODE_KP_POWER,
        keypad_percent = c.SDL_SCANCODE_KP_PERCENT,
        keypad_less = c.SDL_SCANCODE_KP_LESS,
        keypad_greater = c.SDL_SCANCODE_KP_GREATER,
        keypad_ampersand = c.SDL_SCANCODE_KP_AMPERSAND,
        keypad_double_ampersand = c.SDL_SCANCODE_KP_DBLAMPERSAND,
        keypad_vertical_bar = c.SDL_SCANCODE_KP_VERTICALBAR,
        keypad_double_vertical_bar = c.SDL_SCANCODE_KP_DBLVERTICALBAR,
        keypad_colon = c.SDL_SCANCODE_KP_COLON,
        keypad_hash = c.SDL_SCANCODE_KP_HASH,
        keypad_space = c.SDL_SCANCODE_KP_SPACE,
        keypad_at_sign = c.SDL_SCANCODE_KP_AT,
        keypad_exclamation_mark = c.SDL_SCANCODE_KP_EXCLAM,
        keypad_memory_store = c.SDL_SCANCODE_KP_MEMSTORE,
        keypad_memory_recall = c.SDL_SCANCODE_KP_MEMRECALL,
        keypad_memory_clear = c.SDL_SCANCODE_KP_MEMCLEAR,
        keypad_memory_add = c.SDL_SCANCODE_KP_MEMADD,
        keypad_memory_subtract = c.SDL_SCANCODE_KP_MEMSUBTRACT,
        keypad_memory_multiply = c.SDL_SCANCODE_KP_MEMMULTIPLY,
        keypad_memory_divide = c.SDL_SCANCODE_KP_MEMDIVIDE,
        keypad_plus_minus = c.SDL_SCANCODE_KP_PLUSMINUS,
        keypad_clear = c.SDL_SCANCODE_KP_CLEAR,
        keypad_clear_entry = c.SDL_SCANCODE_KP_CLEARENTRY,
        keypad_binary = c.SDL_SCANCODE_KP_BINARY,
        keypad_octal = c.SDL_SCANCODE_KP_OCTAL,
        keypad_decimal = c.SDL_SCANCODE_KP_DECIMAL,
        keypad_hexadecimal = c.SDL_SCANCODE_KP_HEXADECIMAL,
        left_control = c.SDL_SCANCODE_LCTRL,
        left_shift = c.SDL_SCANCODE_LSHIFT,
        ///left alternate
        left_alt = c.SDL_SCANCODE_LALT,
        left_gui = c.SDL_SCANCODE_LGUI,
        right_control = c.SDL_SCANCODE_RCTRL,
        right_shift = c.SDL_SCANCODE_RSHIFT,
        ///right alternate
        right_alt = c.SDL_SCANCODE_RALT,
        right_gui = c.SDL_SCANCODE_RGUI,
        mode = c.SDL_SCANCODE_MODE,
        audio_next = c.SDL_SCANCODE_AUDIONEXT,
        audio_previous = c.SDL_SCANCODE_AUDIOPREV,
        audio_stop = c.SDL_SCANCODE_AUDIOSTOP,
        audio_play = c.SDL_SCANCODE_AUDIOPLAY,
        audio_mute = c.SDL_SCANCODE_AUDIOMUTE,
        media_select = c.SDL_SCANCODE_MEDIASELECT,
        www = c.SDL_SCANCODE_WWW,
        mail = c.SDL_SCANCODE_MAIL,
        calculator = c.SDL_SCANCODE_CALCULATOR,
        computer = c.SDL_SCANCODE_COMPUTER,
        application_control_search = c.SDL_SCANCODE_AC_SEARCH,
        application_control_home = c.SDL_SCANCODE_AC_HOME,
        application_control_back = c.SDL_SCANCODE_AC_BACK,
        application_control_forward = c.SDL_SCANCODE_AC_FORWARD,
        application_control_stop = c.SDL_SCANCODE_AC_STOP,
        application_control_refresh = c.SDL_SCANCODE_AC_REFRESH,
        application_control_bookmarks = c.SDL_SCANCODE_AC_BOOKMARKS,
        brightness_down = c.SDL_SCANCODE_BRIGHTNESSDOWN,
        brightness_up = c.SDL_SCANCODE_BRIGHTNESSUP,
        display_switch = c.SDL_SCANCODE_DISPLAYSWITCH,
        keyboard_illumination_toggle = c.SDL_SCANCODE_KBDILLUMTOGGLE,
        keyboard_illumination_down = c.SDL_SCANCODE_KBDILLUMDOWN,
        keyboard_illumination_up = c.SDL_SCANCODE_KBDILLUMUP,
        eject = c.SDL_SCANCODE_EJECT,
        sleep = c.SDL_SCANCODE_SLEEP,
        application_1 = c.SDL_SCANCODE_APP1,
        application_2 = c.SDL_SCANCODE_APP2,
        audio_rewind = c.SDL_SCANCODE_AUDIOREWIND,
        audio_fast_forward = c.SDL_SCANCODE_AUDIOFASTFORWARD,
        _,
    };

    pub const Keycode = enum(c.SDL_Keycode) {
        unknown = c.SDLK_UNKNOWN,
        @"return" = c.SDLK_RETURN,
        escape = c.SDLK_ESCAPE,
        backspace = c.SDLK_BACKSPACE,
        tab = c.SDLK_TAB,
        space = c.SDLK_SPACE,
        exclamation_mark = c.SDLK_EXCLAIM,
        quote = c.SDLK_QUOTEDBL,
        hash = c.SDLK_HASH,
        percent = c.SDLK_PERCENT,
        dollar = c.SDLK_DOLLAR,
        ampersand = c.SDLK_AMPERSAND,
        apostrophe = c.SDLK_QUOTE,
        left_parenthesis = c.SDLK_LEFTPAREN,
        right_parenthesis = c.SDLK_RIGHTPAREN,
        asterisk = c.SDLK_ASTERISK,
        plus = c.SDLK_PLUS,
        comma = c.SDLK_COMMA,
        minus = c.SDLK_MINUS,
        period = c.SDLK_PERIOD,
        slash = c.SDLK_SLASH,
        @"0" = c.SDLK_0,
        @"1" = c.SDLK_1,
        @"2" = c.SDLK_2,
        @"3" = c.SDLK_3,
        @"4" = c.SDLK_4,
        @"5" = c.SDLK_5,
        @"6" = c.SDLK_6,
        @"7" = c.SDLK_7,
        @"8" = c.SDLK_8,
        @"9" = c.SDLK_9,
        colon = c.SDLK_COLON,
        semicolon = c.SDLK_SEMICOLON,
        less = c.SDLK_LESS,
        equals = c.SDLK_EQUALS,
        greater = c.SDLK_GREATER,
        question_mark = c.SDLK_QUESTION,
        at_sign = c.SDLK_AT,
        left_bracket = c.SDLK_LEFTBRACKET,
        backslash = c.SDLK_BACKSLASH,
        right_bracket = c.SDLK_RIGHTBRACKET,
        caret = c.SDLK_CARET,
        underscore = c.SDLK_UNDERSCORE,
        grave = c.SDLK_BACKQUOTE,
        a = c.SDLK_a,
        b = c.SDLK_b,
        c = c.SDLK_c,
        d = c.SDLK_d,
        e = c.SDLK_e,
        f = c.SDLK_f,
        g = c.SDLK_g,
        h = c.SDLK_h,
        i = c.SDLK_i,
        j = c.SDLK_j,
        k = c.SDLK_k,
        l = c.SDLK_l,
        m = c.SDLK_m,
        n = c.SDLK_n,
        o = c.SDLK_o,
        p = c.SDLK_p,
        q = c.SDLK_q,
        r = c.SDLK_r,
        s = c.SDLK_s,
        t = c.SDLK_t,
        u = c.SDLK_u,
        v = c.SDLK_v,
        w = c.SDLK_w,
        x = c.SDLK_x,
        y = c.SDLK_y,
        z = c.SDLK_z,
        ///capital letters lock
        caps_lock = c.SDLK_CAPSLOCK,
        f1 = c.SDLK_F1,
        f2 = c.SDLK_F2,
        f3 = c.SDLK_F3,
        f4 = c.SDLK_F4,
        f5 = c.SDLK_F5,
        f6 = c.SDLK_F6,
        f7 = c.SDLK_F7,
        f8 = c.SDLK_F8,
        f9 = c.SDLK_F9,
        f10 = c.SDLK_F10,
        f11 = c.SDLK_F11,
        f12 = c.SDLK_F12,
        print_screen = c.SDLK_PRINTSCREEN,
        scroll_lock = c.SDLK_SCROLLLOCK,
        pause = c.SDLK_PAUSE,
        insert = c.SDLK_INSERT,
        home = c.SDLK_HOME,
        page_up = c.SDLK_PAGEUP,
        delete = c.SDLK_DELETE,
        end = c.SDLK_END,
        page_down = c.SDLK_PAGEDOWN,
        right = c.SDLK_RIGHT,
        left = c.SDLK_LEFT,
        down = c.SDLK_DOWN,
        up = c.SDLK_UP,
        ///numeric lock, "Clear" key on Apple keyboards
        num_lock_clear = c.SDLK_NUMLOCKCLEAR,
        keypad_divide = c.SDLK_KP_DIVIDE,
        keypad_multiply = c.SDLK_KP_MULTIPLY,
        keypad_minus = c.SDLK_KP_MINUS,
        keypad_plus = c.SDLK_KP_PLUS,
        keypad_enter = c.SDLK_KP_ENTER,
        keypad_1 = c.SDLK_KP_1,
        keypad_2 = c.SDLK_KP_2,
        keypad_3 = c.SDLK_KP_3,
        keypad_4 = c.SDLK_KP_4,
        keypad_5 = c.SDLK_KP_5,
        keypad_6 = c.SDLK_KP_6,
        keypad_7 = c.SDLK_KP_7,
        keypad_8 = c.SDLK_KP_8,
        keypad_9 = c.SDLK_KP_9,
        keypad_0 = c.SDLK_KP_0,
        keypad_period = c.SDLK_KP_PERIOD,
        application = c.SDLK_APPLICATION,
        power = c.SDLK_POWER,
        keypad_equals = c.SDLK_KP_EQUALS,
        f13 = c.SDLK_F13,
        f14 = c.SDLK_F14,
        f15 = c.SDLK_F15,
        f16 = c.SDLK_F16,
        f17 = c.SDLK_F17,
        f18 = c.SDLK_F18,
        f19 = c.SDLK_F19,
        f20 = c.SDLK_F20,
        f21 = c.SDLK_F21,
        f22 = c.SDLK_F22,
        f23 = c.SDLK_F23,
        f24 = c.SDLK_F24,
        execute = c.SDLK_EXECUTE,
        help = c.SDLK_HELP,
        menu = c.SDLK_MENU,
        select = c.SDLK_SELECT,
        stop = c.SDLK_STOP,
        again = c.SDLK_AGAIN,
        undo = c.SDLK_UNDO,
        cut = c.SDLK_CUT,
        copy = c.SDLK_COPY,
        paste = c.SDLK_PASTE,
        find = c.SDLK_FIND,
        mute = c.SDLK_MUTE,
        volume_up = c.SDLK_VOLUMEUP,
        volume_down = c.SDLK_VOLUMEDOWN,
        keypad_comma = c.SDLK_KP_COMMA,
        keypad_equals_as_400 = c.SDLK_KP_EQUALSAS400,
        alternate_erase = c.SDLK_ALTERASE,
        ///aka "Attention"
        system_request = c.SDLK_SYSREQ,
        cancel = c.SDLK_CANCEL,
        clear = c.SDLK_CLEAR,
        prior = c.SDLK_PRIOR,
        return_2 = c.SDLK_RETURN2,
        separator = c.SDLK_SEPARATOR,
        out = c.SDLK_OUT,
        ///Don't know what this stands for, operator? operation? operating system? Couldn't find it anywhere.
        oper = c.SDLK_OPER,
        ///technically named "Clear/Again"
        clear_again = c.SDLK_CLEARAGAIN,
        ///aka "CrSel/Props" (properties)
        cursor_selection = c.SDLK_CRSEL,
        extend_selection = c.SDLK_EXSEL,
        keypad_00 = c.SDLK_KP_00,
        keypad_000 = c.SDLK_KP_000,
        thousands_separator = c.SDLK_THOUSANDSSEPARATOR,
        decimal_separator = c.SDLK_DECIMALSEPARATOR,
        currency_unit = c.SDLK_CURRENCYUNIT,
        currency_subunit = c.SDLK_CURRENCYSUBUNIT,
        keypad_left_parenthesis = c.SDLK_KP_LEFTPAREN,
        keypad_right_parenthesis = c.SDLK_KP_RIGHTPAREN,
        keypad_left_brace = c.SDLK_KP_LEFTBRACE,
        keypad_right_brace = c.SDLK_KP_RIGHTBRACE,
        keypad_tab = c.SDLK_KP_TAB,
        keypad_backspace = c.SDLK_KP_BACKSPACE,
        keypad_a = c.SDLK_KP_A,
        keypad_b = c.SDLK_KP_B,
        keypad_c = c.SDLK_KP_C,
        keypad_d = c.SDLK_KP_D,
        keypad_e = c.SDLK_KP_E,
        keypad_f = c.SDLK_KP_F,
        ///keypad exclusive or
        keypad_xor = c.SDLK_KP_XOR,
        keypad_power = c.SDLK_KP_POWER,
        keypad_percent = c.SDLK_KP_PERCENT,
        keypad_less = c.SDLK_KP_LESS,
        keypad_greater = c.SDLK_KP_GREATER,
        keypad_ampersand = c.SDLK_KP_AMPERSAND,
        keypad_double_ampersand = c.SDLK_KP_DBLAMPERSAND,
        keypad_vertical_bar = c.SDLK_KP_VERTICALBAR,
        keypad_double_vertical_bar = c.SDLK_KP_DBLVERTICALBAR,
        keypad_colon = c.SDLK_KP_COLON,
        keypad_hash = c.SDLK_KP_HASH,
        keypad_space = c.SDLK_KP_SPACE,
        keypad_at_sign = c.SDLK_KP_AT,
        keypad_exclamation_mark = c.SDLK_KP_EXCLAM,
        keypad_memory_store = c.SDLK_KP_MEMSTORE,
        keypad_memory_recall = c.SDLK_KP_MEMRECALL,
        keypad_memory_clear = c.SDLK_KP_MEMCLEAR,
        keypad_memory_add = c.SDLK_KP_MEMADD,
        keypad_memory_subtract = c.SDLK_KP_MEMSUBTRACT,
        keypad_memory_multiply = c.SDLK_KP_MEMMULTIPLY,
        keypad_memory_divide = c.SDLK_KP_MEMDIVIDE,
        keypad_plus_minus = c.SDLK_KP_PLUSMINUS,
        keypad_clear = c.SDLK_KP_CLEAR,
        keypad_clear_entry = c.SDLK_KP_CLEARENTRY,
        keypad_binary = c.SDLK_KP_BINARY,
        keypad_octal = c.SDLK_KP_OCTAL,
        keypad_decimal = c.SDLK_KP_DECIMAL,
        keypad_hexadecimal = c.SDLK_KP_HEXADECIMAL,
        left_control = c.SDLK_LCTRL,
        left_shift = c.SDLK_LSHIFT,
        ///left alternate
        left_alt = c.SDLK_LALT,
        left_gui = c.SDLK_LGUI,
        right_control = c.SDLK_RCTRL,
        right_shift = c.SDLK_RSHIFT,
        ///right alternate
        right_alt = c.SDLK_RALT,
        right_gui = c.SDLK_RGUI,
        mode = c.SDLK_MODE,
        audio_next = c.SDLK_AUDIONEXT,
        audio_previous = c.SDLK_AUDIOPREV,
        audio_stop = c.SDLK_AUDIOSTOP,
        audio_play = c.SDLK_AUDIOPLAY,
        audio_mute = c.SDLK_AUDIOMUTE,
        media_select = c.SDLK_MEDIASELECT,
        www = c.SDLK_WWW,
        mail = c.SDLK_MAIL,
        calculator = c.SDLK_CALCULATOR,
        computer = c.SDLK_COMPUTER,
        application_control_search = c.SDLK_AC_SEARCH,
        application_control_home = c.SDLK_AC_HOME,
        application_control_back = c.SDLK_AC_BACK,
        application_control_forward = c.SDLK_AC_FORWARD,
        application_control_stop = c.SDLK_AC_STOP,
        application_control_refresh = c.SDLK_AC_REFRESH,
        application_control_bookmarks = c.SDLK_AC_BOOKMARKS,
        brightness_down = c.SDLK_BRIGHTNESSDOWN,
        brightness_up = c.SDLK_BRIGHTNESSUP,
        display_switch = c.SDLK_DISPLAYSWITCH,
        keyboard_illumination_toggle = c.SDLK_KBDILLUMTOGGLE,
        keyboard_illumination_down = c.SDLK_KBDILLUMDOWN,
        keyboard_illumination_up = c.SDLK_KBDILLUMUP,
        eject = c.SDLK_EJECT,
        sleep = c.SDLK_SLEEP,
        application_1 = c.SDLK_APP1,
        application_2 = c.SDLK_APP2,
        audio_rewind = c.SDLK_AUDIOREWIND,
        audio_fast_forward = c.SDLK_AUDIOFASTFORWARD,
        _,
    };

    pub const KeyboardEvent = struct {
        pub const KeyState = enum(u8) {
            released = c.SDL_RELEASED,
            pressed = c.SDL_PRESSED,
        };

        timestamp: u32,
        window_id: u32,
        key_state: KeyState,
        is_repeat: bool,
        scancode: Scancode,
        keycode: Keycode,
        modifiers: KeyModifierSet,

        pub fn fromNative(native: c.SDL_KeyboardEvent) KeyboardEvent {
            switch (native.type) {
                else => unreachable,
                c.SDL_KEYDOWN, c.SDL_KEYUP => {},
            }
            return .{
                .timestamp = native.timestamp,
                .window_id = native.windowID,
                .key_state = @enumFromInt(native.state),
                .is_repeat = native.repeat != 0,
                .scancode = @enumFromInt(native.keysym.scancode),
                .keycode = @enumFromInt(native.keysym.sym),
                .modifiers = KeyModifierSet.fromNative(native.keysym.mod),
            };
        }
    };

    pub const MouseButton = enum(u3) {
        left = c.SDL_BUTTON_LEFT,
        middle = c.SDL_BUTTON_MIDDLE,
        right = c.SDL_BUTTON_RIGHT,
        extra_1 = c.SDL_BUTTON_X1,
        extra_2 = c.SDL_BUTTON_X2,
    };
    pub const MouseButtonState = struct {
        pub const NativeBitField = u32;
        pub const Storage = u5;

        storage: Storage,

        fn maskForButton(button_id: MouseButton) Storage {
            const mask: NativeBitField = @as(NativeBitField, 1) << (@intFromEnum(button_id) - 1);
            return @intCast(mask);
        }

        pub fn getPressed(self: MouseButtonState, button_id: MouseButton) bool {
            return (self.storage & maskForButton(button_id)) != 0;
        }
        pub fn setPressed(self: *MouseButtonState, button_id: MouseButton) void {
            self.storage |= maskForButton(button_id);
        }
        pub fn setUnpressed(self: *MouseButtonState, button_id: MouseButton) void {
            self.storage &= ~maskForButton(button_id);
        }

        pub fn fromNative(native: NativeBitField) MouseButtonState {
            return .{ .storage = @intCast(native) };
        }
        pub fn toNative(self: MouseButtonState) NativeBitField {
            return self.storage;
        }
    };
    pub const MouseMotionEvent = struct {
        timestamp: u32,
        /// originally named `windowID`
        window_id: u32,
        /// originally named `which`;
        /// if it comes from a touch input device,
        /// the value is c.SDL_TOUCH_MOUSEID,
        /// in which case a TouchFingerEvent was also generated.
        mouse_instance_id: u32,
        /// from original field named `state`
        button_state: MouseButtonState,
        x: i32,
        y: i32,
        /// originally named `xrel`,
        /// difference of position since last reported MouseMotionEvent,
        /// ignores screen boundaries if relative mouse mode is enabled
        /// (see c.SDL_SetRelativeMouseMode)
        delta_x: i32,
        /// originally named `yrel`,
        /// difference of position since last reported MouseMotionEvent,
        /// ignores screen boundaries if relative mouse mode is enabled
        /// (see c.SDL_SetRelativeMouseMode)
        delta_y: i32,

        pub fn fromNative(native: c.SDL_MouseMotionEvent) MouseMotionEvent {
            std.debug.assert(native.type == c.SDL_MOUSEMOTION);
            return .{
                .timestamp = native.timestamp,
                .window_id = native.windowID,
                .mouse_instance_id = native.which,
                .button_state = MouseButtonState.fromNative(native.state),
                .x = native.x,
                .y = native.y,
                .delta_x = native.xrel,
                .delta_y = native.yrel,
            };
        }
    };
    pub const MouseButtonEvent = struct {
        pub const ButtonState = enum(u8) {
            released = c.SDL_RELEASED,
            pressed = c.SDL_PRESSED,
        };

        timestamp: u32,
        /// originally named `windowID`
        window_id: u32,
        /// originally named `which`,
        /// if it comes from a touch input device,
        /// the value is c.SDL_TOUCH_MOUSEID,
        /// in which case a TouchFingerEvent was also generated.
        mouse_instance_id: u32,
        button: MouseButton,
        state: ButtonState,
        clicks: u8,
        x: i32,
        y: i32,

        pub fn fromNative(native: c.SDL_MouseButtonEvent) MouseButtonEvent {
            switch (native.type) {
                else => unreachable,
                c.SDL_MOUSEBUTTONDOWN, c.SDL_MOUSEBUTTONUP => {},
            }
            return .{
                .timestamp = native.timestamp,
                .window_id = native.windowID,
                .mouse_instance_id = native.which,
                .button = @enumFromInt(native.button),
                .state = @enumFromInt(native.state),
                .clicks = native.clicks,
                .x = native.x,
                .y = native.y,
            };
        }
    };
    pub const MouseWheelEvent = struct {
        pub const Direction = enum(u8) {
            normal = c.SDL_MOUSEWHEEL_NORMAL,
            flipped = c.SDL_MOUSEWHEEL_FLIPPED,
        };

        timestamp: u32,
        /// originally named `windowID`
        window_id: u32,
        /// originally named `which`,
        /// if it comes from a touch input device,
        /// the value is c.SDL_TOUCH_MOUSEID,
        /// in which case a TouchFingerEvent was also generated.
        mouse_instance_id: u32,
        /// originally named `x`,
        /// the amount scrolled horizontally,
        /// positive to the right and negative to the left,
        /// unless field `direction` has value `.flipped`,
        /// in which case the signs are reversed.
        delta_x: i32,
        /// originally named `y`,
        /// the amount scrolled vertically,
        /// positive away from the user and negative towards the user,
        /// unless field `direction` has value `.flipped`,
        /// in which case the signs are reversed.
        delta_y: i32,
        /// On macOS, devices are often by default configured to have
        /// "natural" scrolling direction, which flips the sign of both delta values.
        /// In this case, this field will have value `.flipped` instead of `.normal`.
        direction: Direction,

        pub fn fromNative(native: c.SDL_MouseWheelEvent) MouseWheelEvent {
            std.debug.assert(native.type == c.SDL_MOUSEWHEEL);
            return .{
                .timestamp = native.timestamp,
                .window_id = native.windowID,
                .mouse_instance_id = native.which,
                .delta_x = native.x,
                .delta_y = native.y,
                .direction = @enumFromInt(@as(u8, @intCast(native.direction))),
            };
        }
    };

    pub const JoyAxisEvent = struct {
        timestamp: u32,
        joystick_id: c.SDL_JoystickID,
        axis: u8,
        value: i16,

        pub fn fromNative(native: c.SDL_JoyAxisEvent) JoyAxisEvent {
            switch (native.type) {
                else => unreachable,
                c.SDL_JOYAXISMOTION => {},
            }
            return .{
                .timestamp = native.timestamp,
                .joystick_id = native.which,
                .axis = native.axis,
                .value = native.value,
            };
        }

        pub fn normalizedValue(self: JoyAxisEvent, comptime FloatType: type) FloatType {
            const denominator: FloatType = if (self.value > 0)
                @floatFromInt(c.SDL_JOYSTICK_AXIS_MAX)
            else
                @floatFromInt(c.SDL_JOYSTICK_AXIS_MIN);
            return @as(FloatType, @floatFromInt(self.value)) / @abs(denominator);
        }
    };

    pub const JoyHatEvent = struct {
        pub const HatValue = enum(u8) {
            centered = c.SDL_HAT_CENTERED,
            up = c.SDL_HAT_UP,
            right = c.SDL_HAT_RIGHT,
            down = c.SDL_HAT_DOWN,
            left = c.SDL_HAT_LEFT,
            right_up = c.SDL_HAT_RIGHTUP,
            right_down = c.SDL_HAT_RIGHTDOWN,
            left_up = c.SDL_HAT_LEFTUP,
            left_down = c.SDL_HAT_LEFTDOWN,
        };

        timestamp: u32,
        joystick_id: c.SDL_JoystickID,
        hat: u8,
        value: HatValue,

        pub fn fromNative(native: c.SDL_JoyHatEvent) JoyHatEvent {
            switch (native.type) {
                else => unreachable,
                c.SDL_JOYHATMOTION => {},
            }
            return .{
                .timestamp = native.timestamp,
                .joystick_id = native.which,
                .hat = native.hat,
                .value = @enumFromInt(native.value),
            };
        }
    };

    pub const JoyBallEvent = struct {
        timestamp: u32,
        joystick_id: c.SDL_JoystickID,
        ball: u8,
        relative_x: i16,
        relative_y: i16,

        pub fn fromNative(native: c.SDL_JoyBallEvent) JoyBallEvent {
            switch (native.type) {
                else => unreachable,
                c.SDL_JOYBALLMOTION => {},
            }
            return .{
                .timestamp = native.timestamp,
                .joystick_id = native.which,
                .ball = native.ball,
                .relative_x = native.xrel,
                .relative_y = native.yrel,
            };
        }
    };

    pub const JoyButtonEvent = struct {
        pub const ButtonState = enum(u8) {
            released = c.SDL_RELEASED,
            pressed = c.SDL_PRESSED,
        };

        timestamp: u32,
        joystick_id: c.SDL_JoystickID,
        button: u8,
        button_state: ButtonState,

        pub fn fromNative(native: c.SDL_JoyButtonEvent) JoyButtonEvent {
            switch (native.type) {
                else => unreachable,
                c.SDL_JOYBUTTONDOWN, c.SDL_JOYBUTTONUP => {},
            }
            return .{
                .timestamp = native.timestamp,
                .joystick_id = native.which,
                .button = native.button,
                .button_state = @enumFromInt(native.state),
            };
        }
    };

    pub const ControllerAxisEvent = struct {
        timestamp: u32,
        joystick_id: c.SDL_JoystickID,
        axis: GameController.Axis,
        value: i16,

        pub fn fromNative(native: c.SDL_ControllerAxisEvent) ControllerAxisEvent {
            switch (native.type) {
                else => unreachable,
                c.SDL_CONTROLLERAXISMOTION => {},
            }
            return .{
                .timestamp = native.timestamp,
                .joystick_id = native.which,
                .axis = @enumFromInt(native.axis),
                .value = native.value,
            };
        }

        pub fn normalizedValue(self: ControllerAxisEvent, comptime FloatType: type) FloatType {
            const denominator: FloatType = if (self.value > 0)
                @floatFromInt(c.SDL_JOYSTICK_AXIS_MAX)
            else
                @floatFromInt(c.SDL_JOYSTICK_AXIS_MIN);
            return @as(FloatType, @floatFromInt(self.value)) / @abs(denominator);
        }
    };

    pub const GameController = struct {
        pub const Button = enum(i32) {
            a = c.SDL_CONTROLLER_BUTTON_A,
            b = c.SDL_CONTROLLER_BUTTON_B,
            x = c.SDL_CONTROLLER_BUTTON_X,
            y = c.SDL_CONTROLLER_BUTTON_Y,
            back = c.SDL_CONTROLLER_BUTTON_BACK,
            guide = c.SDL_CONTROLLER_BUTTON_GUIDE,
            start = c.SDL_CONTROLLER_BUTTON_START,
            left_stick = c.SDL_CONTROLLER_BUTTON_LEFTSTICK,
            right_stick = c.SDL_CONTROLLER_BUTTON_RIGHTSTICK,
            left_shoulder = c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER,
            right_shoulder = c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
            dpad_up = c.SDL_CONTROLLER_BUTTON_DPAD_UP,
            dpad_down = c.SDL_CONTROLLER_BUTTON_DPAD_DOWN,
            dpad_left = c.SDL_CONTROLLER_BUTTON_DPAD_LEFT,
            dpad_right = c.SDL_CONTROLLER_BUTTON_DPAD_RIGHT,
            /// Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button
            misc_1 = c.SDL_CONTROLLER_BUTTON_MISC1,
            /// Xbox Elite paddle P1
            paddle_1 = c.SDL_CONTROLLER_BUTTON_PADDLE1,
            /// Xbox Elite paddle P2
            paddle_2 = c.SDL_CONTROLLER_BUTTON_PADDLE2,
            /// Xbox Elite paddle P3
            paddle_3 = c.SDL_CONTROLLER_BUTTON_PADDLE3,
            /// Xbox Elite paddle P4
            paddle_4 = c.SDL_CONTROLLER_BUTTON_PADDLE4,
            /// PS4/PS5 touchpad button
            touchpad = c.SDL_CONTROLLER_BUTTON_TOUCHPAD,
        };

        pub const Axis = enum(i32) {
            left_x = c.SDL_CONTROLLER_AXIS_LEFTX,
            left_y = c.SDL_CONTROLLER_AXIS_LEFTY,
            right_x = c.SDL_CONTROLLER_AXIS_RIGHTX,
            right_y = c.SDL_CONTROLLER_AXIS_RIGHTY,
            trigger_left = c.SDL_CONTROLLER_AXIS_TRIGGERLEFT,
            trigger_right = c.SDL_CONTROLLER_AXIS_TRIGGERRIGHT,
        };
    };

    pub const ControllerButtonEvent = struct {
        pub const ButtonState = enum(u8) {
            released = c.SDL_RELEASED,
            pressed = c.SDL_PRESSED,
        };

        timestamp: u32,
        joystick_id: c.SDL_JoystickID,
        button: GameController.Button,
        button_state: ButtonState,

        pub fn fromNative(native: c.SDL_ControllerButtonEvent) ControllerButtonEvent {
            switch (native.type) {
                else => unreachable,
                c.SDL_CONTROLLERBUTTONDOWN, c.SDL_CONTROLLERBUTTONUP => {},
            }
            return .{
                .timestamp = native.timestamp,
                .joystick_id = native.which,
                .button = @enumFromInt(native.button),
                .button_state = @enumFromInt(native.state),
            };
        }
    };

    pub const UserEvent = struct {
        /// from Event.registerEvents
        type: u32,
        timestamp: u32 = 0,
        window_id: u32 = 0,
        code: i32,
        data1: ?*anyopaque = null,
        data2: ?*anyopaque = null,

        pub fn from(native: c.SDL_UserEvent) UserEvent {
            return .{
                .type = native.type,
                .timestamp = native.timestamp,
                .window_id = native.windowID,
                .code = native.code,
                .data1 = native.data1,
                .data2 = native.data2,
            };
        }
    };

    pub const EventType = std.meta.Tag(Event);
    pub const Event = union(enum) {
        pub const CommonEvent = c.SDL_CommonEvent;
        pub const DisplayEvent = c.SDL_DisplayEvent;
        pub const TextEditingEvent = c.SDL_TextEditingEvent;
        pub const TextInputEvent = c.SDL_TextInputEvent;
        pub const JoyDeviceEvent = c.SDL_JoyDeviceEvent;
        pub const ControllerDeviceEvent = c.SDL_ControllerDeviceEvent;
        pub const AudioDeviceEvent = c.SDL_AudioDeviceEvent;
        pub const SensorEvent = c.SDL_SensorEvent;
        pub const QuitEvent = c.SDL_QuitEvent;
        pub const SysWMEvent = c.SDL_SysWMEvent;
        pub const TouchFingerEvent = c.SDL_TouchFingerEvent;
        pub const MultiGestureEvent = c.SDL_MultiGestureEvent;
        pub const DollarGestureEvent = c.SDL_DollarGestureEvent;
        pub const DropEvent = c.SDL_DropEvent;

        clip_board_update: CommonEvent,
        app_did_enter_background: CommonEvent,
        app_did_enter_foreground: CommonEvent,
        app_will_enter_foreground: CommonEvent,
        app_will_enter_background: CommonEvent,
        app_low_memory: CommonEvent,
        app_terminating: CommonEvent,
        render_targets_reset: CommonEvent,
        render_device_reset: CommonEvent,
        key_map_changed: CommonEvent,
        display: DisplayEvent,
        window: WindowEvent,
        key_down: KeyboardEvent,
        key_up: KeyboardEvent,
        text_editing: TextEditingEvent,
        text_input: TextInputEvent,
        mouse_motion: MouseMotionEvent,
        mouse_button_down: MouseButtonEvent,
        mouse_button_up: MouseButtonEvent,
        mouse_wheel: MouseWheelEvent,
        joy_axis_motion: JoyAxisEvent,
        joy_ball_motion: JoyBallEvent,
        joy_hat_motion: JoyHatEvent,
        joy_button_down: JoyButtonEvent,
        joy_button_up: JoyButtonEvent,
        joy_device_added: JoyDeviceEvent,
        joy_device_removed: JoyDeviceEvent,
        controller_axis_motion: ControllerAxisEvent,
        controller_button_down: ControllerButtonEvent,
        controller_button_up: ControllerButtonEvent,
        controller_device_added: ControllerDeviceEvent,
        controller_device_removed: ControllerDeviceEvent,
        controller_device_remapped: ControllerDeviceEvent,
        audio_device_added: AudioDeviceEvent,
        audio_device_removed: AudioDeviceEvent,
        sensor_update: SensorEvent,
        quit: QuitEvent,
        sys_wm: SysWMEvent,
        finger_down: TouchFingerEvent,
        finger_up: TouchFingerEvent,
        finger_motion: TouchFingerEvent,
        multi_gesture: MultiGestureEvent,
        dollar_gesture: DollarGestureEvent,
        dollar_record: DollarGestureEvent,
        drop_file: DropEvent,
        drop_text: DropEvent,
        drop_begin: DropEvent,
        drop_complete: DropEvent,
        user: UserEvent,

        pub fn from(raw: c.SDL_Event) Event {
            return switch (raw.type) {
                c.SDL_QUIT => Event{ .quit = raw.quit },
                c.SDL_APP_TERMINATING => Event{ .app_terminating = raw.common },
                c.SDL_APP_LOWMEMORY => Event{ .app_low_memory = raw.common },
                c.SDL_APP_WILLENTERBACKGROUND => Event{ .app_will_enter_background = raw.common },
                c.SDL_APP_DIDENTERBACKGROUND => Event{ .app_did_enter_background = raw.common },
                c.SDL_APP_WILLENTERFOREGROUND => Event{ .app_will_enter_foreground = raw.common },
                c.SDL_APP_DIDENTERFOREGROUND => Event{ .app_did_enter_foreground = raw.common },
                c.SDL_DISPLAYEVENT => Event{ .display = raw.display },
                c.SDL_WINDOWEVENT => Event{ .window = WindowEvent.fromNative(raw.window) },
                c.SDL_SYSWMEVENT => Event{ .sys_wm = raw.syswm },
                c.SDL_KEYDOWN => Event{ .key_down = KeyboardEvent.fromNative(raw.key) },
                c.SDL_KEYUP => Event{ .key_up = KeyboardEvent.fromNative(raw.key) },
                c.SDL_TEXTEDITING => Event{ .text_editing = raw.edit },
                c.SDL_TEXTINPUT => Event{ .text_input = raw.text },
                c.SDL_KEYMAPCHANGED => Event{ .key_map_changed = raw.common },
                c.SDL_MOUSEMOTION => Event{ .mouse_motion = MouseMotionEvent.fromNative(raw.motion) },
                c.SDL_MOUSEBUTTONDOWN => Event{ .mouse_button_down = MouseButtonEvent.fromNative(raw.button) },
                c.SDL_MOUSEBUTTONUP => Event{ .mouse_button_up = MouseButtonEvent.fromNative(raw.button) },
                c.SDL_MOUSEWHEEL => Event{ .mouse_wheel = MouseWheelEvent.fromNative(raw.wheel) },
                c.SDL_JOYAXISMOTION => Event{ .joy_axis_motion = JoyAxisEvent.fromNative(raw.jaxis) },
                c.SDL_JOYBALLMOTION => Event{ .joy_ball_motion = JoyBallEvent.fromNative(raw.jball) },
                c.SDL_JOYHATMOTION => Event{ .joy_hat_motion = JoyHatEvent.fromNative(raw.jhat) },
                c.SDL_JOYBUTTONDOWN => Event{ .joy_button_down = JoyButtonEvent.fromNative(raw.jbutton) },
                c.SDL_JOYBUTTONUP => Event{ .joy_button_up = JoyButtonEvent.fromNative(raw.jbutton) },
                c.SDL_JOYDEVICEADDED => Event{ .joy_device_added = raw.jdevice },
                c.SDL_JOYDEVICEREMOVED => Event{ .joy_device_removed = raw.jdevice },
                c.SDL_CONTROLLERAXISMOTION => Event{ .controller_axis_motion = ControllerAxisEvent.fromNative(raw.caxis) },
                c.SDL_CONTROLLERBUTTONDOWN => Event{ .controller_button_down = ControllerButtonEvent.fromNative(raw.cbutton) },
                c.SDL_CONTROLLERBUTTONUP => Event{ .controller_button_up = ControllerButtonEvent.fromNative(raw.cbutton) },
                c.SDL_CONTROLLERDEVICEADDED => Event{ .controller_device_added = raw.cdevice },
                c.SDL_CONTROLLERDEVICEREMOVED => Event{ .controller_device_removed = raw.cdevice },
                c.SDL_CONTROLLERDEVICEREMAPPED => Event{ .controller_device_remapped = raw.cdevice },
                c.SDL_FINGERDOWN => Event{ .finger_down = raw.tfinger },
                c.SDL_FINGERUP => Event{ .finger_up = raw.tfinger },
                c.SDL_FINGERMOTION => Event{ .finger_motion = raw.tfinger },
                c.SDL_DOLLARGESTURE => Event{ .dollar_gesture = raw.dgesture },
                c.SDL_DOLLARRECORD => Event{ .dollar_record = raw.dgesture },
                c.SDL_MULTIGESTURE => Event{ .multi_gesture = raw.mgesture },
                c.SDL_CLIPBOARDUPDATE => Event{ .clip_board_update = raw.common },
                c.SDL_DROPFILE => Event{ .drop_file = raw.drop },
                c.SDL_DROPTEXT => Event{ .drop_text = raw.drop },
                c.SDL_DROPBEGIN => Event{ .drop_begin = raw.drop },
                c.SDL_DROPCOMPLETE => Event{ .drop_complete = raw.drop },
                c.SDL_AUDIODEVICEADDED => Event{ .audio_device_added = raw.adevice },
                c.SDL_AUDIODEVICEREMOVED => Event{ .audio_device_removed = raw.adevice },
                c.SDL_SENSORUPDATE => Event{ .sensor_update = raw.sensor },
                c.SDL_RENDER_TARGETS_RESET => Event{ .render_targets_reset = raw.common },
                c.SDL_RENDER_DEVICE_RESET => Event{ .render_device_reset = raw.common },
                c.SDL_USEREVENT => Event{ .user = UserEvent.from(raw.user) },
                else => @panic("Unsupported event type detected!"),
            };
        }
    };

    pub fn pollEvent() ?Event {
        const S = struct {
            pub var event: c.SDL_Event = undefined;
        };

        if (c.SDL_PollEvent(&S.event) == 0) return null;
        return Event.from(S.event);
    }
};

pub const TTF = struct {
    pub fn init() SDLError!void {
        return errIfNotZero(c.TTF_Init(), SDLError.InitTTF);
    }

    pub fn quit() void {
        c.TTF_Quit();
    }

    pub const Font = struct {
        ptr: *c.TTF_Font,

        pub fn openFromConstMem(mem: []const u8, pt_size: u32) SDLError!Font {
            const rw_mem = c.SDL_RWFromConstMem(mem.ptr, @intCast(mem.len));
            if (rw_mem == null) return SDLError.RWFromMem;

            const ptr = try (c.TTF_OpenFontRW(rw_mem, 1, @intCast(pt_size)) orelse printSDLError(SDLError.OpenFont));

            return Font{
                .ptr = ptr,
            };
        }

        pub fn deinit(self: Font) void {
            c.TTF_CloseFont(self.ptr);
        }
    };

    pub fn renderSolid(font: Font, text: [:0]const u8, color: Color) SDLError!Surface {
        const surface = c.TTF_RenderText_Solid(font.ptr, text, color);
        if (surface == null) {
            return printSDLError(SDLError.TextRender);
        }

        return Surface{
            .ptr = @ptrCast(surface),
        };
    }

    pub fn renderSolidWrapped(font: Font, text: [:0]const u8, color: Color, wrapLength: u32) SDLError!Surface {
        const surface = c.TTF_RenderText_Solid_Wrapped(font.ptr, text, color, wrapLength);
        if (surface == null) {
            return printSDLError(SDLError.TextRender);
        }

        return Surface{
            .ptr = @ptrCast(surface),
        };
    }
};
