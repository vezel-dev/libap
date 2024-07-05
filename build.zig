// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

const std = @import("std");

// TODO: https://github.com/ziglang/zig/issues/14531
const version = "0.1.0-dev";

pub fn build(b: *std.Build) anyerror!void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const install_step = b.getInstallStep();
    const check_step = b.step("check", "Run source code checks");
    const fmt_step = b.step("fmt", "Fix source code formatting");
    const test_step = b.step("test", "Build and run tests");

    const fmt_paths = &[_][]const u8{
        "lib",
        "build.zig",
        "build.zig.zon",
    };

    check_step.dependOn(&b.addFmt(.{
        .paths = fmt_paths,
        .check = true,
    }).step);

    fmt_step.dependOn(&b.addFmt(.{
        .paths = fmt_paths,
    }).step);

    _ = b.addModule("ap", .{
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "ap.zig" })),
        .target = target,
        .optimize = optimize,
        // Avoid adding opinionated build options to the module itself as those will be forced on third-party users.
    });

    install_step.dependOn(&b.addInstallHeaderFile(
        b.path(b.pathJoin(&.{ "inc", "ap.h" })),
        b.pathJoin(&.{ "ap", "ap.h" }),
    ).step);

    const stlib_step = b.addStaticLibrary(.{
        // Avoid name clash with the DLL import library on Windows.
        .name = if (target.result.os.tag == .windows) "libap" else "ap",
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "c.zig" })),
        .target = target,
        .optimize = optimize,
        .strip = optimize != .Debug,
    });

    const shlib_step = b.addSharedLibrary(.{
        .name = "ap",
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "c.zig" })),
        .target = target,
        .optimize = optimize,
        .strip = optimize != .Debug,
    });

    // On Linux, undefined symbols are allowed in shared libraries by default; override that.
    shlib_step.linker_allow_shlib_undefined = false;

    inline for (.{ stlib_step, shlib_step }) |step| {
        b.installArtifact(step);
    }

    install_step.dependOn(&b.addInstallLibFile(b.addWriteFiles().add("libap.pc", b.fmt(
        \\prefix=${{pcfiledir}}/../..
        \\exec_prefix=${{prefix}}
        \\includedir=${{prefix}}/include/ap
        \\libdir=${{prefix}}/lib
        \\
        \\Name: libap
        \\Description: A port of LLVM's arbitrary-precision numerics types to Zig with a C API.
        \\URL: https://github.com/vezel-dev/libap
        \\Version: {s}
        \\
        \\Cflags: -I${{includedir}}
        \\Libs: -L${{libdir}} -lap
    , .{version})), b.pathJoin(&.{ "pkgconfig", "libap.pc" })).step);

    const run_test_step = b.addRunArtifact(b.addTest(.{
        .name = "ap-test",
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "ap.zig" })),
        .target = target,
        .optimize = optimize,
    }));

    // Always run tests when requested, even if the binary has not changed.
    run_test_step.has_side_effects = true;

    test_step.dependOn(&run_test_step.step);
}
