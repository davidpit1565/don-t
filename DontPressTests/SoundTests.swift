import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class SpySounds: SoundEffects {
    var prepareCount = 0
    var played: [SoundEffect] = []
    func prepare() { prepareCount += 1 }
    func play(_ effect: SoundEffect) { played.append(effect) }
}

final class SoundSynthTests: XCTestCase {
    func testEveryEffectRendersValidAudio() {
        for effect in SoundEffect.allCases {
            let samples = SoundSynth.render(effect)
            XCTAssertEqual(samples.count, SoundSynth.sampleCount(for: effect), "\(effect)")
            XCTAssertGreaterThan(samples.count, 441, "\(effect) too short")
            XCTAssertLessThan(samples.count, 44_100 * 2, "\(effect) too long")
            XCTAssertFalse(samples.contains { !$0.isFinite }, "\(effect) has NaN/inf")
            let peak = samples.map { abs($0) }.max() ?? 0
            XCTAssertLessThanOrEqual(peak, 1, "\(effect)")
            XCTAssertLessThanOrEqual(peak, SoundSynth.targetPeak + 1e-6, "\(effect)")
            XCTAssertGreaterThan(peak, 0.5, "\(effect) is (nearly) silent")
        }
    }

    func testEveryEffectEndsInSilence() {
        for effect in SoundEffect.allCases {
            let samples = SoundSynth.render(effect)
            let tail = Int(SoundSynth.silentTailSeconds * SoundSynth.defaultSampleRate)
            XCTAssertTrue(samples.suffix(tail).allSatisfy { $0 == 0 }, "\(effect) does not end in silence")
            XCTAssertTrue(samples.prefix(10).contains { $0 != 0 }, "\(effect) does not start promptly")
        }
    }

    func testRenderingIsDeterministic() {
        for effect in SoundEffect.allCases {
            XCTAssertEqual(SoundSynth.render(effect), SoundSynth.render(effect), "\(effect)")
        }
    }

    func testPressTickIsShort() {
        // A tick that rings too long would smear rapid tapping.
        XCTAssertLessThan(SoundSynth.render(.press(stage: 0)).count, Int(0.15 * SoundSynth.defaultSampleRate))
    }

    func testPitchRisesWithStage() {
        var previousFrequency = 0.0
        var previousCrossings = 0
        for stage in 0...SoundEffect.maxPressStage {
            let frequency = SoundSynth.pressFrequency(stage: stage)
            XCTAssertGreaterThan(frequency, previousFrequency)
            previousFrequency = frequency

            let crossings = zeroCrossings(SoundSynth.render(.press(stage: stage)), from: 0.01, to: 0.06)
            XCTAssertGreaterThan(crossings, previousCrossings, "stage \(stage)")
            previousCrossings = crossings
        }
    }

    func testPressStageMapping() {
        XCTAssertEqual(SoundEffect.pressStage(forRun: -5), 0)
        XCTAssertEqual(SoundEffect.pressStage(forRun: 0), 0)
        XCTAssertEqual(SoundEffect.pressStage(forRun: 9), 0)
        XCTAssertEqual(SoundEffect.pressStage(forRun: 10), 1)
        XCTAssertEqual(SoundEffect.pressStage(forRun: 35), 3)
        XCTAssertEqual(SoundEffect.pressStage(forRun: Int.max), SoundEffect.maxPressStage)
        XCTAssertEqual(SoundEffect.press(forRun: 25), .press(stage: 2))
    }

    func testOutOfRangeStagesAreClampedAndRenderable() {
        XCTAssertEqual(SoundEffect.press(stage: 999).normalized, .press(stage: SoundEffect.maxPressStage))
        XCTAssertEqual(SoundEffect.press(stage: -3).normalized, .press(stage: 0))
        XCTAssertEqual(SoundSynth.render(.press(stage: 999)), SoundSynth.render(.press(stage: SoundEffect.maxPressStage)))
        // Every case in allCases is already normalized and distinct.
        XCTAssertEqual(Set(SoundEffect.allCases).count, SoundEffect.allCases.count)
        XCTAssertTrue(SoundEffect.allCases.allSatisfy { $0.normalized == $0 })
    }

    func testOtherSampleRatesAndBadInput() {
        let at48k = SoundSynth.render(.boom, sampleRate: 48_000)
        XCTAssertEqual(at48k.count, SoundSynth.sampleCount(for: .boom, sampleRate: 48_000))
        XCTAssertFalse(at48k.contains { !$0.isFinite })
        // Nonsense sample rates fall back to the default rather than producing garbage.
        XCTAssertEqual(SoundSynth.render(.error, sampleRate: .nan), SoundSynth.render(.error))
        XCTAssertEqual(SoundSynth.render(.error, sampleRate: 0), SoundSynth.render(.error))
    }

    func testEnvelopeStaysInRange() {
        let envelopes: [SoundSynth.Envelope] = [.pluck, .note, .bell, .hit, .init(attack: 0, decay: 0, sustain: 1, release: 0)]
        for envelope in envelopes {
            for step in -2...102 {
                let gain = envelope.gain(at: Double(step) / 100 * 0.5, duration: 0.5)
                XCTAssertGreaterThanOrEqual(gain, 0)
                XCTAssertLessThanOrEqual(gain, 1)
            }
            XCTAssertEqual(envelope.gain(at: 0.5, duration: 0.5), 0)
        }
    }

    private func zeroCrossings(_ samples: [Float], from start: Double, to end: Double) -> Int {
        let a = Int(start * SoundSynth.defaultSampleRate), b = Int(end * SoundSynth.defaultSampleRate)
        var count = 0
        for i in (a + 1)..<b where (samples[i - 1] < 0) != (samples[i] < 0) { count += 1 }
        return count
    }
}

final class SoundSettingTests: XCTestCase {
    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    func testSoundEnabledDefaultsOnAndPersists() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertTrue(store.loadSoundEnabled())
        store.saveSoundEnabled(false)
        XCTAssertFalse(UserDefaultsStatsStore(defaults: defaults).loadSoundEnabled())
        store.saveSoundEnabled(true)
        XCTAssertTrue(UserDefaultsStatsStore(defaults: defaults).loadSoundEnabled())
    }

    func testWrongTypeReadsAsDefault() {
        let defaults = makeIsolatedDefaults(self)
        defaults.set("nope", forKey: UserDefaultsStatsStore.soundKey)
        XCTAssertTrue(UserDefaultsStatsStore(defaults: defaults).loadSoundEnabled())
    }

    func testInMemoryStore() {
        let store = InMemoryStatsStore()
        XCTAssertTrue(store.loadSoundEnabled())
        store.saveSoundEnabled(false)
        XCTAssertFalse(store.loadSoundEnabled())
    }

    func testViewModelPlaysOneSoundPerPressWithEscalatingStage() {
        onMain {
            let spy = SpySounds()
            let model = HomeViewModel(service: PressService(store: InMemoryStatsStore()),
                                      reactions: ReactionEngine(random: scripted([50, 0, 1])), sounds: spy)
            XCTAssertEqual(spy.prepareCount, 1)
            for _ in 0..<30 { model.press() }
            XCTAssertEqual(model.stats.currentRun, 30)
            XCTAssertEqual(spy.played.count, 30)
            // The very first press unlocks the first achievement.
            XCTAssertEqual(spy.played[0], .achievement)
            XCTAssertEqual(spy.played[1], .press(stage: 0))
            // Press 10 crosses the first milestone.
            XCTAssertEqual(spy.played[9], .milestone)
            XCTAssertEqual(spy.played[10], .press(stage: 1))
            XCTAssertEqual(spy.played[22], .press(stage: 2))
        }
    }

    func testMuteSilencesButNeverAffectsCounting() {
        onMain {
            let store = InMemoryStatsStore()
            let spy = SpySounds()
            let model = HomeViewModel(service: PressService(store: store), sounds: spy)
            XCTAssertTrue(model.isSoundEnabled)
            model.setSoundEnabled(false)
            for _ in 0..<5 { model.press() }
            XCTAssertTrue(spy.played.isEmpty)
            XCTAssertEqual(model.stats.currentRun, 5)
            XCTAssertFalse(store.loadSoundEnabled())

            // The setting survives a relaunch, and a muted launch does not warm up audio.
            let spy2 = SpySounds()
            let relaunched = HomeViewModel(service: PressService(store: store), sounds: spy2)
            XCTAssertFalse(relaunched.isSoundEnabled)
            XCTAssertEqual(spy2.prepareCount, 0)
            relaunched.setSoundEnabled(true)
            XCTAssertEqual(spy2.prepareCount, 1)
            relaunched.press()
            XCTAssertEqual(spy2.played, [.press(stage: 0)])
        }
    }

    func testDefaultViewModelHasNoSoundsAndStillCounts() {
        onMain {
            let model = HomeViewModel(service: PressService(store: InMemoryStatsStore()))
            model.press()
            model.playSound(.boom)
            XCTAssertEqual(model.stats.totalPresses, 1)
        }
    }
}
