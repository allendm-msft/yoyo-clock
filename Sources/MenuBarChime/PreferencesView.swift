import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: Settings

    let soundNames: [String]
    let onPreviewSound: (String, Double) -> Void
    let onPreviewBlink: () -> Void
    let onPreviewExplosion: () -> Void
    let onPreviewYoyo: () -> Void

    private let hours = Array(0...23)

    var body: some View {
        ScrollView {
            preferencesContent
        }
        .frame(height: 620)
    }

    private var preferencesContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("yoyo clock")
                    .font(.title2.bold())
                Text("a macos app that drops a yoyo from your taskbar at an interval of your choosing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            section("Schedule") {
                Picker("Chime", selection: $settings.interval) {
                    ForEach(ChimeInterval.allCases) { interval in
                        Text(interval.title).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Text("Chimes are aligned to the top of the hour.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            section("Menu bar icon") {
                Toggle("Explode the clock when it rings", isOn: $settings.explosionEnabled)

                HStack {
                    Spacer()
                    Button("Test", action: onPreviewExplosion)
                }
                .disabled(!settings.explosionEnabled)

                Toggle("Blink the menu bar icon", isOn: $settings.blinkEnabled)

                HStack {
                    Text("Flashes")
                    Stepper(value: $settings.blinkCount, in: 1...20) {
                        Text("\(settings.blinkCount)")
                            .monospacedDigit()
                            .frame(minWidth: 24, alignment: .trailing)
                    }
                    Spacer()
                    Button("Test", action: onPreviewBlink)
                }
                .disabled(!settings.blinkEnabled)
            }

            Divider()

            section("Yo-yo") {
                Toggle("Drop a yo-yo from the menu bar icon", isOn: $settings.yoyoEnabled)

                HStack {
                    Text("Duration")
                    Slider(value: $settings.yoyoDuration, in: 1...10, step: 0.5)
                    Text("\(settings.yoyoDuration, specifier: "%.1f") sec")
                        .monospacedDigit()
                        .frame(width: 58, alignment: .trailing)
                    Button("Test", action: onPreviewYoyo)
                }
                .disabled(!settings.yoyoEnabled)
            }

            Divider()

            section("Sound") {
                Toggle("Play a sound", isOn: $settings.soundEnabled)

                HStack {
                    Picker("Sound", selection: $settings.soundName) {
                        ForEach(soundNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 200)

                    Button("Test") {
                        onPreviewSound(settings.soundName, settings.volume)
                    }
                }
                .disabled(!settings.soundEnabled)

                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                    Slider(value: $settings.volume, in: 0...1)
                        .accessibilityLabel("Chime and announcement volume")
                    Image(systemName: "speaker.wave.3.fill")
                    Text("\(Int((settings.volume * 100).rounded()))%")
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
                .disabled(!settings.soundEnabled && !settings.announceTime)
            }

            Divider()

            section("Time announcements") {
                Toggle("Announce time when the yo-yo drops", isOn: $settings.announceTime)
                Text("Uses an English (Ireland) voice and the volume slider above, independently of the chime sound. Test it with the Yo-yo Test button.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if TimeAnnouncer.irishVoice == nil {
                    Text("Install an English (Ireland) voice such as Moira in macOS Accessibility voice settings to enable Irish speech.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            section("Quiet hours") {
                Toggle("Silence chimes during quiet hours", isOn: $settings.quietHoursEnabled)

                HStack {
                    Picker("From", selection: $settings.quietStartHour) {
                        ForEach(hours, id: \.self) { Text(label(forHour: $0)).tag($0) }
                    }
                    .frame(maxWidth: 140)

                    Picker("To", selection: $settings.quietEndHour) {
                        ForEach(hours, id: \.self) { Text(label(forHour: $0)).tag($0) }
                    }
                    .frame(maxWidth: 140)
                }
                .disabled(!settings.quietHoursEnabled)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func label(forHour hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
