import AppKit

/// Plays a system alert sound at a configurable volume.
final class SoundPlayer {
    static let defaultSoundName = "Submarine"

    private var current: NSSound?

    /// System sound names discovered from the standard sound directories.
    static func availableSoundNames() -> [String] {
        let directories = [
            "/System/Library/Sounds",
            "/Library/Sounds",
            (NSHomeDirectory() as NSString).appendingPathComponent("Library/Sounds")
        ]

        var names = Set<String>()
        for directory in directories {
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: directory) else { continue }
            for entry in entries {
                let name = (entry as NSString).deletingPathExtension
                if !name.isEmpty, NSSound(named: name) != nil {
                    names.insert(name)
                }
            }
        }

        if names.isEmpty { names.insert(defaultSoundName) }
        return names.sorted()
    }

    func play(named name: String, volume: Double) {
        current?.stop()

        guard let sound = NSSound(named: name) ?? NSSound(named: Self.defaultSoundName) else {
            NSSound.beep()
            return
        }

        // NSSound(named:) returns a shared instance; copy it so volume stays local.
        let instance = (sound.copy() as? NSSound) ?? sound
        instance.volume = Float(min(max(volume, 0), 1))
        current = instance
        instance.play()
    }

    func stop() {
        current?.stop()
        current = nil
    }
}
