//
//  MealState.swift
//  IFApp
//
//  The last-meal picker's single source of truth. `ateMin = -1` means
//  "now / starting fresh" (no back-date yet).
//

struct MealState: Equatable, Sendable {
    var ateDay: Int = 0          // days ago, 0...6
    var ateMin: Int = -1         // minute-of-day 0...1439, -1 = now/fresh

    var isFresh: Bool { ateMin < 0 }
}
