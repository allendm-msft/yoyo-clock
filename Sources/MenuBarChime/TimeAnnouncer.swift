import AVFoundation
import Foundation

final class TimeAnnouncer {
    private let synthesizer = AVSpeechSynthesizer()

    static var irishVoice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "en-IE" }
            .sorted {
                if $0.quality.rawValue != $1.quality.rawValue {
                    return $0.quality.rawValue > $1.quality.rawValue
                }
                return $0.identifier < $1.identifier
            }
            .first
    }

    static func phrase(at date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IE")
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return "\(formatter.string(from: date))."
    }

    func announce(at date: Date, volume: Double) throws {
        guard let voice = Self.irishVoice else {
            throw AnnouncementError.missingIrishVoice
        }

        stop()
        let utterance = AVSpeechUtterance(string: Self.phrase(at: date))
        utterance.voice = voice
        utterance.volume = Float(min(max(volume, 0), 1))
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    enum AnnouncementError: LocalizedError {
        case missingIrishVoice

        var errorDescription: String? {
            "Install an English (Ireland) voice, such as Moira, in System Settings → Accessibility → Spoken Content (or Read & Speak) → System Voice → Manage Voices. Then try the yo-yo again."
        }
    }
}
