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

    func testUnlockFollowsTheThemeRule() {
        for choice in AppIconChoice.all {
            for s in [stats(), stats(best: 10, total: 10), stats(best: 249, total: 499), stats(best: 250, total: 500)] {
                XCTAssertEqual(choice.isUnlocked(for: s), choice.theme.isUnlocked(for: s), choice.id)
            }
        }
        let cobalt = AppIconChoice.all.first { $0.theme == .cobalt }!
        XCTAssertFalse(cobalt.isUnlocked(for: stats(best: 9)))
        XCTAssertTrue(cobalt.isUnlocked(for: stats(best: 10)))
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
        XCTAssertEqual(gold.requirementText, "\(ButtonTheme.gold.rule.requirementText), or unlock with Pro")
    }

    func testStatusesReflectCurrentAlternateIcon() {
        let statuses = AppIconChoice.statuses(stats: stats(), isPro: true, currentIconName: "AppIcon-Radioactive")
        XCTAssertEqual(statuses.filter(\.isSelected).map(\.id), ["radioactive"])
        XCTAssertTrue(statuses.allSatisfy(\.isUnlocked))
        XCTAssertTrue(statuses.allSatisfy { $0.requirementText == nil })
    }
}
