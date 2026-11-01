import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class AppIconChoiceTests: XCTestCase {
    private func stats(best: Int = 0, total: Int = 0) -> PressStats {
        PressStats(currentRun: 0, personalBest: best, totalPresses: total)
    }

    func testOneChoicePerThemeInThemeOrder() {
        XCTAssertEqual(AppIconChoice.all.map(\.theme), ButtonTheme.all)
        XCTAssertEqual(Set(AppIconChoice.all.map(\.id)).count, AppIconChoice.all.count)
    }

    func testClassicIsThePrimaryIconAndOthersHaveUniqueAlternateNames() {
        XCTAssertEqual(AppIconChoice.all.first, .primary)
        XCTAssertNil(AppIconChoice.primary.iconName)
        let alternates = AppIconChoice.all.dropFirst().map(\.iconName)
        XCTAssertTrue(alternates.allSatisfy { $0 != nil })
        XCTAssertEqual(Set(alternates.compactMap { $0 }).count, alternates.count)
    }

    func testAlternateNamesMatchTheBuildSetting() {
        // Must match ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES in Scripts/generate_xcodeproj.py.
        let expected: Set = ["AppIcon-Cobalt", "AppIcon-Stealth", "AppIcon-Radioactive", "AppIcon-Gold"]
        XCTAssertEqual(Set(AppIconChoice.all.compactMap(\.iconName)), expected)
        XCTAssertEqual(AppIconChoice.choice(forIconName: "AppIcon-Gold").theme, .gold)
        XCTAssertEqual(AppIconChoice.choice(forIconName: "AppIcon-Cobalt").theme, .cobalt)
    }

    func testUnknownOrNilIconNameResolvesToPrimary() {
        XCTAssertEqual(AppIconChoice.choice(forIconName: nil), .primary)
        XCTAssertEqual(AppIconChoice.choice(forIconName: "Nope"), .primary)
        XCTAssertEqual(AppIconChoice.choice(forIconName: ""), .primary)
    }

    func testAlternateIconsArePro() {
        for choice in AppIconChoice.all {
            for s in [stats(), stats(best: 10, total: 10), stats(best: 250, total: 500), stats(best: Int.max, total: Int.max)] {
                // Playing never unlocks an alternate icon: they are a Pro perk. Classic is always on.
                XCTAssertEqual(choice.isUnlocked(for: s, isPro: false), choice.iconName == nil, choice.id)
            }
        }
    }

    func testProUnlocksEveryIcon() {
        XCTAssertTrue(AppIconChoice.all.allSatisfy { $0.isUnlocked(for: stats(), isPro: true) })
    }

    func testStatusesAtZeroWithoutPro() {
        let statuses = AppIconChoice.statuses(stats: stats(), isPro: false, currentIconName: nil)
        XCTAssertEqual(statuses.filter(\.isUnlocked).map(\.id), ["classic"])
        XCTAssertEqual(statuses.filter(\.isSelected).map(\.id), ["classic"])
        XCTAssertNil(statuses[0].requirementText)
        let gold = statuses.first { $0.id == "gold" }!
        XCTAssertEqual(gold.requirementText, "Included with Pro")
    }

    func testStatusesReflectCurrentAlternateIcon() {
        let statuses = AppIconChoice.statuses(stats: stats(), isPro: true, currentIconName: "AppIcon-Radioactive")
        XCTAssertEqual(statuses.filter(\.isSelected).map(\.id), ["radioactive"])
        XCTAssertTrue(statuses.allSatisfy(\.isUnlocked))
        XCTAssertTrue(statuses.allSatisfy { $0.requirementText == nil })
    }
}
