import AppKit

/// Fires a callback at wall-clock boundaries aligned to the top of the hour
/// (e.g. :00, :15, :30, :45 for a 15 minute interval).
final class ChimeScheduler {
    private var timer: Timer?
    private let calendar = Calendar.current
    private var intervalProvider: () -> ChimeInterval
    private let onFire: (Date) -> Void

    private(set) var nextFireDate: Date?

    init(intervalProvider: @escaping () -> ChimeInterval, onFire: @escaping (Date) -> Void) {
        self.intervalProvider = intervalProvider
        self.onFire = onFire

        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self,
                           selector: #selector(systemStateChanged),
                           name: NSWorkspace.didWakeNotification,
                           object: nil)
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemStateChanged),
            name: Notification.Name("com.apple.system.timezone"),
            object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(systemStateChanged),
                                               name: .NSSystemClockDidChange,
                                               object: nil)
    }

    deinit {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func systemStateChanged() {
        reschedule()
    }

    func start() {
        reschedule()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        nextFireDate = nil
    }

    func reschedule() {
        timer?.invalidate()

        let next = Self.nextBoundary(after: Date(),
                                     intervalMinutes: intervalProvider().rawValue,
                                     calendar: calendar)
        nextFireDate = next

        let timer = Timer(fireAt: next,
                          interval: 0,
                          target: self,
                          selector: #selector(fire),
                          userInfo: nil,
                          repeats: false)
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func fire() {
        let firedAt = nextFireDate ?? Date()
        reschedule()
        onFire(firedAt)
    }

    /// Next instant strictly after `date` whose minute-of-hour is a multiple of
    /// `intervalMinutes` (with zero seconds), measured from the top of the hour.
    static func nextBoundary(after date: Date, intervalMinutes: Int, calendar: Calendar = .current) -> Date {
        let step = max(1, min(intervalMinutes, 60))

        var components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        components.minute = 0
        components.second = 0
        components.nanosecond = 0

        guard let hourStart = calendar.date(from: components) else {
            return date.addingTimeInterval(TimeInterval(step * 60))
        }

        // Walk forward in `step` minutes from the top of the current hour.
        var candidate = hourStart
        while candidate <= date {
            guard let advanced = calendar.date(byAdding: .minute, value: step, to: candidate) else {
                return date.addingTimeInterval(TimeInterval(step * 60))
            }
            candidate = advanced
        }
        return candidate
    }
}
