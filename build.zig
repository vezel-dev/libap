// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

const std = @import("std");

// TODO: https://github.com/ziglang/zig/issues/14531
const version = std.SemanticVersion.parse("0.1.0-dev") catch unreachable;

pub fn build(b: *std.Build) anyerror!void {
    // TODO: https://github.com/ziglang/zig/pull/23239
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link binaries statically or dynamically") orelse .static;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const strip = b.option(bool, "strip", "Omit debug information in binaries");
    const code_model = b.option(std.builtin.CodeModel, "code-model", "Assume a particular code model") orelse .default;
    const valgrind = b.option(bool, "valgrind", "Enable Valgrind client requests");

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

    _ = b.addModule("ap", .{
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "ap.zig" })),
        // Inherit other options from consumers of the module.
    });

    const lib_step = b.addLibrary(.{
        .linkage = linkage,
        .name = "ap",
        .root_module = b.createModule(.{
            .root_source_file = b.path(b.pathJoin(&.{ "lib", "c.zig" })),
            .target = target,
            .optimize = optimize,
            .strip = strip,
            .code_model = code_model,
            .valgrind = valgrind,
        }),
        .version = version,
    });

    // On Linux, undefined symbols are allowed in shared libraries by default; override that.
    lib_step.linker_allow_shlib_undefined = false;

    lib_step.installHeadersDirectory(b.path("inc"), "ap", .{});

    b.installArtifact(lib_step);

    install_tls.dependOn(
        &b.addInstallLibFile(
            b.addWriteFiles().add(
                "libap.pc",
                b.fmt(
                    \\prefix={s}
                    \\includedir=${{prefix}}/include/ap
                    \\libdir=${{prefix}}/lib
                    \\
                    \\Name: libap
                    \\Description: An arbitrary-precision numerics library, ported from LLVM to Zig with a C API.
                    \\URL: https://github.com/vezel-dev/libap
                    \\Version: {}
                    \\
                    \\Cflags: -I${{includedir}}
                    \\Libs: -L${{libdir}} -lap
                , .{ b.install_prefix, version }),
            ),
            b.pathJoin(&.{ "pkgconfig", "libap.pc" }),
        ).step,
    );

    b.installDirectory(.{
        .source_dir = lib_step.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = b.pathJoin(&.{ "share", "doc", "libap", "html" }),
    });

    const test_step = b.addTest(.{
        .name = "ap-test",
        .root_module = b.createModule(.{
            .root_source_file = b.path(b.pathJoin(&.{ "lib", "ap.zig" })),
            .target = target,
            .optimize = optimize,
            .strip = strip,
            .code_model = code_model,
            .valgrind = valgrind,
        }),
    });

    test_step.linkage = linkage;

    const run_test_step = b.addRunArtifact(test_step);

    // Always run tests when requested, even if the binary has not changed.
    run_test_step.has_side_effects = true;

    test_tls.dependOn(&run_test_step.step);
}
