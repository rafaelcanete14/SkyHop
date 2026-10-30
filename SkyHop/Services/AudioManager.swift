import AVFoundation
import Foundation

/// Identifiers for original procedurally synthesized game sound effects.
enum SoundEffect: CaseIterable {
    case flap
    case score
    case milestone
    case collision
    case button
    case unlock
}

/// Self-contained procedural audio engine synthesizing original sound effects
/// and a seamless looping background soundtrack in memory (zero external audio files required).
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var sfxPools: [SoundEffect: [AVAudioPlayer]] = [:]
    private var sfxIndices: [SoundEffect: Int] = [:]
    private var musicPlayer: AVAudioPlayer?

    private var soundEffectsEnabled: Bool = true
    private var soundEffectsVolume: Float = 0.85
    private var musicEnabled: Bool = true
    private var musicVolume: Float = 0.50
    private var isPausedForInterruption: Bool = false
    private var wantsBackgroundMusic: Bool = false
    private var isPrepared: Bool = false

    private init() {
        configureAudioSession()
        observeAudioInterruptions()
        prepareSynthesizedAudioAsync()
    }

    func apply(settings: GameSettings) {
        soundEffectsEnabled = settings.soundEffectsEnabled
        soundEffectsVolume = Float(settings.soundEffectsVolume)
        musicEnabled = settings.musicEnabled
        musicVolume = Float(settings.musicVolume)

        if let player = musicPlayer {
            player.volume = musicVolume * 0.45
            if musicEnabled && wantsBackgroundMusic && !isPausedForInterruption {
                if !player.isPlaying {
                    player.play()
                }
            } else {
                player.pause()
            }
        }
    }

    func startBackgroundMusic() {
        wantsBackgroundMusic = true
        guard musicEnabled, !isPausedForInterruption, let player = musicPlayer else { return }
        player.volume = musicVolume * 0.45
        if !player.isPlaying {
            player.play()
        }
    }

    func pauseBackgroundMusic() {
        musicPlayer?.pause()
    }

    func resumeBackgroundMusicIfNeeded() {
        guard wantsBackgroundMusic, musicEnabled, !isPausedForInterruption else { return }
        if let player = musicPlayer, !player.isPlaying {
            player.volume = musicVolume * 0.45
            player.play()
        }
    }

    func play(_ effect: SoundEffect) {
        guard soundEffectsEnabled, soundEffectsVolume > 0.01 else { return }
        guard let pool = sfxPools[effect], !pool.isEmpty else { return }

        let index = (sfxIndices[effect] ?? 0) % pool.count
        sfxIndices[effect] = index + 1

        let player = pool[index]
        player.volume = soundEffectsVolume
        if player.isPlaying {
            player.currentTime = 0
        } else {
            player.currentTime = 0
            player.play()
        }
    }

    // MARK: - Session & Interruptions

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Audio session failures on simulator or restricted devices fail gracefully.
        }
    }

    private func observeAudioInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
                return
            }

            let rawOptions = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let shouldResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)

            Task { @MainActor [weak self] in
                guard let self else { return }
                switch type {
                case .began:
                    self.isPausedForInterruption = true
                    self.musicPlayer?.pause()
                case .ended:
                    self.isPausedForInterruption = false
                    try? AVAudioSession.sharedInstance().setActive(true)
                    if shouldResume {
                        self.resumeBackgroundMusicIfNeeded()
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - Asynchronous Procedural Synthesis

    private func prepareSynthesizedAudioAsync() {
        guard !isPrepared else { return }
        isPrepared = true

        Task.detached(priority: .userInitiated) { [weak self] in
            let flapWAV = AudioSynthesizer.makeFlapWAV()
            let scoreWAV = AudioSynthesizer.makeScoreWAV()
            let milestoneWAV = AudioSynthesizer.makeMilestoneWAV()
            let collisionWAV = AudioSynthesizer.makeCollisionWAV()
            let buttonWAV = AudioSynthesizer.makeButtonWAV()
            let unlockWAV = AudioSynthesizer.makeUnlockWAV()
            let musicWAV = AudioSynthesizer.makeSkyIslandLoopWAV()

            await MainActor.run {
                guard let self else { return }
                self.registerPool(for: .flap, data: flapWAV, count: 4)
                self.registerPool(for: .score, data: scoreWAV, count: 3)
                self.registerPool(for: .milestone, data: milestoneWAV, count: 2)
                self.registerPool(for: .collision, data: collisionWAV, count: 2)
                self.registerPool(for: .button, data: buttonWAV, count: 2)
                self.registerPool(for: .unlock, data: unlockWAV, count: 1)

                if let music = try? AVAudioPlayer(data: musicWAV) {
                    music.numberOfLoops = -1
                    music.volume = self.musicVolume * 0.45
                    music.prepareToPlay()
                    self.musicPlayer = music
                    if self.wantsBackgroundMusic && self.musicEnabled && !self.isPausedForInterruption {
                        music.play()
                    }
                }
            }
        }
    }

    private func registerPool(for effect: SoundEffect, data: Data, count: Int) {
        var players: [AVAudioPlayer] = []
        players.reserveCapacity(count)
        for _ in 0..<count {
            if let player = try? AVAudioPlayer(data: data) {
                player.prepareToPlay()
                players.append(player)
            }
        }
        sfxPools[effect] = players
        sfxIndices[effect] = 0
    }
}

// MARK: - Procedural PCM WAV Synthesizer

private enum AudioSynthesizer {
    static let sampleRate: Double = 44_100.0

    /// Soft upward marimba/breeze chirp for each wing hop.
    static func makeFlapWAV() -> Data {
        let duration = 0.13
        let count = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: count)
        var phase = 0.0

        for i in 0..<count {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let freq = 420.0 + 360.0 * pow(progress, 0.75)
            phase += (2.0 * .pi * freq) / sampleRate

            let attack = min(1.0, t / 0.010)
            let decay = pow(max(0.0, 1.0 - progress), 1.65)
            let env = attack * decay

            let fundamental = sin(phase)
            let harmonic = 0.28 * sin(phase * 2.0)
            let airyBreath = 0.08 * sin(Double(i) * 1.73) * (1.0 - progress)

            let value = (fundamental + harmonic + airyBreath) * env * 0.48
            samples[i] = clampToInt16(value)
        }
        return encodeWAV(samples: samples)
    }

    /// Bright two-note crystal bell chime (`E5` -> `B5`) on passing an obstacle gate.
    static func makeScoreWAV() -> Data {
        let notes: [(freq: Double, start: Double, length: Double, amp: Double)] = [
            (659.25, 0.00, 0.12, 0.42),
            (987.77, 0.075, 0.24, 0.46)
        ]
        return renderPolyphonicNotes(notes: notes, totalDuration: 0.33)
    }

    /// Sparkly 4-note major arpeggio (`C5 - E5 - G5 - C6`) on 10-point streaks.
    static func makeMilestoneWAV() -> Data {
        let notes: [(freq: Double, start: Double, length: Double, amp: Double)] = [
            (523.25, 0.00, 0.16, 0.36),
            (659.25, 0.07, 0.18, 0.38),
            (783.99, 0.14, 0.20, 0.40),
            (1046.50, 0.21, 0.34, 0.45)
        ]
        return renderPolyphonicNotes(notes: notes, totalDuration: 0.56)
    }

    /// Joyful major-add9 chord flourish when unlocking a new creature skin.
    static func makeUnlockWAV() -> Data {
        let notes: [(freq: Double, start: Double, length: Double, amp: Double)] = [
            (523.25, 0.00, 0.45, 0.28),
            (659.25, 0.05, 0.45, 0.28),
            (783.99, 0.10, 0.45, 0.30),
            (1174.66, 0.16, 0.50, 0.34)
        ]
        return renderPolyphonicNotes(notes: notes, totalDuration: 0.68)
    }

    /// Crisp tactile UI pop for buttons and toggles.
    static func makeButtonWAV() -> Data {
        let duration = 0.055
        let count = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: count)
        var phase = 0.0

        for i in 0..<count {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let freq = 680.0 + 180.0 * (1.0 - progress)
            phase += (2.0 * .pi * freq) / sampleRate
            let env = min(1.0, t / 0.004) * pow(1.0 - progress, 2.2)
            samples[i] = clampToInt16(sin(phase) * env * 0.34)
        }
        return encodeWAV(samples: samples)
    }

    /// Percussive cartoon thump + gentle descending slide on obstacle collision.
    static func makeCollisionWAV() -> Data {
        let duration = 0.32
        let count = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: count)
        var phase = 0.0
        var lfsr: UInt32 = 0xACE1

        for i in 0..<count {
            let t = Double(i) / sampleRate
            let progress = t / duration

            // Descending body tone
            let freq = max(75.0, 290.0 * pow(1.0 - progress, 1.35))
            phase += (2.0 * .pi * freq) / sampleRate

            // Deterministic pseudo-noise burst for crisp initial impact
            let bit = lfsr & 1
            lfsr = (lfsr >> 1) ^ (bit != 0 ? 0xB400 : 0)
            let noise = (Double(lfsr & 0xFF) / 127.5) - 1.0
            let impactEnv = exp(-t * 42.0)

            let bodyEnv = min(1.0, t / 0.005) * pow(1.0 - progress, 1.4)
            let tone = sin(phase) + 0.35 * sin(phase * 1.5)
            let mixed = (tone * bodyEnv * 0.45) + (noise * impactEnv * 0.30)
            samples[i] = clampToInt16(mixed)
        }
        return encodeWAV(samples: samples)
    }

    /// Original cheerful 8-bar Sky Archipelago loop (120 BPM, 16.0 seconds seamless cycle).
    static func makeSkyIslandLoopWAV() -> Data {
        let stepDuration = 0.25 // Eighth-note at 120 BPM (64 steps = 16.0 seconds)
        let totalSteps = 64
        let totalDuration = Double(totalSteps) * stepDuration
        let totalSamples = Int(sampleRate * totalDuration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)

        // Melody frequencies in C Major / Lydian breeze (0 = rest)
        let melody: [Double] = [
            // Bar 1-2 (Cadd9)
            659.25, 0, 783.99, 659.25, 587.33, 0, 523.25, 0,
            587.33, 659.25, 783.99, 0, 659.25, 0, 0, 0,
            // Bar 3-4 (Am7 -> G6)
            659.25, 0, 880.00, 783.99, 659.25, 0, 523.25, 587.33,
            659.25, 0, 587.33, 0, 493.88, 0, 0, 0,
            // Bar 5-6 (Fmaj7 -> Em7)
            698.46, 0, 880.00, 0, 783.99, 659.25, 587.33, 0,
            659.25, 0, 783.99, 0, 659.25, 523.25, 493.88, 0,
            // Bar 7-8 (Dm9 -> G13 turnaround)
            587.33, 659.25, 698.46, 0, 783.99, 0, 880.00, 783.99,
            783.99, 659.25, 587.33, 0, 523.25, 0, 0, 0
        ]

        // Warm bass roots (one note every 2 steps = quarter notes)
        let bassRoots: [Double] = [
            130.81, 196.00, 130.81, 196.00, 130.81, 196.00, 130.81, 196.00, // C
            110.00, 164.81, 110.00, 164.81, 98.00,  146.83, 98.00,  146.83, // Am -> G
            174.61, 220.00, 174.61, 220.00, 164.81, 196.00, 164.81, 196.00, // F -> Em
            146.83, 220.00, 146.83, 220.00, 98.00,  146.83, 196.00, 146.83  // Dm -> G
        ]

        // Render bell-marimba melody
        for (step, freq) in melody.enumerated() where freq > 0 {
            let startTime = Double(step) * stepDuration
            let noteLen = stepDuration * 1.45
            addTone(
                to: &buffer,
                frequency: freq,
                startTime: startTime,
                duration: noteLen,
                amplitude: 0.20,
                overtoneRatio: 2.0,
                overtoneMix: 0.22
            )
        }

        // Render soft bassline
        for (beat, freq) in bassRoots.enumerated() {
            let startTime = Double(beat) * (stepDuration * 2.0)
            let noteLen = stepDuration * 1.85
            addTone(
                to: &buffer,
                frequency: freq,
                startTime: startTime,
                duration: noteLen,
                amplitude: 0.18,
                overtoneRatio: 2.0,
                overtoneMix: 0.12
            )
        }

        // Render gentle shimmer arpeggio pad on every bar
        let barChords: [[Double]] = [
            [261.63, 329.63, 392.00],
            [261.63, 329.63, 493.88],
            [220.00, 261.63, 329.63],
            [196.00, 246.94, 329.63],
            [174.61, 220.00, 261.63],
            [164.81, 246.94, 329.63],
            [146.83, 220.00, 261.63],
            [196.00, 246.94, 293.66]
        ]

        for (bar, chord) in barChords.enumerated() {
            let barStart = Double(bar) * (stepDuration * 8.0)
            for toneFreq in chord {
                addPadTone(
                    to: &buffer,
                    frequency: toneFreq,
                    startTime: barStart,
                    duration: stepDuration * 8.0,
                    amplitude: 0.055
                )
            }
        }

        var pcm = [Int16](repeating: 0, count: totalSamples)
        for i in 0..<totalSamples {
            pcm[i] = clampToInt16(buffer[i])
        }
        return encodeWAV(samples: pcm)
    }

    // MARK: - Helpers

    private static func renderPolyphonicNotes(
        notes: [(freq: Double, start: Double, length: Double, amp: Double)],
        totalDuration: Double
    ) -> Data {
        let totalSamples = Int(sampleRate * totalDuration)
        var mix = [Double](repeating: 0.0, count: totalSamples)

        for note in notes {
            addTone(
                to: &mix,
                frequency: note.freq,
                startTime: note.start,
                duration: note.length,
                amplitude: note.amp,
                overtoneRatio: 2.0,
                overtoneMix: 0.30
            )
        }

        var pcm = [Int16](repeating: 0, count: totalSamples)
        for i in 0..<totalSamples {
            pcm[i] = clampToInt16(mix[i])
        }
        return encodeWAV(samples: pcm)
    }

    private static func addTone(
        to buffer: inout [Double],
        frequency: Double,
        startTime: Double,
        duration: Double,
        amplitude: Double,
        overtoneRatio: Double,
        overtoneMix: Double
    ) {
        let startIndex = max(0, Int(startTime * sampleRate))
        let sampleCount = Int(duration * sampleRate)
        let total = buffer.count
        guard total > 0, sampleCount > 0 else { return }

        let phaseInc = (2.0 * .pi * frequency) / sampleRate
        var phase = 0.0

        for n in 0..<sampleCount {
            let t = Double(n) / sampleRate
            let progress = t / duration
            let attack = min(1.0, t / 0.008)
            let decay = pow(max(0.0, 1.0 - progress), 2.1)
            let env = attack * decay

            let sample = (sin(phase) + overtoneMix * sin(phase * overtoneRatio)) * env * amplitude
            let writeIdx = (startIndex + n) % total
            buffer[writeIdx] += sample
            phase += phaseInc
        }
    }

    private static func addPadTone(
        to buffer: inout [Double],
        frequency: Double,
        startTime: Double,
        duration: Double,
        amplitude: Double
    ) {
        let startIndex = max(0, Int(startTime * sampleRate))
        let sampleCount = Int(duration * sampleRate)
        let endIndex = min(buffer.count, startIndex + sampleCount)
        guard startIndex < endIndex else { return }

        let phaseInc = (2.0 * .pi * frequency) / sampleRate
        var phase = 0.0

        for idx in startIndex..<endIndex {
            let n = idx - startIndex
            let progress = Double(n) / Double(sampleCount)
            // Smooth sine window for click-free bar transitions
            let env = sin(.pi * progress)
            buffer[idx] += sin(phase) * env * amplitude
            phase += phaseInc
        }
    }

    private static func clampToInt16(_ normalized: Double) -> Int16 {
        let clamped = max(-0.98, min(0.98, normalized))
        return Int16(clamped * Double(Int16.max))
    }

    private static func encodeWAV(samples: [Int16]) -> Data {
        let dataByteCount = UInt32(samples.count * MemoryLayout<Int16>.size)
        let riffChunkSize = 36 + dataByteCount
        let byteRate = UInt32(sampleRate) * 2
        let blockAlign: UInt16 = 2
        let bitsPerSample: UInt16 = 16

        var wav = Data()
        wav.reserveCapacity(44 + Int(dataByteCount))

        wav.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        wav.appendLE(riffChunkSize)
        wav.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

        wav.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        wav.appendLE(UInt32(16))                         // PCM chunk size
        wav.appendLE(UInt16(1))                          // AudioFormat = 1 (PCM)
        wav.appendLE(UInt16(1))                          // NumChannels = 1 (Mono)
        wav.appendLE(UInt32(sampleRate))                 // SampleRate
        wav.appendLE(byteRate)                           // ByteRate
        wav.appendLE(blockAlign)                         // BlockAlign
        wav.appendLE(bitsPerSample)                      // BitsPerSample

        wav.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        wav.appendLE(dataByteCount)

        samples.withUnsafeBytes { rawBuffer in
            wav.append(contentsOf: rawBuffer)
        }

        return wav
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { raw in
            append(contentsOf: raw)
        }
    }
}
