//
//  BookMonthProvider.swift
//  BookMonth
//

import WidgetKit
import Foundation

struct BookMonthEntry: TimelineEntry {
    let date: Date
    let month: Int
    let income: CGFloat
    let pay: CGFloat
    var balance: CGFloat { income - pay }

    static var placeholder: BookMonthEntry {
        BookMonthEntry(date: Date(), month: Calendar.current.component(.month, from: Date()),
                       income: 0, pay: 0)
    }

    /// Read live data from the shared App Group. Reuses the main-app
    /// statistical pipeline via the OC bridging header (BookMonthModel
    /// reads NSUserDefaults suite "group.xpf.widget" internally via
    /// NSUserDefaults+Extension; same path as the legacy Today widget).
    static func current() -> BookMonthEntry {
        let now = Date()
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: now)
        let year = comps.year ?? 2026
        let month = comps.month ?? 1

        guard let monthModels = BookMonthModel.statisticalMonth(withYear: year, month: month) as? [BookMonthModel] else {
            return BookMonthEntry(date: now, month: month, income: 0, pay: 0)
        }

        var allDetails: [BookDetailModel] = []
        for m in monthModels {
            if let arr = m.array as? [BookDetailModel] {
                allDetails.append(contentsOf: arr)
            }
        }

        // Same categoryId thresholds as old ContentView.m: <=32 expense, >=33 income.
        let pay: CGFloat = allDetails
            .filter { $0.categoryId <= 32 }
            .reduce(0) { $0 + CGFloat($1.price) }
        let income: CGFloat = allDetails
            .filter { $0.categoryId >= 33 }
            .reduce(0) { $0 + CGFloat($1.price) }

        return BookMonthEntry(date: now, month: month, income: income, pay: pay)
    }
}

struct BookMonthProvider: TimelineProvider {
    func placeholder(in context: Context) -> BookMonthEntry {
        BookMonthEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BookMonthEntry) -> Void) {
        completion(BookMonthEntry.current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookMonthEntry>) -> Void) {
        // Single entry, refreshed roughly half-hourly. Cheap data, frequent
        // booking adds — 30 min covers the typical "I just logged something
        // and want to see it on the widget" case without hammering the
        // refresh budget. Main app can still nudge instantly via
        // WidgetCenter.shared.reloadAllTimelines() after a new entry.
        let entry = BookMonthEntry.current()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
