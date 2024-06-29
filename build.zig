const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "sdl-zig",
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (std.process.getEnvVarOwned(b.allocator, "NIX_SDL2_INCLUDE")) |SDL_include| {
        exe.addIncludePath(.{ .cwd_relative = b.pathJoin(
            &.{ SDL_include, "SDL2" },
        ) });
    } else |err| {
        switch (err) {
            error.EnvironmentVariableNotFound => {},
            else => unreachable,
        }
    }

    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkLibC();

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
