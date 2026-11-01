import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class SetPieceCatalogTests: XCTestCase {
    func testEveryMilestoneHasExactlyOneSetPiece() {
        for milestone in Milestone.thresholds {
            let matches = SetPieceCatalog.all.filter { $0.milestone == milestone }
            XCTAssertEqual(matches.count, 1, "milestone \(milestone)")
            XCTAssertEqual(SetPieceCatalog.setPiece(forMilestone: milestone), matches.first)
        }
        XCTAssertEqual(SetPieceCatalog.all.count, Milestone.thresholds.count)
        XCTAssertNil(SetPieceCatalog.setPiece(forMilestone: 11))
        XCTAssertNil(SetPieceCatalog.setPiece(forMilestone: 0))
    }

    func testSelectionIsDeterministic() {
        XCTAssertEqual(SetPieceCatalog.setPiece(forMilestone: 10)?.id, "flinch")
        XCTAssertEqual(SetPieceCatalog.setPiece(forMilestone: 1000)?.id, "ending")
        XCTAssertEqual(SetPieceCatalog.setPiece(forMilestone: 50), SetPieceCatalog.setPiece(forMilestone: 50))
    }

    func testIdsAndNamesAreUniqueAndNonEmpty() {
        let ids = SetPieceCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for piece in SetPieceCatalog.all {
            XCTAssertFalse(piece.name.isEmpty)
            XCTAssertFalse(piece.reactionLine.isEmpty)
            XCTAssertFalse(piece.id.isEmpty)
        }
    }

    func testScriptsAreWellFormed() {
        for piece in SetPieceCatalog.all {
            XCTAssertGreaterThan(piece.duration, 0, piece.id)
            XCTAssertLessThanOrEqual(piece.duration, 6, "\(piece.id): keep set-pieces short; taps keep counting anyway")
            XCTAssertFalse(piece.steps.isEmpty, piece.id)

            let times = piece.steps.map(\.at)
            XCTAssertEqual(times, times.sorted(), "\(piece.id): steps must be sorted by time")
            XCTAssertGreaterThanOrEqual(times.first ?? -1, 0, piece.id)
            XCTAssertLessThanOrEqual(times.last ?? .infinity, piece.duration, piece.id)

            XCTAssertEqual(piece.steps.last?.action, .restore, "\(piece.id): the last step must restore the button")
            XCTAssertEqual(piece.steps.last?.at, piece.duration, "\(piece.id): restore happens exactly at the end")

            let hapticTimes = piece.haptics.map(\.at)
            XCTAssertEqual(hapticTimes, hapticTimes.sorted(), "\(piece.id): haptic cues must be sorted")
            for cue in piece.haptics {
                XCTAssertGreaterThanOrEqual(cue.at, 0, piece.id)
                XCTAssertLessThanOrEqual(cue.at, piece.duration, piece.id)
            }
        }
    }

    func testValuesStayInSaneRanges() {
        for piece in SetPieceCatalog.all {
            for step in piece.steps {
                switch step.action {
                case .scale(let s): XCTAssertTrue((0...1.5).contains(s), piece.id)
                case .opacity(let o): XCTAssertTrue((0...1).contains(o), piece.id)
                case .offset(let x, let y):
                    XCTAssertTrue(abs(x) <= 2 && abs(y) <= 2, "\(piece.id): offsets are in button diameters")
                case .shake(let amplitude, let cycles):
                    XCTAssertTrue(amplitude >= 0 && amplitude <= 0.1, piece.id)
                    XCTAssertTrue(cycles >= 0 && cycles <= 40, piece.id)
                case .lock(let progress):
                    if let progress { XCTAssertTrue((0...1).contains(progress), piece.id) }
                case .flash(let peak): XCTAssertTrue((0...1).contains(peak), piece.id)
                case .caption(let text):
                    if let text { XCTAssertFalse(text.isEmpty, piece.id) }
                case .rotation, .glitch, .restore: break
                }
            }
        }
    }

    func testTremorHasAHapticCrescendo() {
        let kinds = SetPieceCatalog.tremor.haptics.map(\.kind)
        XCTAssertEqual(kinds.first, .light)
        XCTAssertTrue(kinds.contains(.medium))
        XCTAssertTrue(kinds.contains(.heavy))
        XCTAssertGreaterThanOrEqual(kinds.count, 6)
    }

    func testEndingIsNamedAndFinal() {
        let ending = SetPieceCatalog.setPiece(forMilestone: 1000)
        XCTAssertEqual(ending?.name, "The End of the Button")
        XCTAssertEqual(ending, SetPieceCatalog.all.last)
    }

    func testReducedMotionDropsMotionButKeepsTheJoke() {
        for piece in SetPieceCatalog.all {
            let reduced = piece.steps(reduceMotion: true)
            XCTAssertEqual(reduced, piece.reducedMotionSteps)
            XCTAssertEqual(piece.steps(reduceMotion: false), piece.steps)

            for step in reduced {
                switch step.action {
                case .scale, .offset, .rotation, .shake, .glitch:
                    XCTFail("\(piece.id): motion step \(step.action) survived Reduce Motion")
                default: break
                }
            }
            XCTAssertEqual(reduced.last?.action, .restore, piece.id)
            XCTAssertTrue(reduced.contains { if case .flash = $0.action { return true } else { return false } },
                          "\(piece.id): Reduce Motion replaces motion with a short flash")
            let originalCaptions = piece.steps.compactMap { if case .caption(let t) = $0.action { return t } else { return nil } }
            let reducedCaptions = reduced.compactMap { if case .caption(let t) = $0.action { return t } else { return nil } }
            XCTAssertEqual(originalCaptions, reducedCaptions, "\(piece.id): captions are kept so the gag stays readable")
            let times = reduced.map(\.at)
            XCTAssertEqual(times, times.sorted(), piece.id)
        }
    }

    func testReducedMotionDoesNotDuplicateAnExistingFlash() {
        let glitch = SetPieceCatalog.glitch
        let flashes = glitch.reducedMotionSteps.filter { if case .flash = $0.action { return true } else { return false } }
        XCTAssertEqual(flashes.count, 1)
        let flinch = SetPieceCatalog.flinch
        let flinchFlashes = flinch.reducedMotionSteps.filter { if case .flash = $0.action { return true } else { return false } }
        XCTAssertEqual(flinchFlashes.count, 1)
        XCTAssertEqual(flinch.reducedMotionSteps.first?.at, 0)
    }
}

final class SetPieceDirectorTests: XCTestCase {
    func testStartsNothingWithoutMilestone() {
        var director = SetPieceDirector()
        XCTAssertEqual(director.registerPress(milestone: nil), .none)
        XCTAssertFalse(director.isPlaying)
        XCTAssertNil(director.active)
    }

    func testStartsSetPieceOnMilestone() {
        var director = SetPieceDirector()
        let outcome = director.registerPress(milestone: 10)
        XCTAssertEqual(outcome, .start(SetPieceCatalog.flinch))
        XCTAssertTrue(director.isPlaying)
        XCTAssertEqual(director.active?.id, "flinch")
    }

    func testUnknownMilestoneStartsNothing() {
        var director = SetPieceDirector()
        XCTAssertEqual(director.registerPress(milestone: 7), .none)
        XCTAssertFalse(director.isPlaying)
    }

    func testPressesDuringSetPieceAreNeverBlocked() {
        var director = SetPieceDirector()
        _ = director.registerPress(milestone: 10)
        for _ in 0..<5 {
            XCTAssertTrue(director.acceptsPresses)
            XCTAssertEqual(director.registerPress(milestone: nil), .none)
        }
        XCTAssertEqual(director.pressesDuringSetPiece, 5)
        XCTAssertTrue(director.isPlaying, "ordinary presses do not end the set-piece")
    }

    func testCallerCountsEveryPressExactlyOnceRegardlessOfSetPieces() {
        // The director sits beside the real counting path; drive both and compare.
        let service = PressService(store: InMemoryStatsStore())
        var director = SetPieceDirector()
        var started: [String] = []
        for _ in 1...60 {
            let result = service.registerPress()
            if case .start(let piece) = director.registerPress(milestone: result.milestone) {
                started.append(piece.id)
            }
        }
        XCTAssertEqual(service.stats.currentRun, 60)
        XCTAssertEqual(service.stats.totalPresses, 60)
        XCTAssertEqual(started, ["flinch", "getaway", "lockdown"])
        XCTAssertEqual(director.active?.id, "lockdown", "a newer milestone replaces a set-piece still playing")
        XCTAssertEqual(director.pressesDuringSetPiece, 50, "every press after the first set-piece started was still accepted")
    }

    func testNeverPlaysTwiceForTheSameMilestoneInARun() {
        var director = SetPieceDirector()
        XCTAssertEqual(director.registerPress(milestone: 10), .start(SetPieceCatalog.flinch))
        director.finish(id: "flinch")
        XCTAssertEqual(director.registerPress(milestone: 10), .none)
        XCTAssertFalse(director.isPlaying)
        XCTAssertEqual(director.playedMilestones, [10])
    }

    func testFinishClearsOnlyTheMatchingSetPiece() {
        var director = SetPieceDirector()
        _ = director.registerPress(milestone: 10)
        director.finish(id: "something-else")
        XCTAssertTrue(director.isPlaying)
        director.finish(id: "flinch")
        XCTAssertFalse(director.isPlaying)
        director.finish(id: "flinch")   // idempotent
        XCTAssertFalse(director.isPlaying)
    }

    func testStaleFinishDoesNotCancelReplacement() {
        var director = SetPieceDirector()
        _ = director.registerPress(milestone: 10)
        _ = director.registerPress(milestone: 25)
        director.finish(id: "flinch")   // the interrupted one reports late
        XCTAssertEqual(director.active?.id, "getaway")
    }

    func testNewRunAllowsEveryMilestoneAgain() {
        var director = SetPieceDirector()
        _ = director.registerPress(milestone: 10)
        _ = director.registerPress(milestone: nil)
        director.startNewRun()
        XCTAssertEqual(director, SetPieceDirector())
        XCTAssertEqual(director.registerPress(milestone: 10), .start(SetPieceCatalog.flinch))
    }

    func testEveryMilestonePlaysOnceAcrossAFullRun() {
        var director = SetPieceDirector()
        var ids: [String] = []
        var previous = 0
        for run in 1...1000 {
            let milestone = Milestone.crossed(from: previous, to: run)
            previous = run
            if case .start(let piece) = director.registerPress(milestone: milestone) {
                ids.append(piece.id)
                director.finish(id: piece.id)
            }
        }
        XCTAssertEqual(ids, SetPieceCatalog.all.map(\.id))
        XCTAssertEqual(director.playedMilestones, Set(Milestone.thresholds))
    }
}

final class HomeViewModelSetPieceTests: XCTestCase {
    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    @MainActor private func makeModel() -> HomeViewModel {
        HomeViewModel(service: PressService(store: InMemoryStatsStore()), reactions: ReactionEngine(random: scripted([50, 0, 1])))
    }

    func testSetPieceStartsOnMilestoneAndTapsKeepCounting() {
        onMain {
            let model = makeModel()
            for _ in 0..<9 { model.press() }
            XCTAssertNil(model.activeSetPiece)
            model.press()   // 10
            XCTAssertEqual(model.activeSetPiece?.id, "flinch")
            XCTAssertEqual(model.reactionText, ReactionCatalog.milestones[10]?.text, "the milestone reaction line is untouched")
            for _ in 0..<5 { model.press() }
            XCTAssertEqual(model.stats.currentRun, 15, "presses during a set-piece count exactly once each")
            XCTAssertEqual(model.pressCount, 15)
            XCTAssertEqual(model.activeSetPiece?.id, "flinch", "ordinary presses do not end the set-piece")
        }
    }

    func testFinishClearsActiveSetPieceAndItNeverReplays() {
        onMain {
            let model = makeModel()
            for _ in 0..<10 { model.press() }
            XCTAssertEqual(model.activeSetPiece?.id, "flinch")
            model.finishSetPiece(id: "other")
            XCTAssertEqual(model.activeSetPiece?.id, "flinch", "stale ids are ignored")
            model.finishSetPiece(id: "flinch")
            XCTAssertNil(model.activeSetPiece)
            for _ in 0..<15 { model.press() }  // 25
            XCTAssertEqual(model.activeSetPiece?.id, "getaway")
            XCTAssertEqual(model.stats.currentRun, 25)
        }
    }

    func testNewerMilestoneReplacesRunningSetPiece() {
        onMain {
            let model = makeModel()
            for _ in 0..<25 { model.press() }
            XCTAssertEqual(model.activeSetPiece?.id, "getaway")
            model.finishSetPiece(id: "flinch")   // late report from the interrupted one
            XCTAssertEqual(model.activeSetPiece?.id, "getaway")
            XCTAssertEqual(model.stats, PressStats(currentRun: 25, personalBest: 25, totalPresses: 25))
        }
    }
}
