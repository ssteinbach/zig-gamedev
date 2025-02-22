const std = @import("std");

pub const Options = struct {
    use_double_precision: bool = false,
    enable_asserts: bool = false,
    enable_cross_platform_determinism: bool = true,
    enable_debug_renderer: bool = false,
};

pub const Package = struct {
    options: Options,
    zphysics: *std.Build.Module,
    zphysics_options: *std.Build.Module,
    zphysics_c_cpp: *std.Build.CompileStep,

    pub fn link(pkg: Package, exe: *std.Build.CompileStep) void {
        exe.addIncludePath(thisDir() ++ "/libs/JoltC");
        exe.linkLibrary(pkg.zphysics_c_cpp);
        exe.addModule("zphysics", pkg.zphysics);
        exe.addModule("zphysics_options", pkg.zphysics_options);
    }
};

pub fn package(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
    args: struct {
        options: Options = .{},
    },
) Package {
    const step = b.addOptions();
    step.addOption(bool, "use_double_precision", args.options.use_double_precision);
    step.addOption(bool, "enable_asserts", args.options.enable_asserts);
    step.addOption(bool, "enable_cross_platform_determinism", args.options.enable_cross_platform_determinism);
    step.addOption(bool, "enable_debug_renderer", args.options.enable_debug_renderer);

    const zphysics_options = step.createModule();

    const zphysics = b.createModule(.{
        .source_file = .{ .path = thisDir() ++ "/src/zphysics.zig" },
        .dependencies = &.{
            .{ .name = "zphysics_options", .module = zphysics_options },
        },
    });

    const zphysics_c_cpp = b.addStaticLibrary(.{
        .name = "zphysics",
        .target = target,
        .optimize = optimize,
    });

    const abi = (std.zig.system.NativeTargetInfo.detect(target) catch unreachable).target.abi;

    zphysics_c_cpp.addIncludePath(thisDir() ++ "/libs");
    zphysics_c_cpp.addIncludePath(thisDir() ++ "/libs/JoltC");
    zphysics_c_cpp.linkLibC();
    if (abi != .msvc)
        zphysics_c_cpp.linkLibCpp();

    const flags = &.{
        "-std=c++17",
        if (abi != .msvc) "-DJPH_COMPILER_MINGW" else "",
        if (args.options.enable_cross_platform_determinism) "-DJPH_CROSS_PLATFORM_DETERMINISTIC" else "",
        if (args.options.enable_debug_renderer) "-DJPH_DEBUG_RENDERER" else "",
        if (args.options.use_double_precision) "-DJPH_DOUBLE_PRECISION" else "",
        if (args.options.enable_asserts or zphysics_c_cpp.optimize == .Debug) "-DJPH_ENABLE_ASSERTS" else "",
        "-fno-sanitize=undefined",
    };

    zphysics_c_cpp.addCSourceFile(thisDir() ++ "/libs/JoltC/JoltPhysicsC.cpp", flags);
    zphysics_c_cpp.addCSourceFile(thisDir() ++ "/libs/JoltC/JoltPhysicsC_Extensions.cpp", flags);

    const src_dir = thisDir() ++ "/libs/Jolt";
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/AABBTree/AABBTreeBuilder.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/Color.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/Factory.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/IssueReporting.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/JobSystemThreadPool.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/JobSystemWithBarrier.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/LinearCurve.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/Memory.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/Profiler.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/RTTI.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/Semaphore.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/StringTools.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Core/TickCounter.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Geometry/ConvexHullBuilder.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Geometry/ConvexHullBuilder2D.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Geometry/Indexify.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Geometry/OrientedBox.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Math/UVec4.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Math/Vec3.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/ObjectStream.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/ObjectStreamBinaryIn.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/ObjectStreamBinaryOut.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/ObjectStreamIn.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/ObjectStreamOut.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/ObjectStreamTextIn.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/ObjectStreamTextOut.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/SerializableObject.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/ObjectStream/TypeDeclarations.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Body/Body.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Body/BodyAccess.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Body/BodyCreationSettings.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Body/BodyInterface.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Body/BodyManager.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Body/MassProperties.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Body/MotionProperties.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Character/Character.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Character/CharacterBase.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Character/CharacterVirtual.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/BroadPhase/BroadPhase.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/BroadPhase/BroadPhaseBruteForce.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/BroadPhase/BroadPhaseQuadTree.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/BroadPhase/QuadTree.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/CastConvexVsTriangles.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/CastSphereVsTriangles.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/CollideConvexVsTriangles.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/CollideSphereVsTriangles.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/CollisionDispatch.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/CollisionGroup.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/GroupFilter.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/GroupFilterTable.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/ManifoldBetweenTwoFaces.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/NarrowPhaseQuery.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/NarrowPhaseStats.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/PhysicsMaterial.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/PhysicsMaterialSimple.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/BoxShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/CapsuleShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/CompoundShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/ConvexHullShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/ConvexShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/CylinderShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/DecoratedShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/HeightFieldShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/MeshShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/MutableCompoundShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/OffsetCenterOfMassShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/RotatedTranslatedShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/ScaledShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/Shape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/SphereShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/StaticCompoundShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/TaperedCapsuleShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/Shape/TriangleShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Collision/TransformedShape.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/ConeConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/Constraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/ConstraintManager.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/ContactConstraintManager.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/DistanceConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/FixedConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/GearConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/HingeConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/MotorSettings.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/PathConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/PathConstraintPath.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/PathConstraintPathHermite.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/PointConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/RackAndPinionConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/SixDOFConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/SliderConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/SwingTwistConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/TwoBodyConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Constraints/PulleyConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/DeterminismLog.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/IslandBuilder.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/LargeIslandSplitter.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/PhysicsScene.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/PhysicsSystem.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/PhysicsUpdateContext.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/PhysicsLock.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Ragdoll/Ragdoll.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/StateRecorderImpl.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/TrackedVehicleController.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/VehicleAntiRollBar.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/VehicleCollisionTester.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/VehicleConstraint.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/VehicleController.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/VehicleDifferential.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/VehicleEngine.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/VehicleTrack.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/VehicleTransmission.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/Wheel.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/WheeledVehicleController.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Physics/Vehicle/MotorcycleController.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/RegisterTypes.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Renderer/DebugRenderer.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Renderer/DebugRendererPlayback.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Renderer/DebugRendererRecorder.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Skeleton/SkeletalAnimation.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Skeleton/Skeleton.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Skeleton/SkeletonMapper.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/Skeleton/SkeletonPose.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/TriangleGrouper/TriangleGrouperClosestCentroid.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/TriangleGrouper/TriangleGrouperMorton.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/TriangleSplitter/TriangleSplitter.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/TriangleSplitter/TriangleSplitterBinning.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/TriangleSplitter/TriangleSplitterFixedLeafSize.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/TriangleSplitter/TriangleSplitterLongestAxis.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/TriangleSplitter/TriangleSplitterMean.cpp", flags);
    zphysics_c_cpp.addCSourceFile(src_dir ++ "/TriangleSplitter/TriangleSplitterMorton.cpp", flags);

    return .{
        .options = args.options,
        .zphysics = zphysics,
        .zphysics_options = zphysics_options,
        .zphysics_c_cpp = zphysics_c_cpp,
    };
}

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run zphysics tests");
    test_step.dependOn(runTests(b, optimize, target));
}

pub fn runTests(
    b: *std.Build,
    optimize: std.builtin.Mode,
    target: std.zig.CrossTarget,
) *std.Build.Step {
    const parent_step = b.allocator.create(std.Build.Step) catch @panic("OOM");
    parent_step.* = std.Build.Step.init(.{ .id = .custom, .name = "zphysics-tests", .owner = b });

    const test0 = testStep(b, "zphysics-tests-f32", optimize, target, .{
        .use_double_precision = false,
        .enable_debug_renderer = true,
    });
    parent_step.dependOn(&test0.step);

    // const test1 = testStep(b, "zphysics-tests-f64", optimize, target, .{
    //     .use_double_precision = true,
    //     .enable_debug_renderer = true,
    // });
    // parent_step.dependOn(&test1.step);

    return parent_step;
}

fn testStep(
    b: *std.Build,
    name: []const u8,
    optimize: std.builtin.Mode,
    target: std.zig.CrossTarget,
    options: Options,
) *std.Build.RunStep {
    const test_exe = b.addTest(.{
        .name = name,
        .root_source_file = .{ .path = thisDir() ++ "/src/zphysics.zig" },
        .target = target,
        .optimize = optimize,
    });

    const abi = (std.zig.system.NativeTargetInfo.detect(target) catch unreachable).target.abi;

    test_exe.addCSourceFile(
        thisDir() ++ "/libs/JoltC/JoltPhysicsC_Tests.c",
        &.{
            "-std=c11",
            if (abi != .msvc) "-DJPH_COMPILER_MINGW" else "",
            if (options.use_double_precision) "-DJPH_DOUBLE_PRECISION" else "",
            if (options.enable_asserts or optimize == .Debug) "-DJPH_ENABLE_ASSERTS" else "",
            if (options.enable_cross_platform_determinism) "-DJPH_CROSS_PLATFORM_DETERMINISTIC" else "",
            if (options.enable_debug_renderer) "-DJPH_DEBUG_RENDERER" else "",
            "-fno-sanitize=undefined",
        },
    );

    const zphysics_pkg = package(b, target, optimize, .{ .options = options });
    zphysics_pkg.link(test_exe);

    test_exe.addModule("zphysics_options", zphysics_pkg.zphysics_options);

    return b.addRunArtifact(test_exe);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
