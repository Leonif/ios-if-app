import Foundation

enum SourceReaderStrings {
    static var kicker: String { String(localized: "SourceReader.kicker", defaultValue: "Research, in context") }
    static var findings: String { String(localized: "SourceReader.findings", defaultValue: "The main finding") }
    static var limits: String { String(localized: "SourceReader.limits", defaultValue: "What this means for IF24") }
    static var original: String { String(localized: "SourceReader.original", defaultValue: "Read the original") }
    static var editorial: String { String(localized: "SourceReader.editorial", defaultValue: "An IF24 summary, not a translation of the full paper.") }
    static var review: String { String(localized: "SourceReader.review", defaultValue: "Review") }
    static var clinical: String { String(localized: "SourceReader.clinical", defaultValue: "Randomized trial · adults") }
    static var lab: String { String(localized: "SourceReader.lab", defaultValue: "Mechanistic study · mainly mice") }
    static var one_title: String { String(localized: "SourceReader.1.title", defaultValue: "How the body stores fuel") }
    static var one_body: String { String(localized: "SourceReader.1.body", defaultValue: "Glycogen stores glucose. This review explains the enzymes and hormones that regulate its storage and use.") }
    static var one_limit: String { String(localized: "SourceReader.1.limit", defaultValue: "Useful background for the fuel story. IF24 does not measure glycogen, so its timer cannot tell when your stores are empty.") }
    static var two_title: String { String(localized: "SourceReader.2.title", defaultValue: "Does fasting every other day work better?") }
    static var two_body: String { String(localized: "SourceReader.2.body", defaultValue: "Over one year, alternate-day fasting did not outperform daily calorie restriction for weight loss in this trial.") }
    static var two_limit: String { String(localized: "SourceReader.2.limit", defaultValue: "This studied a different schedule from a daily 16:8 window. It is not a test of IF24 and does not promise weight loss from using a timer.") }
    static var three_title: String { String(localized: "SourceReader.3.title", defaultValue: "Autophagy: understanding a mechanism") }
    static var three_body: String { String(localized: "SourceReader.3.body", defaultValue: "Experiments mainly in mice linked FGF21–JMJD3 signaling to liver autophagy and lipid breakdown.") }
    static var three_limit: String { String(localized: "SourceReader.3.limit", defaultValue: "A mechanism is not a personal timetable. IF24 cannot detect autophagy or establish that it starts at a particular fasting hour in a person.") }
    static var four_title: String { String(localized: "SourceReader.4.title", defaultValue: "Fasting and metabolic health") }
    static var four_body: String { String(localized: "SourceReader.4.body", defaultValue: "This review discusses fasting schedules and metabolic outcomes, while highlighting the need for longer-term evidence.") }
    static var four_limit: String { String(localized: "SourceReader.4.limit", defaultValue: "This is context, not an individual treatment plan. IF24 records time; it does not measure metabolic health or decide whether fasting is suitable for you.") }
}
