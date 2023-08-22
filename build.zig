const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Module
    const ulid_module = b.addModule("ulid", .{ .source_file = .{ .path = "ulid.zig" } });

    // Static library
    const ulid_lib = b.addStaticLibrary(.{ .name = "ulid", .root_source_file = .{ .path = "ulid.zig" }, .target = target, .optimize = optimize });
    ulid_lib.linkLibC();
    const lib_step = b.step("lib", "Build the ulid static library");
    lib_step.dependOn(&ulid_lib.step);
    const install_h = b.addInstallHeaderFile("ulid.h", "ulid.h");
    lib_step.dependOn(&install_h.step);
    const install_lib = b.addInstallArtifact(ulid_lib, .{});
    lib_step.dependOn(&install_lib.step);

    // Benchmark
    const ulid_bench = b.addExecutable(.{
        .name = "ulid-bench",
        .root_source_file = .{ .path = "ulid_benchmark.zig" },
        .optimize = .ReleaseFast,
    });
    ulid_bench.addModule("ulid", ulid_module);
    ulid_bench.linkLibC();
    {
        const bench_step = b.step("benchmark", "Run the ulid benchmarks");
        bench_step.dependOn(&b.addRunArtifact(ulid_bench).step);
    }

    // Example
    const ulid_example = b.addExecutable(.{
        .name = "ulid-example",
        .root_source_file = .{ .path = "ulid_example.zig" },
    });
    ulid_example.addModule("ulid", ulid_module);
    const example_step = b.step("example", "Run the ulid example");
    example_step.dependOn(&b.addRunArtifact(ulid_example).step);

    // CLI
    const ulid_bin = b.addExecutable(.{ .name = "ulid" });
    ulid_bin.addCSourceFile(.{ .file = .{ .path = "ulid.c" }, .flags = &[_][]const u8{} });
    ulid_bin.linkLibrary(ulid_lib);
    const bin_step = b.step("cli", "Build the ulid cli");
    bin_step.dependOn(&b.addInstallArtifact(ulid_bin, .{}).step);

    // Tests
    const tests = b.step("test", "Run tests");
    const ulid_test = b.addTest(.{
        .name = "ulid-test",
        .root_source_file = .{ .path = "ulid.zig" },
    });
    ulid_test.linkLibC();
    const ulid_ctest = b.addExecutable(.{ .name = "ulidc-test" });
    ulid_ctest.addCSourceFile(.{ .file = .{ .path = "ulid.c" }, .flags = &[_][]const u8{"-DTEST"} });
    ulid_ctest.linkLibrary(ulid_lib);
    tests.dependOn(&b.addRunArtifact(ulid_ctest).step);
    tests.dependOn(&b.addRunArtifact(ulid_test).step);
    tests.dependOn(&ulid_bench.step);
    tests.dependOn(bin_step);
    tests.dependOn(lib_step);

    // Default install
    b.getInstallStep().dependOn(bin_step);
    b.getInstallStep().dependOn(lib_step);
}
