import Foundation
import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class SpyHaptics: HapticFeedback {
    var prepareCount = 0, pressCount = 0, milestoneCount = 0
    func prepare() { prepareCount += 1 }
    func press() { pressCount += 1 }
    func milestone() { milestoneCount += 1 }
}

/// Returns a fresh isolated UserDefaults suite and removes it on teardown.
func makeIsolatedDefaults(_ testCase: XCTestCase, function: String = #function) -> UserDefaults {
    let name = "dontpress.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    testCase.addTeardownBlock { defaults.removePersistentDomain(forName: name) }
    return defaults
}

/// Deterministic "random": cycles through the provided values (mod upperBound).
func scripted(_ values: [Int]) -> (Int) -> Int {
    var index = 0
    return { upper in
        defer { index += 1 }
        return values[index % values.count] % max(upper, 1)
    }
}
