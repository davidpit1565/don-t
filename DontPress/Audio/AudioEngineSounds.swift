import AVFoundation

/// Plays `SoundSynth` output through one `AVAudioEngine`.
///
/// - Every effect is rendered once (off the main thread) into a preallocated
///   `AVAudioPCMBuffer`; a tap only schedules an existing buffer, it allocates no audio memory.
/// - A small pool of player nodes acts as voices, so overlapping taps mix instead of cutting
///   each other off; when all voices are busy the oldest one is reused.
/// - The session category is `.ambient`: it respects the Ring/Silent switch and mixes with
///   other apps' audio.
/// - Any failure (no session, engine won't start, interruption) just means silence. Nothing
///   here throws, crashes, or touches counting.
@MainActor
final class AudioEngineSounds: SoundEffects {
    private static let voiceCount = 6

    private var engine = AVAudioEngine()
    private let format: AVAudioFormat?
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var nextVoice = 0
    private var isRendering = false
    private var isGraphReady = false
    private var observers: [NSObjectProtocol] = []

    init() {
        format = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.defaultSampleRate, channels: 1)
    }

    // MARK: SoundEffects

    func prepare() {
        guard !isRendering, buffers.isEmpty, format != nil else { return }
        isRendering = true
        let sampleRate = SoundSynth.defaultSampleRate
        Task.detached(priority: .utility) { [weak self] in
            let rendered: [(SoundEffect, [Float])] = SoundEffect.allCases.map { ($0, SoundSynth.render($0, sampleRate: sampleRate)) }
            await self?.install(rendered)
        }
    }

    func play(_ effect: SoundEffect) {
        guard isGraphReady, !players.isEmpty, let buffer = buffers[effect.normalized] else {
            // Not ready yet (first moments after launch, or audio unavailable): stay silent.
            if buffers.isEmpty { prepare() }
            return
        }
        guard ensureRunning() else { return }

        let player = players[nextVoice]
        nextVoice = (nextVoice + 1) % players.count
        // `.interrupts` makes voice stealing clean when every voice is busy.
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    // MARK: Setup

    private func install(_ rendered: [(SoundEffect, [Float])]) {
        isRendering = false
        guard let format else { return }
        var made: [SoundEffect: AVAudioPCMBuffer] = [:]
        for (effect, samples) in rendered {
            guard !samples.isEmpty,
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
                  let channel = buffer.floatChannelData?[0] else { continue }
            buffer.frameLength = AVAudioFrameCount(samples.count)
            samples.withUnsafeBufferPointer { source in
                guard let base = source.baseAddress else { return }
                channel.update(from: base, count: samples.count)
            }
            made[effect] = buffer
        }
        buffers = made
        guard !made.isEmpty else { return }
        buildGraph(format: format)
    }

    private func buildGraph(format: AVAudioFormat) {
        guard !isGraphReady else { return }
        configureSession()
        for _ in 0..<Self.voiceCount {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        engine.mainMixerNode.outputVolume = 0.8
        engine.prepare()
        isGraphReady = true
        observeSystemEvents()
        _ = ensureRunning()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            // Silence is an acceptable outcome; the engine may still start with defaults.
        }
    }

    /// Starts the engine if it stopped (first use, interruption, route/config change).
    private func ensureRunning() -> Bool {
        if engine.isRunning { return true }
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    private func observeSystemEvents() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        // After a configuration change (e.g. output route) the engine stops; restart lazily on
        // the next play. Player nodes keep their connections.
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleEngineReset() }
        })
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let rawType = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            MainActor.assumeIsolated {
                if rawType == AVAudioSession.InterruptionType.ended.rawValue {
                    try? AVAudioSession.sharedInstance().setActive(true)
                }
                self?.handleEngineReset()
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleMediaServicesReset() }
        })
    }

    private func handleEngineReset() {
        // Stop the voices so stale schedules don't fire later; next play restarts as needed.
        for player in players { player.stop() }
    }

    private func handleMediaServicesReset() {
        // The whole audio graph is invalid; rebuild it (with a fresh engine) from the cached buffers.
        for player in players { player.stop() }
        engine.stop()
        players.removeAll()
        nextVoice = 0
        isGraphReady = false
        engine = AVAudioEngine()
        if let format, !buffers.isEmpty { buildGraph(format: format) }
    }
}
