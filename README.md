# libap

> [!WARNING]
> This is currently in-development vaporware.

libap is a port of [LLVM](https://llvm.org)'s arbitrary-precision (AP) numerics
types to [Zig](https://ziglang.org), with an additional C API on top to allow C
programs to make use of the library as well.

Note that the types offered by this library have a fixed, predetermined bit
width and semantics; they do not grow to maintain precision. For example, when
creating an `ap.Int`, you have to specify exactly how many bits it should
occupy. Any operation that produces a new value will have the same bit width,
and any operation involving two `ap.Int` values requires that they have the
same bit width. Contrast with the types in
[std.math.big](https://ziglang.org/documentation/master/std/#std.math.big) which
grow as necessary.

Most applications that use arbitrary-precision numbers *do* want them to grow in
order to maintain full precision. In other words, most users should look to
`std.math.big` (or an equivalent C library). The types offered by libap are
primarily useful for compilers, emulators, cryptography, and other fields where
the desired precision is bounded and/or strict semantics are required.

## Status

libap currently covers the following LLVM types:

* [`APInt`](https://llvm.org/doxygen/classllvm_1_1APInt.html)
* [`APSInt`](https://llvm.org/doxygen/classllvm_1_1APSInt.html)
* [`APFloat`](https://llvm.org/doxygen/classllvm_1_1APFloat.html)
* [`APFixedPoint`](https://llvm.org/doxygen/classllvm_1_1APFixedPoint.html)

Changes made to these types in LLVM are periodically synchronized here. The
current `master` code is based on LLVM commit
[`bbc6504b3d2f237ed7e84dcaecb228bf2124f72e`](https://github.com/llvm/llvm-project/commit/bbc6504b3d2f237ed7e84dcaecb228bf2124f72e).

## Usage

The minimum Zig version supported by this project can be found in the
`minimum_zig_version` field of the [`build.zig.zon`](build.zig.zon) file. We
generally try to track the latest release of Zig.

To use libap in your Zig project, first add it as a package:

```bash
zig fetch --save=ap https://github.com/vezel-dev/libap/archive/vX.Y.Z.tar.gz
# Or, to use Git:
zig fetch --save=ap git+https://github.com/vezel-dev/libap.git#vX.Y.Z
```

(You can find the latest version on the
[releases page](https://github.com/vezel-dev/libap/releases).)

Then, consume the `ap` module in your `build.zig`:

```zig
const ap = b.dependency("ap", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("ap", ap.module("ap"));
```

You should now be able to `@import("ap")` in your Zig code.

<!-- TODO: Add a short API usage example. -->

## Installation

If you plan to use libap as a C library, you will likely want to install it
somewhere on your system since C does not have a package manager. To do so, grab
a source code archive from the
[releases page](https://github.com/vezel-dev/libap/releases), and run
`zig build --prefix $HOME/.local -Doptimize=ReleaseFast` or similar.

The result will look like this:

```console
$ tree $HOME/.local
/home/alexrp/.local
├── include
│   └── ap
│       └── ap.h
└── lib
    ├── libap.a
    ├── libap.so
    └── pkgconfig
        └── libap.pc
```

Assuming you have set your `C_INCLUDE_PATH`, `LD_LIBRARY_PATH`, and
`PKG_CONFIG_PATH` environment variables appropriately, you should now be able
to use libap like any other C library.

<!-- TODO: Add a short API usage example. -->

## License

This project is licensed under the terms found in
[`LICENSE-LLVM`](LICENSE-LLVM), i.e. the same license as the C++ code from which
this library was ported. This is the new LLVM license following the
[LLVM relicensing effort](https://foundation.llvm.org/docs/relicensing).
