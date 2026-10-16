import AVFoundation

final class RobotVoice {
    static let gentle = ["Hm?", "Was that you?", "Oh. Hi.", "I noticed.", "Tickles.", "Easy there.", "Gentle."]
    static let stung = [
        "Ouch!", "Rude!", "Hey, I'm working here!", "Watch the hinge!", "That stung!", "Personal space!",
        "Why though?", "Uncalled for!",
    ]
    static let hurt = [
        "Agh! My pixels!", "I felt that in my battery!", "You'll void my warranty!", "That one rattled my fans!",
        "I'm writing this down!", "Okay, now I'm upset!",
    ]
    static let overwhelmed = [
        "Enough! Enough!", "I surrender!", "Is this a drum solo?", "Ten out of ten for enthusiasm.",
        "I need a moment.", "Stop, I'm only aluminum!",
    ]

    private let synthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "en-US")
    private var lastLine = ""

    func speak(intensity: Double, streak: Int, volume: Double) {
        let line = Self.lines(intensity: intensity, streak: streak).filter { $0 != lastLine }.randomElement()!
        lastLine = line

        let utterance = AVSpeechUtterance(string: line)
        utterance.voice = voice
        utterance.volume = Float(volume)
        utterance.pitchMultiplier = Float(0.9 + 0.7 * intensity)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * Float(1 + 0.04 * Double(min(streak, 6)))
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }

    private static func lines(intensity: Double, streak: Int) -> [String] {
        if streak >= 5 { return overwhelmed }
        if intensity > 0.75 { return hurt }
        if intensity > 0.35 { return stung }
        return gentle
    }
}
