import AppKit
import Combine
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private let settings = Settings.shared
    private let soundPlayer = SoundPlayer()
    private let timeAnnouncer = TimeAnnouncer()
    private let yoyoAnimator = YoyoAnimator()
    private var scheduler: ChimeScheduler!
    private var blinker: Blinker!
    private var explosionAnimator: ExplosionAnimator!
    private var statusItem: NSStatusItem!
    private var preferencesWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var nextChimeMenuItem: NSMenuItem!
    private var enabledMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!
    private var timeAnnouncementMenuItem: NSMenuItem!
    private var menuRefreshTimer: Timer?

    private var isEnabled = true

    private lazy var soundNames: [String] = SoundPlayer.availableSoundNames()

    private lazy var idleImage = StatusIconFactory.clock(palette: .brass)
    private lazy var alertImages = [
        StatusIconFactory.clock(palette: .crimson),
        StatusIconFactory.clock(palette: .emerald),
        StatusIconFactory.clock(palette: .amber)
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.load()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = idleImage
        statusItem.button?.imageScaling = .scaleProportionallyDown
        statusItem.button?.toolTip = "yoyo clock"

        blinker = Blinker(button: statusItem.button!, idleImage: idleImage, alertImages: alertImages)
        explosionAnimator = ExplosionAnimator(button: statusItem.button!, idleImage: idleImage)

        scheduler = ChimeScheduler(
            intervalProvider: { [unowned self] in self.settings.interval },
            onFire: { [weak self] date in self?.handleChime(at: date) }
        )

        buildMenu()
        scheduler.start()
        refreshMenuState()

        settings.scheduleDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self, self.isEnabled else { return }
                self.scheduler.reschedule()
                self.refreshMenuState()
            }
            .store(in: &cancellables)

        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                self.refreshMenuState()
                if !self.settings.announceTime || !self.settings.yoyoEnabled {
                    self.timeAnnouncer.stop()
                }
            }
            .store(in: &cancellables)

        let refresh = Timer(timeInterval: 20, repeats: true) { [weak self] _ in
            self?.refreshMenuState()
        }
        RunLoop.main.add(refresh, forMode: .common)
        menuRefreshTimer = refresh
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuRefreshTimer?.invalidate()
        scheduler?.stop()
        blinker?.stop()
        explosionAnimator?.stop()
        yoyoAnimator.stop()
        soundPlayer.stop()
        timeAnnouncer.stop()
    }

    // MARK: - Chime

    private func handleChime(at date: Date) {
        guard isEnabled else { return }
        refreshMenuState()
        guard !settings.isQuiet(at: date) else { return }
        performChime()
    }

    private func performChime() {
        blinker.stop()

        if settings.explosionEnabled {
            // Blink afterwards so the two effects don't fight over the icon.
            explosionAnimator.play(duration: 1.1) { [weak self] in
                guard let self, self.isEnabled, self.settings.blinkEnabled else { return }
                self.blinker.blink(flashes: self.settings.blinkCount)
            }
        } else if settings.blinkEnabled {
            blinker.blink(flashes: settings.blinkCount)
        }

        if settings.yoyoEnabled, let button = statusItem.button {
            playYoyo(from: button)
        }
        if settings.soundEnabled {
            soundPlayer.play(named: settings.soundName, volume: settings.volume)
        }
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        nextChimeMenuItem = NSMenuItem(title: "Next chime: —", action: nil, keyEquivalent: "")
        nextChimeMenuItem.isEnabled = false
        menu.addItem(nextChimeMenuItem)

        menu.addItem(.separator())

        enabledMenuItem = NSMenuItem(title: "Chimes Enabled",
                                     action: #selector(toggleEnabled),
                                     keyEquivalent: "")
        enabledMenuItem.target = self
        menu.addItem(enabledMenuItem)

        let intervalItem = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
        let intervalMenu = NSMenu()
        intervalMenu.autoenablesItems = false
        for interval in ChimeInterval.allCases {
            let item = NSMenuItem(title: interval.title,
                                  action: #selector(selectInterval(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.tag = interval.rawValue
            intervalMenu.addItem(item)
        }
        intervalItem.submenu = intervalMenu
        menu.addItem(intervalItem)

        let testItem = NSMenuItem(title: "Test Chime Now",
                                  action: #selector(testChime),
                                  keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)

        timeAnnouncementMenuItem = NSMenuItem(
            title: "Announce Time (Irish Voice)",
            action: #selector(toggleTimeAnnouncements),
            keyEquivalent: ""
        )
        timeAnnouncementMenuItem.target = self
        menu.addItem(timeAnnouncementMenuItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences…",
                                   action: #selector(openPreferences),
                                   keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login",
                                           action: #selector(toggleLaunchAtLogin),
                                           keyEquivalent: "")
        launchAtLoginMenuItem.target = self
        menu.addItem(launchAtLoginMenuItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit yoyo clock",
                                  action: #selector(NSApplication.terminate(_:)),
                                  keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func refreshMenuState() {
        enabledMenuItem?.state = isEnabled ? .on : .off
        refreshTimeAnnouncementState()

        if let intervalMenu = statusItem.menu?.item(withTitle: "Interval")?.submenu {
            for item in intervalMenu.items {
                item.state = item.tag == settings.interval.rawValue ? .on : .off
            }
        }

        launchAtLoginMenuItem?.state = isLaunchAtLoginEnabled ? .on : .off
        launchAtLoginMenuItem?.isHidden = !launchAtLoginSupported

        if !isEnabled {
            nextChimeMenuItem?.title = "Chimes paused"
            statusItem.button?.appearsDisabled = true
            return
        }

        statusItem.button?.appearsDisabled = false

        if let next = scheduler?.nextFireDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            var title = "Next chime: \(formatter.string(from: next))"
            if settings.isQuiet(at: next) {
                title += " (quiet)"
            }
            nextChimeMenuItem?.title = title
            statusItem.button?.toolTip = title
        } else {
            nextChimeMenuItem?.title = "Next chime: —"
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        refreshMenuState()
    }

    private func refreshTimeAnnouncementState() {
        guard let item = timeAnnouncementMenuItem else { return }
        item.state = settings.announceTime ? .on : .off
        item.toolTip = "Speak the current time in an Irish voice whenever the yo-yo drops. Uses the app's volume setting."
    }

    @objc private func toggleTimeAnnouncements() {
        settings.announceTime.toggle()
        if !settings.announceTime { timeAnnouncer.stop() }
        refreshTimeAnnouncementState()
    }

    private func playYoyo(from button: NSStatusBarButton) {
        yoyoAnimator.play(from: button, duration: settings.yoyoDuration)
        guard settings.announceTime else { return }
        do {
            try timeAnnouncer.announce(at: Date(), volume: settings.volume)
        } catch {
            NSLog("yoyo clock: time announcement failed: \(error.localizedDescription)")
            let alert = NSAlert()
            alert.messageText = "Irish voice unavailable"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        if isEnabled {
            scheduler.start()
        } else {
            scheduler.stop()
            blinker.stop()
            explosionAnimator.stop()
            yoyoAnimator.stop()
            soundPlayer.stop()
            timeAnnouncer.stop()
        }
        refreshMenuState()
    }

    @objc private func selectInterval(_ sender: NSMenuItem) {
        guard let interval = ChimeInterval(rawValue: sender.tag) else { return }
        settings.interval = interval
        refreshMenuState()
    }

    @objc private func testChime() {
        performChime()
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            let view = PreferencesView(
                settings: settings,
                soundNames: soundNames,
                onPreviewSound: { [weak self] name, volume in
                    self?.soundPlayer.play(named: name, volume: volume)
                },
                onPreviewBlink: { [weak self] in
                    guard let self else { return }
                    self.explosionAnimator.stop()
                    self.blinker.blink(flashes: self.settings.blinkCount)
                },
                onPreviewExplosion: { [weak self] in
                    guard let self else { return }
                    self.blinker.stop()
                    self.explosionAnimator.play(duration: 1.1)
                },
                onPreviewYoyo: { [weak self] in
                    guard let self, let button = self.statusItem.button else { return }
                    self.playYoyo(from: button)
                }
            )

            let hosting = NSHostingView(rootView: view)
            let window = NSWindow(contentRect: .zero,
                                  styleMask: [.titled, .closable],
                                  backing: .buffered,
                                  defer: false)
            window.title = "yoyo clock Preferences"
            window.contentView = hosting
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            preferencesWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSWindow) === preferencesWindow else { return }
        // Return to menu-bar-only mode so the app leaves the Dock and app switcher.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: - Launch at login

    private var launchAtLoginSupported: Bool {
        if #available(macOS 13.0, *) { return Bundle.main.bundleIdentifier != nil }
        return false
    }

    private var isLaunchAtLoginEnabled: Bool {
        guard #available(macOS 13.0, *), launchAtLoginSupported else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    @objc private func toggleLaunchAtLogin() {
        guard #available(macOS 13.0, *), launchAtLoginSupported else { return }
        do {
            if isLaunchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("yoyo clock: launch-at-login toggle failed: \(error.localizedDescription)")
        }
        refreshMenuState()
    }

}
