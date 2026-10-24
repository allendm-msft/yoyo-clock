import AppKit

/// Bursts the status bar clock apart and reassembles it.
final class ExplosionAnimator {
    private weak var button: NSStatusBarButton?
    private let idleImage: NSImage

    private var timer: Timer?
    private var startedAt: TimeInterval = 0
    private var duration: TimeInterval = 1.1
    private var completion: (() -> Void)?

    init(button: NSStatusBarButton, idleImage: NSImage) {
        self.button = button
        self.idleImage = idleImage
    }

    var isAnimating: Bool { timer != nil }

    func play(duration: TimeInterval = 1.1, completion: (() -> Void)? = nil) {
        stop()

        self.duration = min(max(duration, 0.3), 5)
        self.completion = completion
        startedAt = ProcessInfo.processInfo.systemUptime

        let timer = Timer(timeInterval: 1.0 / 40.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.tolerance = 0.005
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    private func tick() {
        let elapsed = ProcessInfo.processInfo.systemUptime - startedAt
        guard elapsed < duration else {
            let finished = completion
            stop()
            finished?()
            return
        }

        button?.image = StatusIconFactory.explosionFrame(
            progress: elapsed / duration,
            base: idleImage
        )
        button?.appearsDisabled = false
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        completion = nil
        button?.image = idleImage
    }
}
