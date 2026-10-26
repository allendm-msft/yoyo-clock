import Foundation

@main
struct TimeAnnouncerTests {
    static func main() {
        let utc = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc

        for (hour, minute, expected) in [
            (0, 0, "12:00 AM."),
            (12, 0, "12:00 PM."),
            (14, 15, "2:15 PM."),
            (23, 59, "11:59 PM.")
        ] {
            let date = calendar.date(from: DateComponents(
                year: 2026, month: 10, day: 26, hour: hour, minute: minute
            ))!
            let phrase = TimeAnnouncer.phrase(at: date, timeZone: utc)
            precondition(phrase == expected, "Unexpected time phrase: \(phrase)")
        }

        let date = calendar.date(from: DateComponents(
            year: 2026, month: 10, day: 26, hour: 14, minute: 0
        ))!
        let localPhrase = TimeAnnouncer.phrase(at: date, timeZone: TimeZone(secondsFromGMT: 19800)!)
        precondition(localPhrase == "7:30 PM.")

        if let voice = TimeAnnouncer.irishVoice {
            precondition(voice.language == "en-IE")
            print("Irish voice available: \(voice.name) (\(voice.identifier))")
        } else {
            print("No installed Irish voice; app will report installation instructions.")
        }
        print("PASS: midnight, noon, minutes, timezone, and Irish-only voice selection (no audio played)")
    }
}
