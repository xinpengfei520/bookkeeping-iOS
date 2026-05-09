//
//  BookMonthEntryView.swift
//  BookMonth
//
//  Visual reimplementation of the legacy ContentView.xib in SwiftUI.
//  Pixel-level fidelity is not the goal — WidgetKit canvas sizes
//  (158x158 / 338x158) differ from the Today extension's 110pt strip,
//  so layout is re-balanced for the new aspect ratios. Color tokens
//  and typography weights mirror the original.
//

import WidgetKit
import SwiftUI

// 主品牌色与文字色 — 跟 KKPrefixHeader.pch 的 RGBA(30,177,138,1) /
// kColor_Text_Black 等价物保持一致。Color 不能用 Objective-C 宏，
// 所以 widget 里独立定义一份。
struct BookMonthTheme {
    static let brandGreen = Color(red: 30 / 255.0, green: 177 / 255.0, blue: 138 / 255.0)
    static let brandGreenHighlight = Color(red: 30 / 255.0, green: 200 / 255.0, blue: 138 / 255.0)
    static let widgetBackground = Color(.systemBackground)
    static let primaryText = Color(.label)
    static let dim = Color(.secondaryLabel)
}

/// 把 entry.preferredScheme 应用到子树。nil 时 no-op，让 SwiftUI 跟随系统。
struct ColorSchemeOverride: ViewModifier {
    let scheme: ColorScheme?

    func body(content: Content) -> some View {
        if let s = scheme {
            content.environment(\.colorScheme, s)
        } else {
            content
        }
    }
}

struct BookMonthEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BookMonthEntry

    var body: some View {
        // 先选 family 渲染对应布局，再叠加用户的 colorScheme 偏好（如果设了）。
        // entry.preferredScheme == nil 表示"跟随系统"，让 SwiftUI 自己解析；
        // 否则把整个子树锁到 .light 或 .dark。
        Group {
            switch family {
            case .systemSmall:
                small
            default:
                medium
            }
        }
        .modifier(ColorSchemeOverride(scheme: entry.preferredScheme))
    }

    // 158x158 — 月份 + 收支结余三行 + 记一笔按钮
    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            monthHeader
            VStack(alignment: .leading, spacing: 4) {
                statRow(KKI18n.string(forKey: "收入"), value: entry.income)
                statRow(KKI18n.string(forKey: "支出"), value: entry.pay)
                statRow(KKI18n.string(forKey: "结余"), value: entry.balance)
            }
            Spacer(minLength: 0)
            bookButton
        }
        .padding(12)
    }

    // 338x158 — 左半月份 + 按钮，右半三列收支结余
    private var medium: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                monthHeader
                Spacer(minLength: 0)
                bookButton
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                statRow(KKI18n.string(forKey: "收入"), value: entry.income)
                statRow(KKI18n.string(forKey: "支出"), value: entry.pay)
                statRow(KKI18n.string(forKey: "结余"), value: entry.balance)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
    }

    // 月份 + 后缀（"月" / "Mo."）。点 monthHeader 整块也跳记账页。
    private var monthHeader: some View {
        Link(destination: URL(string: "kbook://month")!) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.month)")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(BookMonthTheme.primaryText)
                Text(KKI18n.string(forKey: "月"))
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(BookMonthTheme.primaryText)
            }
        }
    }

    private func statRow(_ label: String, value: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .light))
                .foregroundColor(BookMonthTheme.dim)
            Spacer()
            Text(formatPrice(value))
                .font(.system(size: 13, weight: .light))
                .foregroundColor(BookMonthTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // 同 ContentView.m 的 -getPriceStr: — 0/1/2 位小数自适应
    private func formatPrice(_ price: CGFloat) -> String {
        let v = Double(price)
        if v.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", v)
        } else if (v * 10).truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.1f", v)
        } else {
            return String(format: "%.2f", v)
        }
    }

    private var bookButton: some View {
        Link(destination: URL(string: "kbook://month")!) {
            Text(KKI18n.string(forKey: "记一笔"))
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(BookMonthTheme.brandGreen)
                .cornerRadius(3)
        }
    }
}
