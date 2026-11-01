import Foundation

/// A tiny deterministic synthesizer. Every `SoundEffect` is described as a handful of
/// layered `Voice`s (oscillator + pitch sweep + ADSR envelope) and rendered to a mono
/// Float buffer. Pure math, no audio APIs, so it is unit-testable on any platform.
enum SoundSynth {
    static let defaultSampleRate: Double = 44_100
    /// Peak level after normalization (headroom for the system mixer).
    static let targetPeak: Float = 0.85
    /// Fade applied to the very end of every buffer, followed by pure silence.
    static let fadeOutSeconds: Double = 0.004
    static let silentTailSeconds: Double = 0.010

    enum Waveform: Sendable {
        case sine
        case triangle
        /// Soft square: the first four odd harmonics, so it buzzes without harsh aliasing.
        case softSquare
        /// Deterministic white noise (seeded).
        case noise(seed: UInt32)
    }

    struct Envelope: Sendable {
        var attack: Double
        var decay: Double
        var sustain: Double
        var release: Double

        /// Gain at `t` seconds into a note of `duration` seconds. Always within 0...1.
        func gain(at t: Double, duration: Double) -> Double {
            guard t >= 0, t < duration else { return 0 }
            let level: Double
            if t < attack {
                level = attack > 0 ? t / attack : 1
            } else if t < attack + decay {
                let p = decay > 0 ? (t - attack) / decay : 1
                level = 1 + (sustain - 1) * p
            } else {
                level = sustain
            }
            let releaseStart = duration - release
            if release > 0, t > releaseStart {
                let p = (t - releaseStart) / release
                return Swift.max(0, Swift.min(1, level * (1 - p)))
            }
            return Swift.max(0, Swift.min(1, level))
        }

        static let pluck = Envelope(attack: 0.002, decay: 0.05, sustain: 0.25, release: 0.03)
        static let note = Envelope(attack: 0.005, decay: 0.06, sustain: 0.6, release: 0.05)
        static let bell = Envelope(attack: 0.002, decay: 0.25, sustain: 0.3, release: 0.35)
        static let hit = Envelope(attack: 0.001, decay: 0.02, sustain: 0.15, release: 0.02)
    }

    struct Voice: Sendable {
        var start: Double
        var duration: Double
        var wave: Waveform
        var fromHz: Double
        var toHz: Double
        var gain: Double
        var envelope: Envelope
        var vibratoHz: Double = 0
        var vibratoDepthHz: Double = 0
        /// Optional one-pole low-pass cutoff (Hz), mainly to darken noise.
        var lowPassHz: Double? = nil

        var end: Double { start + duration }

        /// Instantaneous frequency: exponential sweep plus optional vibrato.
        func frequency(at t: Double) -> Double {
            let p = duration > 0 ? Swift.min(Swift.max(t / duration, 0), 1) : 0
            let base: Double
            if fromHz > 0, toHz > 0 {
                base = fromHz * pow(toHz / fromHz, p)
            } else {
                base = fromHz + (toHz - fromHz) * p
            }
            guard vibratoHz > 0 else { return base }
            return base + vibratoDepthHz * sin(2 * Double.pi * vibratoHz * t)
        }
    }

    // MARK: - Public API

    /// Base pitch of the press tick for a stage: two semitones higher per stage.
    static func pressFrequency(stage: Int) -> Double {
        let s = Swift.min(Swift.max(stage, 0), SoundEffect.maxPressStage)
        return 330 * pow(2, Double(s) * 2 / 12)
    }

    /// Exact number of samples `render` returns for an effect.
    static func sampleCount(for effect: SoundEffect, sampleRate: Double = defaultSampleRate) -> Int {
        let body = voices(for: effect).map(\.end).max() ?? 0
        return Int((body * sampleRate).rounded(.up)) + Int((silentTailSeconds * sampleRate).rounded(.up))
    }

    /// Renders an effect to mono Float samples in -targetPeak...targetPeak, ending in silence.
    /// Deterministic: the same effect and sample rate always produce identical output.
    static func render(_ effect: SoundEffect, sampleRate: Double = defaultSampleRate) -> [Float] {
        let sampleRate = sampleRate.isFinite && sampleRate >= 8_000 ? sampleRate : defaultSampleRate
        let count = sampleCount(for: effect, sampleRate: sampleRate)
        var mix = [Double](repeating: 0, count: count)
        for voice in voices(for: effect) {
            add(voice, into: &mix, sampleRate: sampleRate)
        }

        // Normalize to the target peak (only ever scales down or up to the target, never clips).
        var peak = 0.0
        for v in mix where v.isFinite { peak = Swift.max(peak, abs(v)) }
        let scale = peak > 0 ? Double(targetPeak) / peak : 0

        // Fade out the last few milliseconds of the body, then pure silence.
        let tail = Int((silentTailSeconds * sampleRate).rounded(.up))
        let bodyEnd = count - tail
        let fade = Swift.max(1, Int(fadeOutSeconds * sampleRate))
        var out = [Float](repeating: 0, count: count)
        for i in 0..<bodyEnd {
            var v = mix[i].isFinite ? mix[i] * scale : 0
            let fromEnd = bodyEnd - i
            if fromEnd <= fade { v *= Double(fromEnd - 1) / Double(fade) }
            out[i] = Float(Swift.max(-Double(targetPeak), Swift.min(Double(targetPeak), v)))
        }
        return out
    }

    // MARK: - Sound design

    /// The recipe for each effect. Times in seconds, frequencies in Hz.
    static func voices(for effect: SoundEffect) -> [Voice] {
        switch effect.normalized {
        case .press(let stage):
            let f = pressFrequency(stage: stage)
            return [
                // A short downward "plunk": the body of the tick.
                Voice(start: 0, duration: 0.075, wave: .sine, fromHz: f * 1.5, toHz: f, gain: 1.0, envelope: .pluck),
                // A quiet octave above for brightness.
                Voice(start: 0, duration: 0.05, wave: .triangle, fromHz: f * 2, toHz: f * 2, gain: 0.25, envelope: .hit),
                // A tiny click at the onset (the mechanical part).
                Voice(start: 0, duration: 0.004, wave: .noise(seed: 11), fromHz: 0, toHz: 0, gain: 0.25,
                      envelope: Envelope(attack: 0.0005, decay: 0.002, sustain: 0.2, release: 0.001), lowPassHz: 4_000),
            ]

        case .milestone:
            // Rising major arpeggio with a held top note.
            let notes: [Double] = [523.25, 659.25, 783.99, 1046.5]
            var result: [Voice] = []
            for (i, hz) in notes.enumerated() {
                let isLast = i == notes.count - 1
                result.append(Voice(start: Double(i) * 0.085, duration: isLast ? 0.38 : 0.11, wave: .triangle,
                                    fromHz: hz, toHz: hz, gain: 0.8, envelope: isLast ? .bell : .note))
                result.append(Voice(start: Double(i) * 0.085, duration: isLast ? 0.3 : 0.09, wave: .sine,
                                    fromHz: hz * 2, toHz: hz * 2, gain: 0.2, envelope: .note))
            }
            return result

        case .achievement:
            // Two bell strikes; an inharmonic partial makes them read as metal.
            return bell(at: 0, hz: 1318.5) + bell(at: 0.12, hz: 1975.5)

        case .unlock:
            return [
                Voice(start: 0, duration: 0.14, wave: .triangle, fromHz: 420, toHz: 1260, gain: 0.7, envelope: .note),
                Voice(start: 0.13, duration: 0.24, wave: .sine, fromHz: 1680, toHz: 1680, gain: 0.5, envelope: .bell),
                Voice(start: 0.17, duration: 0.2, wave: .sine, fromHz: 2520, toHz: 2520, gain: 0.25, envelope: .bell),
            ]

        case .balloonSqueak:
            return [
                Voice(start: 0, duration: 0.32, wave: .triangle, fromHz: 680, toHz: 1050, gain: 0.8,
                      envelope: Envelope(attack: 0.02, decay: 0.08, sustain: 0.7, release: 0.06),
                      vibratoHz: 19, vibratoDepthHz: 45),
            ]

        case .balloonPop:
            return [
                Voice(start: 0, duration: 0.09, wave: .noise(seed: 23), fromHz: 0, toHz: 0, gain: 1.0,
                      envelope: Envelope(attack: 0.0005, decay: 0.03, sustain: 0.1, release: 0.04)),
                Voice(start: 0, duration: 0.14, wave: .sine, fromHz: 140, toHz: 55, gain: 0.7, envelope: .pluck),
            ]

        case .eggCrack:
            return crackles(at: 0, seed: 31)

        case .eggHatch:
            return crackles(at: 0, seed: 37) + [
                Voice(start: 0.17, duration: 0.07, wave: .sine, fromHz: 1400, toHz: 1900, gain: 0.55, envelope: .note),
                Voice(start: 0.27, duration: 0.09, wave: .sine, fromHz: 1500, toHz: 2200, gain: 0.55, envelope: .note),
            ]

        case .boom:
            return [
                Voice(start: 0, duration: 0.9, wave: .noise(seed: 41), fromHz: 0, toHz: 0, gain: 1.0,
                      envelope: Envelope(attack: 0.003, decay: 0.25, sustain: 0.25, release: 0.5), lowPassHz: 380),
                Voice(start: 0, duration: 0.7, wave: .sine, fromHz: 95, toHz: 32, gain: 0.9,
                      envelope: Envelope(attack: 0.003, decay: 0.2, sustain: 0.4, release: 0.4)),
            ]

        case .error:
            return [
                Voice(start: 0, duration: 0.11, wave: .softSquare, fromHz: 155, toHz: 150, gain: 0.6, envelope: .note),
                Voice(start: 0.15, duration: 0.14, wave: .softSquare, fromHz: 150, toHz: 140, gain: 0.6, envelope: .note),
            ]
        }
    }

    private static func bell(at start: Double, hz: Double) -> [Voice] {
        [
            Voice(start: start, duration: 0.6, wave: .sine, fromHz: hz, toHz: hz, gain: 0.7, envelope: .bell),
            Voice(start: start, duration: 0.35, wave: .sine, fromHz: hz * 2.76, toHz: hz * 2.76, gain: 0.18, envelope: .bell),
        ]
    }

    /// Three dry, uneven ticks of filtered noise.
    private static func crackles(at start: Double, seed: UInt32) -> [Voice] {
        let ticks: [(Double, Double)] = [(0, 1.0), (0.045, 0.7), (0.105, 0.85)]
        return ticks.enumerated().map { index, tick in
            Voice(start: start + tick.0, duration: 0.018, wave: .noise(seed: seed &+ UInt32(index)), fromHz: 0, toHz: 0,
                  gain: tick.1, envelope: Envelope(attack: 0.0005, decay: 0.006, sustain: 0.2, release: 0.006),
                  lowPassHz: 2_600)
        }
    }

    // MARK: - Rendering

    private static func add(_ voice: Voice, into mix: inout [Double], sampleRate: Double) {
        let first = Swift.max(0, Int((voice.start * sampleRate).rounded()))
        let length = Int((voice.duration * sampleRate).rounded())
        guard length > 0, first < mix.count else { return }
        let last = Swift.min(mix.count, first + length)

        var phase = 0.0 // in cycles, 0..<1
        var rng = voice.noiseSeed
        var lowPassState = 0.0
        let lowPassAlpha: Double? = voice.lowPassHz.map { hz in
            let rc = 1 / (2 * Double.pi * Swift.max(hz, 1))
            let dt = 1 / sampleRate
            return dt / (rc + dt)
        }

        for i in first..<last {
            let t = Double(i - first) / sampleRate
            var sample: Double
            switch voice.wave {
            case .sine:
                sample = sin(2 * Double.pi * phase)
            case .triangle:
                sample = 1 - 4 * abs(phase - 0.5)
            case .softSquare:
                let x = 2 * Double.pi * phase
                sample = (sin(x) + sin(3 * x) / 3 + sin(5 * x) / 5 + sin(7 * x) / 7) * 0.9
            case .noise:
                // xorshift32: fast and fully deterministic.
                rng ^= rng << 13
                rng ^= rng >> 17
                rng ^= rng << 5
                sample = Double(rng) / Double(UInt32.max) * 2 - 1
            }
            if let alpha = lowPassAlpha {
                lowPassState += alpha * (sample - lowPassState)
                // Compensate the level lost by filtering noise.
                sample = lowPassState * 2.5
            }
            mix[i] += sample * voice.gain * voice.envelope.gain(at: t, duration: voice.duration)

            phase += Swift.max(0, voice.frequency(at: t)) / sampleRate
            phase -= phase.rounded(.down)
        }
    }
}

private extension SoundSynth.Voice {
    var noiseSeed: UInt32 {
        if case .noise(let seed) = wave { return seed == 0 ? 0x9E37_79B9 : seed }
        return 1
    }
}
