import Foundation
import XCTest
import Core
@testable import Emitter

final class ManifestDependencyTests: XCTestCase {
    func testManifestSortsDependenciesDeterministically() {
        let manifest = Manifest(
            root: "root.hc",
            sources: [],
            dependencies: [
                ManifestDependency(from: "z.hc", to: "z.md"),
                ManifestDependency(from: "a.hc", to: "z.md"),
                ManifestDependency(from: "a.hc", to: "a.md"),
            ],
            timestamp: "2026-07-27T00:00:00Z",
            version: "0.1.0"
        )

        XCTAssertEqual(
            manifest.dependencies,
            [
                ManifestDependency(from: "a.hc", to: "a.md"),
                ManifestDependency(from: "a.hc", to: "z.md"),
                ManifestDependency(from: "z.hc", to: "z.md"),
            ]
        )
    }

    func testManifestDecodesLegacyJSONWithoutDependencies() throws {
        let legacy = """
        {
          "root": "root.hc",
          "sources": [],
          "timestamp": "2026-07-27T00:00:00Z",
          "version": "0.1.0"
        }
        """

        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(legacy.utf8))

        XCTAssertEqual(manifest.dependencies, [])
        XCTAssertEqual(manifest.schemaVersion, 0)
    }

    func testGeneratorDeduplicatesDependencies() {
        let generator = ManifestGenerator()
        let manifest = generator.generate(
            builder: ManifestBuilder(),
            dependencies: [
                ManifestDependency(from: "root.hc", to: "intro.md"),
                ManifestDependency(from: "root.hc", to: "intro.md"),
            ],
            version: "0.1.0",
            root: "root.hc",
            timestamp: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(
            manifest.dependencies,
            [ManifestDependency(from: "root.hc", to: "intro.md")]
        )
    }
}
