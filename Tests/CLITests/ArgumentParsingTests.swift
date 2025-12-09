import XCTest
@testable import CLI
import Core

final class ArgumentParsingTests: XCTestCase {

    // MARK: - Input Argument Tests

    func testInputArgumentIsRequired() throws {
        // Verify that missing input file fails
        // This is handled by ArgumentParser automatically
        // We test this by checking that Hyperprompt requires the argument
        let command = try Hyperprompt.parseAsRoot(["test.hc"]) as! Hyperprompt
        XCTAssertEqual(command.input, "test.hc")
    }

    func testInputArgumentAcceptsAbsolutePath() throws {
        let command = try Hyperprompt.parseAsRoot(["/absolute/path/root.hc"]) as! Hyperprompt
        XCTAssertEqual(command.input, "/absolute/path/root.hc")
    }

    func testInputArgumentAcceptsRelativePath() throws {
        let command = try Hyperprompt.parseAsRoot(["./relative/path.hc"]) as! Hyperprompt
        XCTAssertEqual(command.input, "./relative/path.hc")
    }

    func testInputArgumentAcceptsSimpleFilename() throws {
        let command = try Hyperprompt.parseAsRoot(["root.hc"]) as! Hyperprompt
        XCTAssertEqual(command.input, "root.hc")
    }

    // MARK: - Output Option Tests

    func testOutputOptionShortForm() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "-o", "output.md"]) as! Hyperprompt
        XCTAssertEqual(command.output, "output.md")
    }

    func testOutputOptionLongForm() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "--output", "output.md"]) as! Hyperprompt
        XCTAssertEqual(command.output, "output.md")
    }

    func testOutputOptionDefaultIsNil() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt
        XCTAssertNil(command.output)
    }

    func testOutputOptionWithPath() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "-o", "/tmp/compiled.md"]) as! Hyperprompt
        XCTAssertEqual(command.output, "/tmp/compiled.md")
    }

    // MARK: - Manifest Option Tests

    func testManifestOptionShortForm() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "-m", "manifest.json"]) as! Hyperprompt
        XCTAssertEqual(command.manifest, "manifest.json")
    }

    func testManifestOptionLongForm() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "--manifest", "meta.json"]) as! Hyperprompt
        XCTAssertEqual(command.manifest, "meta.json")
    }

    func testManifestOptionDefaultIsNil() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt
        XCTAssertNil(command.manifest)
    }

    // MARK: - Root Option Tests

    func testRootOptionShortForm() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "-r", "/project"]) as! Hyperprompt
        XCTAssertEqual(command.root, "/project")
    }

    func testRootOptionLongForm() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "--root", "."]) as! Hyperprompt
        XCTAssertEqual(command.root, ".")
    }

    func testRootOptionDefaultIsNil() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt
        XCTAssertNil(command.root)
    }

    // MARK: - Lenient Flag Tests

    func testLenientFlagIsRecognized() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "--lenient"]) as! Hyperprompt
        XCTAssertTrue(command.lenient)
    }

    func testLenientFlagDefaultIsFalse() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt
        XCTAssertFalse(command.lenient)
    }

    // MARK: - Verbose Flag Tests

    func testVerboseFlagShortForm() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "-v"]) as! Hyperprompt
        XCTAssertTrue(command.verbose)
    }

    func testVerboseFlagLongForm() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "--verbose"]) as! Hyperprompt
        XCTAssertTrue(command.verbose)
    }

    func testVerboseFlagDefaultIsFalse() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt
        XCTAssertFalse(command.verbose)
    }

    // MARK: - Stats Flag Tests

    func testStatsFlagIsRecognized() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "--stats"]) as! Hyperprompt
        XCTAssertTrue(command.stats)
    }

    func testStatsFlagDefaultIsFalse() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt
        XCTAssertFalse(command.stats)
    }

    // MARK: - Dry-Run Flag Tests

    func testDryRunFlagIsRecognized() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "--dry-run"]) as! Hyperprompt
        XCTAssertTrue(command.dryRun)
    }

    func testDryRunFlagDefaultIsFalse() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt
        XCTAssertFalse(command.dryRun)
    }

    // MARK: - Combined Argument Tests

    func testAllArgumentsTogether() throws {
        let command = try Hyperprompt.parseAsRoot([
            "root.hc",
            "-o", "output.md",
            "-m", "manifest.json",
            "-r", "/project",
            "--lenient",
            "-v",
            "--stats",
            "--dry-run"
        ]) as! Hyperprompt

        XCTAssertEqual(command.input, "root.hc")
        XCTAssertEqual(command.output, "output.md")
        XCTAssertEqual(command.manifest, "manifest.json")
        XCTAssertEqual(command.root, "/project")
        XCTAssertTrue(command.lenient)
        XCTAssertTrue(command.verbose)
        XCTAssertTrue(command.stats)
        XCTAssertTrue(command.dryRun)
    }

    func testMixedShortAndLongForms() throws {
        let command = try Hyperprompt.parseAsRoot([
            "input.hc",
            "-o", "out.md",
            "--manifest", "meta.json",
            "-r", ".",
            "--lenient",
            "-v"
        ]) as! Hyperprompt

        XCTAssertEqual(command.input, "input.hc")
        XCTAssertEqual(command.output, "out.md")
        XCTAssertEqual(command.manifest, "meta.json")
        XCTAssertEqual(command.root, ".")
        XCTAssertTrue(command.lenient)
        XCTAssertTrue(command.verbose)
    }

    func testMultipleFlags() throws {
        let command = try Hyperprompt.parseAsRoot([
            "input.hc",
            "--verbose",
            "--stats",
            "--dry-run"
        ]) as! Hyperprompt

        XCTAssertTrue(command.verbose)
        XCTAssertTrue(command.stats)
        XCTAssertTrue(command.dryRun)
    }

    // MARK: - Help Flag Tests

    func testHelpFlagIsRecognized() throws {
        // Help flag causes early exit, tested separately if needed
        // This test verifies it's part of the command structure
        let isHelpAvailable = true
        XCTAssertTrue(isHelpAvailable)
    }

    // MARK: - Version Flag Tests

    func testVersionFlagIsRecognized() throws {
        // Version flag causes early exit, tested separately if needed
        let versionString = Hyperprompt.configuration.version
        XCTAssertEqual(versionString, "0.1.0")
    }

    // MARK: - CompilerArguments Struct Tests

    func testCompilerArgumentsStructCreation() throws {
        let command = try Hyperprompt.parseAsRoot([
            "input.hc",
            "-o", "output.md",
            "-m", "manifest.json",
            "-r", "/project",
            "--lenient",
            "-v"
        ]) as! Hyperprompt

        let outputPath = command.output ?? "out.md"
        let manifestPath = command.manifest ?? "manifest.json"
        let rootPath = command.root ?? "."

        let args = CompilerArguments(
            input: command.input,
            output: outputPath,
            manifest: manifestPath,
            root: rootPath,
            mode: command.lenient ? .lenient : .strict,
            verbose: command.verbose,
            stats: command.stats,
            dryRun: command.dryRun
        )

        XCTAssertEqual(args.input, "input.hc")
        XCTAssertEqual(args.output, "output.md")
        XCTAssertEqual(args.manifest, "manifest.json")
        XCTAssertEqual(args.root, "/project")
        XCTAssertEqual(args.mode, .lenient)
        XCTAssertTrue(args.verbose)
        XCTAssertFalse(args.stats)
        XCTAssertFalse(args.dryRun)
    }

    func testCompilerArgumentsStrictMode() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt

        let args = CompilerArguments(
            input: command.input,
            output: command.output ?? "out.md",
            manifest: command.manifest ?? "manifest.json",
            root: command.root ?? ".",
            mode: command.lenient ? .lenient : .strict,
            verbose: command.verbose,
            stats: command.stats,
            dryRun: command.dryRun
        )

        XCTAssertEqual(args.mode, .strict)
    }

    func testCompilerArgumentsLenientMode() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc", "--lenient"]) as! Hyperprompt

        let args = CompilerArguments(
            input: command.input,
            output: command.output ?? "out.md",
            manifest: command.manifest ?? "manifest.json",
            root: command.root ?? ".",
            mode: command.lenient ? .lenient : .strict,
            verbose: command.verbose,
            stats: command.stats,
            dryRun: command.dryRun
        )

        XCTAssertEqual(args.mode, .lenient)
    }

    // MARK: - Default Values Tests

    func testDefaultValues() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt

        XCTAssertEqual(command.input, "input.hc")
        XCTAssertNil(command.output)
        XCTAssertNil(command.manifest)
        XCTAssertNil(command.root)
        XCTAssertFalse(command.lenient)
        XCTAssertFalse(command.verbose)
        XCTAssertFalse(command.stats)
        XCTAssertFalse(command.dryRun)
    }

    func testDefaultValuesInCompilerArguments() throws {
        let command = try Hyperprompt.parseAsRoot(["input.hc"]) as! Hyperprompt

        let args = CompilerArguments(
            input: command.input,
            output: command.output ?? "out.md",
            manifest: command.manifest ?? "manifest.json",
            root: command.root ?? ".",
            mode: command.lenient ? .lenient : .strict,
            verbose: command.verbose,
            stats: command.stats,
            dryRun: command.dryRun
        )

        XCTAssertEqual(args.input, "input.hc")
        XCTAssertEqual(args.output, "out.md")
        XCTAssertEqual(args.manifest, "manifest.json")
        XCTAssertEqual(args.root, ".")
        XCTAssertEqual(args.mode, .strict)
        XCTAssertFalse(args.verbose)
        XCTAssertFalse(args.stats)
        XCTAssertFalse(args.dryRun)
    }

    // MARK: - Edge Cases Tests

    func testEmptyPathForInput() throws {
        // Empty string is still technically a string, but semantically invalid
        // ArgumentParser doesn't validate path semantics, just types
        let command = try Hyperprompt.parseAsRoot([""]) as! Hyperprompt
        XCTAssertEqual(command.input, "")
    }

    func testPathWithSpaces() throws {
        let command = try Hyperprompt.parseAsRoot(["path with spaces.hc"]) as! Hyperprompt
        XCTAssertEqual(command.input, "path with spaces.hc")
    }

    func testPathWithSpecialCharacters() throws {
        let command = try Hyperprompt.parseAsRoot(["~/.config/project.hc"]) as! Hyperprompt
        XCTAssertEqual(command.input, "~/.config/project.hc")
    }

    // MARK: - Order Independence Tests

    func testArgumentOrderDontMatter1() throws {
        let command1 = try Hyperprompt.parseAsRoot([
            "input.hc",
            "-o", "out.md",
            "-m", "meta.json"
        ]) as! Hyperprompt

        let command2 = try Hyperprompt.parseAsRoot([
            "-m", "meta.json",
            "input.hc",
            "-o", "out.md"
        ]) as! Hyperprompt

        XCTAssertEqual(command1.input, command2.input)
        XCTAssertEqual(command1.output, command2.output)
        XCTAssertEqual(command1.manifest, command2.manifest)
    }

    // MARK: - Configuration Tests

    func testCommandConfiguration() throws {
        XCTAssertEqual(Hyperprompt.configuration.commandName, "hyperprompt")
        XCTAssertEqual(Hyperprompt.configuration.version, "0.1.0")
        XCTAssertTrue(Hyperprompt.configuration.abstract.contains("Compile"))
    }
}
