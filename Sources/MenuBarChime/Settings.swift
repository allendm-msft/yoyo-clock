import Foundation
import Combine

/// How often the chime fires, always aligned to the top of the hour.
enum ChimeInterval: Int, CaseIterable, Identifiable {
    case everyHour = 60
    case everyThirty = 30
    case everyFifteen = 15
    case everyTen = 10
    case everyFive = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .everyHour: return "Every hour (on the hour)"
        case .everyThirty: return "Every 30 minutes (:00, :30)"
        case .everyFifteen: return "Every 15 minutes (:00, :15, :30, :45)"
        case .everyTen: return "Every 10 minutes"
        case .everyFive: return "Every 5 minutes"
        }
    }

    var shortTitle: String {
        self == .everyHour ? "60 min" : "\(rawValue) min"
    }
}

private enum Key {
    static let interval = "chimeIntervalMinutes"
    static let blinkEnabled = "blinkEnabled"
    static let blinkCount = "blinkCount"
    static let soundEnabled = "soundEnabled"
    static let soundName = "soundName"
    static let volume = "soundVolume"
    static let explosionEnabled = "explosionEnabled"
    static let announceTime = "announceTime"
    static let yoyoEnabled = "yoyoEnabled"
    static let yoyoDuration = "yoyoDuration"
    static let quietHoursEnabled = "quietHoursEnabled"
    static let quietStartHour = "quietStartHour"
    static let quietEndHour = "quietEndHour"
}

final class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.interval: ChimeInterval.everyHour.rawValue,
            Key.blinkEnabled: true,
            Key.blinkCount: 6,
            Key.soundEnabled: true,
            Key.soundName: SoundPlayer.defaultSoundName,
            Key.volume: 0.6,
            Key.explosionEnabled: true,
            Key.announceTime: true,
            Key.yoyoEnabled: true,
            Key.yoyoDuration: 3.0,
            Key.quietHoursEnabled: false,
            Key.quietStartHour: 22,
            Key.quietEndHour: 8
        ])
    }

    /// Fires whenever a change requires the scheduler to recompute its next fire date.
    let scheduleDidChange = PassthroughSubject<Void, Never>()

    @Published var interval: ChimeInterval = .everyHour {
        didSet {
            guard interval != oldValue else { return }
            defaults.set(interval.rawValue, forKey: Key.interval)
            scheduleDidChange.send()
        }
    }

    @Published var blinkEnabled: Bool = true {
        didSet { defaults.set(blinkEnabled, forKey: Key.blinkEnabled) }
    }

    /// Number of on/off flashes per chime.
    @Published var blinkCount: Int = 6 {
        didSet { defaults.set(blinkCount, forKey: Key.blinkCount) }
    }

    @Published var explosionEnabled: Bool = true {
        didSet { defaults.set(explosionEnabled, forKey: Key.explosionEnabled) }
    }

    @Published var announceTime: Bool = true {
        didSet { defaults.set(announceTime, forKey: Key.announceTime) }
    }

    @Published var soundEnabled: Bool = true {
        didSet { defaults.set(soundEnabled, forKey: Key.soundEnabled) }
    }

    @Published var soundName: String = SoundPlayer.defaultSoundName {
        didSet { defaults.set(soundName, forKey: Key.soundName) }
    }

    /// 0.0 ... 1.0
    @Published var volume: Double = 0.6 {
        didSet {
            let clamped = min(max(volume, 0), 1)
            if clamped != volume {
                volume = clamped
                return
            }
            defaults.set(volume, forKey: Key.volume)
        }
    }

    @Published var yoyoEnabled: Bool = true {        didSet { defaults.set(yoyoEnabled, forKey: Key.yoyoEnabled) }
    }

    /// Duration of the drop and bounce animation, in seconds.
    @Published var yoyoDuration: Double = 3.0 {
        didSet {
            let clamped = min(max(yoyoDuration, 1), 10)
            if clamped != yoyoDuration {
                yoyoDuration = clamped
                return
            }
            defaults.set(yoyoDuration, forKey: Key.yoyoDuration)
        }
    }

    @Published var quietHoursEnabled: Bool = false {
        didSet { defaults.set(quietHoursEnabled, forKey: Key.quietHoursEnabled) }
    }

    @Published var quietStartHour: Int = 22 {
        didSet { defaults.set(quietStartHour, forKey: Key.quietStartHour) }
    }

    @Published var quietEndHour: Int = 8 {
        didSet { defaults.set(quietEndHour, forKey: Key.quietEndHour) }
    }

    func load() {
        interval = ChimeInterval(rawValue: defaults.integer(forKey: Key.interval)) ?? .everyHour
        blinkEnabled = defaults.bool(forKey: Key.blinkEnabled)
        blinkCount = max(1, min(defaults.integer(forKey: Key.blinkCount), 20))
        explosionEnabled = defaults.bool(forKey: Key.explosionEnabled)
        announceTime = defaults.bool(forKey: Key.announceTime)
        soundEnabled = defaults.bool(forKey: Key.soundEnabled)
        soundName = defaults.string(forKey: Key.soundName) ?? SoundPlayer.defaultSoundName
        volume = min(max(defaults.double(forKey: Key.volume), 0), 1)
        yoyoEnabled = defaults.bool(forKey: Key.yoyoEnabled)
        yoyoDuration = min(max(defaults.double(forKey: Key.yoyoDuration), 1), 10)
        quietHoursEnabled = defaults.bool(forKey: Key.quietHoursEnabled)
        quietStartHour = defaults.integer(forKey: Key.quietStartHour)
        quietEndHour = defaults.integer(forKey: Key.quietEndHour)
    }

    /// True when `date` falls inside the configured quiet window (wraps past midnight).
    func isQuiet(at date: Date) -> Bool {
        guard quietHoursEnabled else { return false }
        let hour = Calendar.current.component(.hour, from: date)
        if quietStartHour == quietEndHour { return false }
        if quietStartHour < quietEndHour {
            return hour >= quietStartHour && hour < quietEndHour
        }
        return hour >= quietStartHour || hour < quietEndHour
    }
}
