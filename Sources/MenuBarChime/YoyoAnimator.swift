import AppKit
import QuartzCore

/// Presents a click-through yo-yo animation directly below a status bar item.
final class YoyoAnimator {
    private static let funEmojis = [
        "🪀", "🕷️", "🧙‍♀️", "👻", "🎃", "🦇",
        "🐙", "👾", "🤖", "🐸", "🦄", "🐝",
        "🍄", "🌈", "🚀", "🛸", "🐲", "😈"
    ]

    private var panels: [NSPanel] = []
    private var animationViews: [YoyoView] = []
    private var timer: Timer?
    private var startedAt: TimeInterval = 0
    private var duration: TimeInterval = 3

    private static let panelSize = NSSize(width: 100, height: 210)

    func play(from button: NSStatusBarButton, duration: TimeInterval) {
        stop()

        guard let buttonWindow = button.window else { return }
        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)

        let emoji = Self.funEmojis.randomElement() ?? "🪀"
        let screens = NSScreen.screens.isEmpty ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
        let buttonScreen = screens.first { $0.frame.intersects(screenRect) }

        for screen in screens {
            let anchor = Self.anchorPoint(
                on: screen,
                buttonRect: screenRect,
                isButtonScreen: screen == buttonScreen
            )
            let panel = makePanel(at: anchor, emoji: emoji)
            panels.append(panel)
            if let view = panel.contentView as? YoyoView {
                animationViews.append(view)
            }
        }

        guard !panels.isEmpty else { return }

        self.duration = min(max(duration, 1), 10)
        startedAt = ProcessInfo.processInfo.systemUptime

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.tolerance = 0.002
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    /// Top-center point the string hangs from, in screen coordinates. Screens
    /// without the status item mirror the item's distance from the right edge,
    /// so the animation still lands under each menu bar's extras area.
    private static func anchorPoint(
        on screen: NSScreen,
        buttonRect: NSRect,
        isButtonScreen: Bool
    ) -> NSPoint {
        if isButtonScreen {
            return NSPoint(x: buttonRect.midX, y: buttonRect.minY)
        }

        let sourceScreen = NSScreen.screens.first { $0.frame.intersects(buttonRect) }
        let insetFromRight = (sourceScreen?.frame.maxX ?? buttonRect.maxX) - buttonRect.midX
        let frame = screen.frame
        let minimumX = frame.minX + panelSize.width / 2
        let maximumX = frame.maxX - panelSize.width / 2
        let x = min(max(frame.maxX - insetFromRight, minimumX), maximumX)

        return NSPoint(x: x, y: screen.visibleFrame.maxY)
    }

    private func makePanel(at anchor: NSPoint, emoji: String) -> NSPanel {
        let size = Self.panelSize
        let origin = NSPoint(x: anchor.x - size.width / 2, y: anchor.y - size.height)

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let view = YoyoView(frame: NSRect(origin: .zero, size: size), emoji: emoji)
        panel.contentView = view
        panel.orderFrontRegardless()
        return panel
    }

    private func tick() {
        let elapsed = ProcessInfo.processInfo.systemUptime - startedAt
        guard elapsed < duration else {
            stop()
            return
        }

        let progress = elapsed / duration
        let fadeIn = min(progress / 0.06, 1)
        let fadeOut = min((1 - progress) / 0.12, 1)
        animationViews.forEach { view in
            view.alphaValue = min(fadeIn, fadeOut)
            view.progress = progress
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        animationViews.removeAll()
    }
}

private final class YoyoView: NSView {
    private let emoji: String

    var progress: Double = 0 {
        didSet { needsDisplay = true }
    }

    init(frame frameRect: NSRect, emoji: String) {
        self.emoji = emoji
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let centerX = bounds.midX
        let emojiRadius: CGFloat = 17
        let topY: CGFloat = 1
        let maximumY = bounds.height - emojiRadius - 5

        // The first fifth is a gravity-like drop; the rest repeats smooth
        // up/down yo-yo cycles while keeping some string visible.
        let dropEnd = 0.20
        let centerY: CGFloat
        if progress < dropEnd {
            let t = progress / dropEnd
            centerY = topY + emojiRadius + (maximumY - topY - emojiRadius) * CGFloat(t * t)
        } else {
            let t = (progress - dropEnd) / (1 - dropEnd)
            let cycles = 2.5
            let wave = (1 - cos(t * cycles * 2 * .pi)) / 2
            let highestY = bounds.height * 0.32
            centerY = maximumY - (maximumY - highestY) * CGFloat(wave)
        }

        let stringPath = NSBezierPath()
        stringPath.move(to: NSPoint(x: centerX, y: topY))
        stringPath.line(to: NSPoint(x: centerX, y: centerY - emojiRadius + 4))
        stringPath.lineWidth = 1.5
        NSColor.labelColor.withAlphaComponent(0.75).setStroke()
        stringPath.stroke()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 30)
        ]
        let attributedEmoji = NSAttributedString(string: emoji, attributes: attributes)
        let emojiSize = attributedEmoji.size()
        let swing = CGFloat(sin(progress * 12 * .pi) * 12)

        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: centerX, yBy: centerY)
        transform.rotate(byDegrees: swing)
        transform.translateX(by: -centerX, yBy: -centerY)
        transform.concat()
        attributedEmoji.draw(at: NSPoint(
            x: centerX - emojiSize.width / 2,
            y: centerY - emojiSize.height / 2
        ))
        NSGraphicsContext.restoreGraphicsState()
    }
}
