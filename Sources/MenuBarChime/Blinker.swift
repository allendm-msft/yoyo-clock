import AppKit

/// Flashes a status item button while cycling through alert colors.
final class Blinker {
    private weak var button: NSStatusBarButton?
    private let idleImage: NSImage
    private let alertImages: [NSImage]

    private var timer: Timer?
    private var remainingSteps = 0
    private var showingAlert = false
    private var colorIndex = 0

    /// Seconds per half-cycle (icon on / icon off).
    var stepDuration: TimeInterval = 0.22

    init(button: NSStatusBarButton, idleImage: NSImage, alertImages: [NSImage]) {
        self.button = button
        self.idleImage = idleImage
        self.alertImages = alertImages
    }

    var isBlinking: Bool { timer != nil }

    /// `flashes` is the number of highlighted flashes to show.
    func blink(flashes: Int) {
        stop()
        guard flashes > 0, button != nil else { return }

        remainingSteps = flashes * 2
        showingAlert = false
        colorIndex = 0

        let timer = Timer(timeInterval: stepDuration, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    private func tick() {
        guard remainingSteps > 0 else {
            stop()
            return
        }
        remainingSteps -= 1
        showingAlert.toggle()
        if showingAlert, !alertImages.isEmpty {
            button?.image = alertImages[colorIndex % alertImages.count]
            colorIndex += 1
        } else {
            button?.image = idleImage
        }
        button?.appearsDisabled = false
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        remainingSteps = 0
        showingAlert = false
        colorIndex = 0
        button?.image = idleImage
    }
}
