//
//  BidiText.swift
//  IFApp
//
//  One definition of the wrapper the app puts around a formatted value before it is
//  substituted into a translated sentence. It lived private inside `HistoryFormat`,
//  which meant it protected the history rows and nothing else — every other
//  substitution site (the last-meal preview, the "fast counts from" subline) went
//  bare. Moved here so there is one wrapper to reach for, next to `Locale.latinDigits`
//  and for the same reason: a formatting rule that only exists at one call site is a
//  rule the next call site will not know about.
//

import Foundation

enum BidiText {
    /// Wraps a formatted value in a Unicode isolate, so the sentence around it cannot
    /// reorder it and it cannot reorder the sentence.
    ///
    /// FIRST STRONG ISOLATE (U+2068), not LEFT-TO-RIGHT ISOLATE — the direction is
    /// read off the value's own first strong character rather than asserted, and both
    /// readings of a clock time need that:
    ///
    /// - "19:00" has no strong character at all. It is a bare digit run whose place in
    ///   the line would otherwise be settled by whatever happens to sit beside it, and
    ///   that is exactly what the isolate is here to stop.
    /// - "8:00 م" has one. Arabic writes the meridiem after the digits, which on an
    ///   RTL line puts it to their *left*. LRI overrides that and lays the token out
    ///   left-to-right, so the meridiem lands on the wrong side — measured on the
    ///   history rows, which read "8:00 م" where ar_SA writes "م 8:00". FSI leaves it
    ///   where the language puts it and still keeps the token whole.
    ///
    /// Outside RTL the two are indistinguishable: the first strong character is Latin
    /// ("PM"), so FSI resolves to LTR and the bytes an LTR locale renders do not move.
    static func isolate(_ text: String) -> String {
        "\u{2068}\(text)\u{2069}"
    }
}
