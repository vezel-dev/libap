// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

const std = @import("std");

const ap = @import("ap.zig");

// TODO: Add C API surface.

test {
    _ = ap; // Include the main library test suite.

    const c = @import("ap_h");
    _ = c;

    // TODO: Verify that declarations here are compatible with declarations in `ap.h`.
}
