//
//  BookMonthProvider.swift
//  BookMonth
//

import WidgetKit
import Foundation
import SwiftUI

struct BookMonthEntry: TimelineEntry {
    let date: Date
    let month: Int
    let income: CGFloat
    let pay: CGFloat
    /// 主 app Me → 深色模式 的偏好。nil = 跟随系统（不覆盖）。
    /// "light" → .light；"dark" → .dark。从共享 App Group suite 读，与
    /// KKTheme.kk_app_theme_mode 同步。WidgetKit 进程自己有独立的 trait
    /// collection，不会自动跟主 app 的 overrideUserInterfaceStyle，所以
    /// 这里要手动把偏好搬过来。
    let preferredScheme: ColorScheme?
    var balance: CGFloat { income - pay }

    static var placeholder: BookMonthEntry {
        BookMonthEntry(date: Date(), month: Calendar.current.component(.month, from: Date()),
                       income: 0, pay: 0, preferredScheme: nil)
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
            return BookMonthEntry(date: now, month: month, income: 0, pay: 0,
                                  preferredScheme: readPreferredScheme())
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

        return BookMonthEntry(date: now, month: month, income: income, pay: pay,
                              preferredScheme: readPreferredScheme())
    }

    /// 读 KKTheme 在共享 suite 写下的 mode 偏好。key/value 的格式必须与
    /// KKTheme.m / KKTheme.h 保持同步（kk_app_theme_mode + "light" / "dark"）。
    private static func readPreferredScheme() -> ColorScheme? {
        guard let defaults = UserDefaults(suiteName: "group.xpf.widget"),
              let mode = defaults.string(forKey: "kk_app_theme_mode"),
              !mode.isEmpty else {
            return nil
        }
        switch mode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
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
