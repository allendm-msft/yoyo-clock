import AppKit

/// Colour scheme for one rendering of the Victorian pocket watch icon.
struct ClockPalette {
    let bezelHighlight: NSColor
    let bezelShadow: NSColor
    let face: NSColor
    let numerals: NSColor
    let hands: NSColor

    static let brass = ClockPalette(
        bezelHighlight: NSColor(calibratedRed: 0.98, green: 0.84, blue: 0.51, alpha: 1),
        bezelShadow: NSColor(calibratedRed: 0.60, green: 0.40, blue: 0.09, alpha: 1),
        face: NSColor(calibratedRed: 0.98, green: 0.95, blue: 0.87, alpha: 1),
        numerals: NSColor(calibratedRed: 0.27, green: 0.17, blue: 0.08, alpha: 1),
        hands: NSColor(calibratedRed: 0.13, green: 0.11, blue: 0.24, alpha: 1)
    )

    static let crimson = ClockPalette(
        bezelHighlight: NSColor(calibratedRed: 1.0, green: 0.46, blue: 0.42, alpha: 1),
        bezelShadow: NSColor(calibratedRed: 0.62, green: 0.03, blue: 0.08, alpha: 1),
        face: NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.88, alpha: 1),
        numerals: NSColor(calibratedRed: 0.42, green: 0.05, blue: 0.07, alpha: 1),
        hands: NSColor(calibratedRed: 0.30, green: 0.02, blue: 0.05, alpha: 1)
    )

    static let emerald = ClockPalette(
        bezelHighlight: NSColor(calibratedRed: 0.55, green: 0.97, blue: 0.62, alpha: 1),
        bezelShadow: NSColor(calibratedRed: 0.03, green: 0.45, blue: 0.20, alpha: 1),
        face: NSColor(calibratedRed: 0.91, green: 1.0, blue: 0.92, alpha: 1),
        numerals: NSColor(calibratedRed: 0.04, green: 0.31, blue: 0.16, alpha: 1),
        hands: NSColor(calibratedRed: 0.03, green: 0.22, blue: 0.12, alpha: 1)
    )

    static let amber = ClockPalette(
        bezelHighlight: NSColor(calibratedRed: 1.0, green: 0.93, blue: 0.46, alpha: 1),
        bezelShadow: NSColor(calibratedRed: 0.76, green: 0.48, blue: 0.02, alpha: 1),
        face: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.83, alpha: 1),
        numerals: NSColor(calibratedRed: 0.40, green: 0.26, blue: 0.02, alpha: 1),
        hands: NSColor(calibratedRed: 0.26, green: 0.17, blue: 0.02, alpha: 1)
    )
}

enum StatusIconFactory {
    static let canvas = NSSize(width: 22, height: 22)

    private static let center = NSPoint(x: 11, y: 9.5)
    private static let caseRadius: CGFloat = 8.0

    /// An ornate Victorian pocket watch: fluted brass case, crown and bow at
    /// the top, cream enamel dial with baton hour markers and spade hands.
    static func clock(palette: ClockPalette) -> NSImage {
        let image = NSImage(size: canvas, flipped: false) { _ in
            NSGraphicsContext.current?.imageInterpolation = .high
            drawCrown(palette: palette)
            drawCase(palette: palette)
            drawDial(palette: palette)
            drawHands(palette: palette)
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = "yoyo clock"
        return image
    }

    private static func drawCrown(palette: ClockPalette) {
        let stem = NSBezierPath(
            roundedRect: NSRect(x: center.x - 1.5, y: center.y + 7.4, width: 3.0, height: 2.2),
            xRadius: 0.9,
            yRadius: 0.9
        )
        NSGradient(starting: palette.bezelHighlight, ending: palette.bezelShadow)?
            .draw(in: stem, angle: -90)

        let bow = NSBezierPath(ovalIn: NSRect(
            x: center.x - 1.7,
            y: center.y + 9.0,
            width: 3.4,
            height: 3.2
        ))
        bow.lineWidth = 1.2
        palette.bezelShadow.setStroke()
        bow.stroke()
        palette.bezelHighlight.withAlphaComponent(0.85).setStroke()
        bow.lineWidth = 0.6
        bow.stroke()
    }

    private static func drawCase(palette: ClockPalette) {
        let caseRect = NSRect(
            x: center.x - caseRadius,
            y: center.y - caseRadius,
            width: caseRadius * 2,
            height: caseRadius * 2
        )
        let caseCircle = NSBezierPath(ovalIn: caseRect)

        NSGraphicsContext.saveGraphicsState()
        caseCircle.addClip()
        NSGradient(starting: palette.bezelHighlight, ending: palette.bezelShadow)?
            .draw(in: caseRect, angle: -90)

        // Fluted knurling around the case edge, a hallmark of the period.
        palette.bezelShadow.withAlphaComponent(0.55).setStroke()
        for index in 0..<24 {
            let angle = Double(index) / 24 * 2 * .pi
            let flute = NSBezierPath()
            flute.move(to: NSPoint(
                x: center.x + cos(angle) * (caseRadius - 1.6),
                y: center.y + sin(angle) * (caseRadius - 1.6)
            ))
            flute.line(to: NSPoint(
                x: center.x + cos(angle) * caseRadius,
                y: center.y + sin(angle) * caseRadius
            ))
            flute.lineWidth = 0.6
            flute.stroke()
        }
        NSGraphicsContext.restoreGraphicsState()

        NSColor(calibratedRed: 0.22, green: 0.14, blue: 0.04, alpha: 0.65).setStroke()
        caseCircle.lineWidth = 0.8
        caseCircle.stroke()
    }

    private static func drawDial(palette: ClockPalette) {
        let dialRadius: CGFloat = 6.1
        let dialRect = NSRect(
            x: center.x - dialRadius,
            y: center.y - dialRadius,
            width: dialRadius * 2,
            height: dialRadius * 2
        )
        let dial = NSBezierPath(ovalIn: dialRect)
        palette.face.setFill()
        dial.fill()
        palette.bezelShadow.withAlphaComponent(0.8).setStroke()
        dial.lineWidth = 0.8
        dial.stroke()

        palette.numerals.setStroke()
        for index in 0..<12 {
            let angle = Double(index) / 12 * 2 * .pi
            let isQuarter = index % 3 == 0
            let inner = dialRadius - (isQuarter ? 2.4 : 1.5)
            let tick = NSBezierPath()
            tick.move(to: NSPoint(
                x: center.x + cos(angle) * inner,
                y: center.y + sin(angle) * inner
            ))
            tick.line(to: NSPoint(
                x: center.x + cos(angle) * (dialRadius - 0.7),
                y: center.y + sin(angle) * (dialRadius - 0.7)
            ))
            tick.lineWidth = isQuarter ? 1.3 : 0.7
            tick.lineCapStyle = .round
            tick.stroke()
        }
    }

    private static func drawHands(palette: ClockPalette) {
        // Classic 10:10 display pose.
        drawHand(angleDegrees: 120, length: 3.4, width: 1.6, palette: palette)
        drawHand(angleDegrees: 60, length: 4.5, width: 1.3, palette: palette)

        let hub = NSBezierPath(ovalIn: NSRect(
            x: center.x - 1.2,
            y: center.y - 1.2,
            width: 2.4,
            height: 2.4
        ))
        palette.hands.setFill()
        hub.fill()

        let jewel = NSBezierPath(ovalIn: NSRect(
            x: center.x - 0.45,
            y: center.y - 0.45,
            width: 0.9,
            height: 0.9
        ))
        palette.bezelHighlight.setFill()
        jewel.fill()
    }

    private static func drawHand(
        angleDegrees: Double,
        length: CGFloat,
        width: CGFloat,
        palette: ClockPalette
    ) {
        let angle = angleDegrees * .pi / 180
        let tip = NSPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)

        let shaft = NSBezierPath()
        shaft.move(to: center)
        shaft.line(to: tip)
        shaft.lineWidth = width
        shaft.lineCapStyle = .round
        palette.hands.setStroke()
        shaft.stroke()

        // Spade tip typical of Victorian watch hands.
        let spade = NSBezierPath(ovalIn: NSRect(
            x: tip.x - width * 0.85,
            y: tip.y - width * 0.85,
            width: width * 1.7,
            height: width * 1.7
        ))
        palette.hands.setFill()
        spade.fill()
    }

    // MARK: - Explosion

    private static let shardAngles: [Double] = [8, 47, 84, 123, 161, 198, 236, 274, 312, 341]
    private static let sparkAngles: [Double] = [20, 55, 95, 130, 170, 205, 245, 285, 320, 355, 68, 143]
    private static let sparkColors: [NSColor] = [.systemRed, .systemGreen, .systemYellow, .systemOrange]

    /// One frame of the "clock bursts apart and reassembles" animation.
    /// `progress` runs 0...1 over the whole sequence.
    static func explosionFrame(progress: Double, base: NSImage) -> NSImage {
        let clamped = min(max(progress, 0), 1)

        let image = NSImage(size: canvas, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high

            let chargeEnd = 0.10
            let burstEnd = 0.72

            if clamped < chargeEnd {
                let t = clamped / chargeEnd
                drawBase(base, in: rect, scale: 1 + 0.18 * CGFloat(t), alpha: 1)
                NSColor.white.withAlphaComponent(CGFloat(t) * 0.7).setFill()
                NSBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3)).fill()
                return true
            }

            if clamped < burstEnd {
                let t = (clamped - chargeEnd) / (burstEnd - chargeEnd)
                drawShockwave(progress: t)
                drawShards(spread: easeOut(t), spin: t, alpha: 1 - t * 0.3)
                drawSparks(spread: easeOut(t), alpha: 1 - t)
                drawBurstGlyph(progress: t, in: rect)
                return true
            }

            let t = (clamped - burstEnd) / (1 - burstEnd)
            drawShards(spread: 1 - easeOut(t), spin: 1 - t, alpha: 1 - t)
            drawBase(base, in: rect, scale: 1 + 0.25 * CGFloat(1 - t), alpha: CGFloat(t))
            return true
        }

        image.isTemplate = false
        image.accessibilityDescription = "yoyo clock"
        return image
    }

    private static func easeOut(_ t: Double) -> Double {
        1 - pow(1 - t, 2.2)
    }

    private static func drawBase(_ base: NSImage, in rect: NSRect, scale: CGFloat, alpha: CGFloat) {
        guard alpha > 0 else { return }
        let width = rect.width * scale
        let height = rect.height * scale
        let target = NSRect(
            x: rect.midX - width / 2,
            y: rect.midY - height / 2,
            width: width,
            height: height
        )
        base.draw(in: target, from: .zero, operation: .sourceOver, fraction: alpha)
    }

    private static func drawShockwave(progress: Double) {
        let radius = 2 + CGFloat(easeOut(progress)) * 9.5
        let ring = NSBezierPath(ovalIn: NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        ring.lineWidth = max(0.4, 2.6 * CGFloat(1 - progress))
        NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.45, alpha: CGFloat(1 - progress) * 0.9).setStroke()
        ring.stroke()
    }

    private static func drawShards(spread: Double, spin: Double, alpha: Double) {
        guard alpha > 0 else { return }

        for (index, angleDegrees) in shardAngles.enumerated() {
            let angle = angleDegrees * .pi / 180
            let distance = CGFloat(spread) * 8.2
            let position = NSPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )
            let direction: Double = index.isMultiple(of: 2) ? 1 : -1
            let size = 2.6 - CGFloat(spread) * 0.9

            NSGraphicsContext.saveGraphicsState()
            let transform = NSAffineTransform()
            transform.translateX(by: position.x, yBy: position.y)
            transform.rotate(byDegrees: CGFloat(spin * 260 * direction))
            transform.concat()

            let shard = NSBezierPath()
            shard.move(to: NSPoint(x: -size, y: -size * 0.75))
            shard.line(to: NSPoint(x: size, y: 0))
            shard.line(to: NSPoint(x: -size * 0.6, y: size))
            shard.close()

            let palette: ClockPalette = index % 3 == 0 ? .crimson : (index % 3 == 1 ? .amber : .brass)
            palette.bezelHighlight.withAlphaComponent(CGFloat(alpha)).setFill()
            shard.fill()
            palette.bezelShadow.withAlphaComponent(CGFloat(alpha) * 0.9).setStroke()
            shard.lineWidth = 0.6
            shard.stroke()
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private static func drawSparks(spread: Double, alpha: Double) {
        guard alpha > 0 else { return }

        for (index, angleDegrees) in sparkAngles.enumerated() {
            let angle = angleDegrees * .pi / 180
            let distance = CGFloat(spread) * 10.5
            let radius = max(0.3, 1.3 * CGFloat(1 - spread))
            let dot = NSBezierPath(ovalIn: NSRect(
                x: center.x + cos(angle) * distance - radius,
                y: center.y + sin(angle) * distance - radius,
                width: radius * 2,
                height: radius * 2
            ))
            sparkColors[index % sparkColors.count]
                .withAlphaComponent(CGFloat(alpha))
                .setFill()
            dot.fill()
        }
    }

    private static func drawBurstGlyph(progress: Double, in rect: NSRect) {
        let alpha: Double
        if progress < 0.2 {
            alpha = progress / 0.2
        } else {
            alpha = max(0, 1 - (progress - 0.2) / 0.5)
        }
        guard alpha > 0.01 else { return }

        let glyph = NSAttributedString(
            string: "💥",
            attributes: [.font: NSFont.systemFont(ofSize: 15)]
        )
        let size = glyph.size()

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.cgContext.setAlpha(CGFloat(alpha))
        glyph.draw(at: NSPoint(x: rect.midX - size.width / 2, y: center.y - size.height / 2))
        NSGraphicsContext.restoreGraphicsState()
    }
}
