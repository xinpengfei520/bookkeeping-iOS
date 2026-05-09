//
//  BookMonthWidget.swift
//  BookMonth
//
//  WidgetKit replacement for the deprecated Today extension. Same App
//  Group ("group.xpf.widget") + same kbook:// URL scheme as the old
//  widget — main app and main-app URL handler don't need changes.
//

import WidgetKit
import SwiftUI

@main
struct BookMonthWidget: Widget {
    let kind: String = "BookMonthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookMonthProvider()) { entry in
            BookMonthEntryView(entry: entry)
                .widgetBackground(BookMonthTheme.widgetBackground)
        }
        .configurationDisplayName(KKI18n.string(forKey: "记呀"))
        .description(KKI18n.string(forKey: "查看本月收支总览，快速记一笔"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// iOS 17+ requires .containerBackground for proper styling on home screen
// + StandBy. iOS 16 only had .background. Wrap both via a modifier so the
// same view code runs on either.
extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}
