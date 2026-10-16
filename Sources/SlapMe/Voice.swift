import AVFoundation
import SlapCore

final class Voice {
    static let quietest = 0.125
    static let extensions: Set = ["mp3", "wav", "m4a", "aac", "aif", "aiff", "caf"]

    private enum Source {
        case robot, loading
        case clips([AVAudioPlayer])
    }

    private let robot = RobotVoice()
    private var files: [URL] = []
    private var source = Source.robot
    private var loading: Task<Void, Never>?

    static func sounds(in folder: URL) -> [URL] {
        let entries = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        )) ?? []
        return entries
            .filter { extensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    func load() {
        let next = Settings.usesSoundsFolder ? Settings.soundsFolder.map(Self.sounds) ?? [] : []
        guard next != files else { return }
        files = next
        loading?.cancel()
        guard !next.isEmpty else {
            source = .robot
            return
        }
        source = .loading
        loading = Task {
            let clips = await Self.decode(next)
            guard !Task.isCancelled else { return }
            source = clips.isEmpty ? .robot : .clips(clips)
        }
    }

    func react(to slap: Slap, streak: Streak) {
        let volume = Settings.volume * (Settings.dynamicVolume ? Self.quietest + (1 - Self.quietest) * slap.intensity : 1)
        switch source {
        case .loading: break
        case .robot: robot.speak(intensity: slap.intensity, streak: streak.count, volume: volume)
        case .clips(let clips): clips.randomElement().map { play($0, volume: volume) }
        }
    }

    func moan() {
        switch source {
        case .loading: break
        case .robot: robot.speak(intensity: 0.5, streak: 1, volume: Settings.volume)
        case .clips(let clips): clips.randomElement().map { play($0, volume: Settings.volume) }
        }
    }

    private func play(_ player: AVAudioPlayer, volume: Double) {
        player.volume = Float(volume)
        player.currentTime = 0
        player.play()
    }

    @concurrent
    private nonisolated static func decode(_ files: [URL]) async -> sending [AVAudioPlayer] {
        files.compactMap { url in
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            return player
        }
    }
}
