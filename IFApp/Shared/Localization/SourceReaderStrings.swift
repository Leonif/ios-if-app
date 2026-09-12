import Foundation

enum SourceReaderStrings {
    static var kicker: String { String(localized: "SourceReader.kicker", defaultValue: "Research, in context") }
    static var findings: String { String(localized: "SourceReader.findings", defaultValue: "The main finding") }
    static var limits: String { String(localized: "SourceReader.limits", defaultValue: "What this means for IF24") }
    static var original: String { String(localized: "SourceReader.original", defaultValue: "Read the original") }
    static var editorial: String { String(localized: "SourceReader.editorial", defaultValue: "An IF24 summary, not a translation of the full paper. IF24 is not a medical device and does not give medical advice - talk to a doctor before changing how you eat.") }
    static var review: String { String(localized: "SourceReader.review", defaultValue: "Review") }
    static var clinical: String { String(localized: "SourceReader.clinical", defaultValue: "Randomized trial · adults") }
    static var lab: String { String(localized: "SourceReader.lab", defaultValue: "Mechanistic study · mainly mice") }
    static var one_title: String { String(localized: "SourceReader.1.title", defaultValue: "How the body stores fuel") }
    static var one_body: String { String(localized: "SourceReader.1.body", defaultValue: "Glycogen is glucose packed into a branched particle - about 55,000 units at most, and the enzyme that frees glucose reaches only its outer layer. A chemistry review, not a study of fasting people.") }
    static var one_limit: String { String(localized: "SourceReader.1.limit", defaultValue: "IF24 does not measure glycogen. The timer counts hours; it cannot tell how full your stores are or when they run out.") }
    static var two_title: String { String(localized: "SourceReader.2.title", defaultValue: "Does fasting every other day work better?") }
    static var two_body: String { String(localized: "SourceReader.2.body", defaultValue: "One year, 100 obese adults: on average weight fell 6.0% on alternate-day fasting and 5.3% on daily calorie cutting - no real difference. More quit the fasting arm (38% vs 29%), and their LDL ran higher.") }
    static var two_limit: String { String(localized: "SourceReader.2.limit", defaultValue: "This studied a different schedule from a daily 16:8 window. It is not a test of IF24 and does not promise weight loss from using a timer.") }
    static var three_title: String { String(localized: "SourceReader.3.title", defaultValue: "Autophagy: understanding a mechanism") }
    static var three_body: String { String(localized: "SourceReader.3.body", defaultValue: "In mice, fasting raises the hormone FGF21, which unlocks autophagy genes; the liver then digests its own fat. Giving obese mice FGF21 cleared fatty liver. No fasting people were studied.") }
    static var three_limit: String { String(localized: "SourceReader.3.limit", defaultValue: "A mechanism is not a personal timetable. IF24 cannot detect autophagy or establish that it starts at a particular fasting hour in a person.") }
    static var four_title: String { String(localized: "SourceReader.4.title", defaultValue: "Fasting and metabolic health") }
    static var four_body: String { String(localized: "SourceReader.4.body", defaultValue: "A review with no measurements of its own. It reports that fasting schedules, including a 6-hour eating window, are associated with lower weight, better lipids and lower blood pressure, and that longer trials are still needed.") }
    static var four_limit: String { String(localized: "SourceReader.4.limit", defaultValue: "IF24 records time. It does not measure metabolic health and cannot decide whether fasting is suitable for you.") }
}
