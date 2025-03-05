// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

const std = @import("std");

// TODO: https://github.com/ziglang/zig/issues/14531
const version = "0.1.0-dev";

pub fn build(b: *std.Build) anyerror!void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const install_tls = b.getInstallStep();
    const check_tls = b.step("check", "Run source code checks");
    const fmt_tls = b.step("fmt", "Fix source code formatting");
    const test_tls = b.step("test", "Build and run tests");

    const fmt_paths = &[_][]const u8{
        "lib",
        "build.zig",
        "build.zig.zon",
    };

    check_tls.dependOn(&b.addFmt(.{
        .paths = fmt_paths,
        .check = true,
    }).step);

    fmt_tls.dependOn(&b.addFmt(.{
        .paths = fmt_paths,
    }).step);

    const ap_mod = b.addModule("ap", .{
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "ap.zig" })),
        .target = target,
        .optimize = optimize,
    });

    const ap_c_mod = b.addModule("ap", .{
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "c.zig" })),
        .target = target,
        .optimize = optimize,
    });

    const stlib_step = b.addLibrary(.{
        .linkage = .static,
        // Avoid name clash with the DLL import library on Windows.
        .name = if (target.result.os.tag == .windows) "libap" else "ap",
        .root_module = ap_c_mod,
    });

    const shlib_step = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "ap",
        .root_module = ap_c_mod,
    });

    // On Linux, undefined symbols are allowed in shared libraries by default; override that.
    shlib_step.linker_allow_shlib_undefined = false;

    inline for (.{ stlib_step, shlib_step }) |step| {
        step.installHeadersDirectory(b.path("inc"), "ap", .{});

        b.installArtifact(step);
    }

    install_tls.dependOn(&b.addInstallLibFile(b.addWriteFiles().add("libap.pc", b.fmt(
        \\prefix=${{pcfiledir}}/../..
        \\exec_prefix=${{prefix}}
        \\includedir=${{prefix}}/include/ap
        \\libdir=${{prefix}}/lib
        \\
        \\Name: libap
        \\Description: An arbitrary-precision numerics library, ported from LLVM to Zig with a C API.
        \\URL: https://github.com/vezel-dev/libap
        \\Version: {s}
        \\
        \\Cflags: -I${{includedir}}
        \\Libs: -L${{libdir}} -lap
    , .{version})), b.pathJoin(&.{ "pkgconfig", "libap.pc" })).step);

    const run_test_step = b.addRunArtifact(b.addTest(.{
        .name = "ap-test",
        .root_module = ap_mod,
    }));

    // Always run tests when requested, even if the binary has not changed.
    run_test_step.has_side_effects = true;

    test_tls.dependOn(&run_test_step.step);
}
