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

// 主品牌色固定（跨浅 / 深色一致）。文字 / 背景色不在这里硬编码，因为
// SwiftUI 的 \.colorScheme env override 不会作用到 UIKit-bridged 颜色
// （`Color(.label)` / `Color(.systemBackground)` 看的是 UITraitCollection，
// widget 进程的 trait 是系统决定的）；改用 SwiftUI 原生的 `.primary` /
// `.secondary` + 直接计算的字面色，让 env 真正生效。
struct BookMonthTheme {
    static let brandGreen = Color(red: 30 / 255.0, green: 177 / 255.0, blue: 138 / 255.0)
    static let brandGreenHighlight = Color(red: 30 / 255.0, green: 200 / 255.0, blue: 138 / 255.0)
}

struct BookMonthEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var systemScheme
    let entry: BookMonthEntry

    /// 实际生效的 colorScheme：用户在主 app 选了 light/dark 就用之；
    /// 否则跟随 widget 进程的系统 trait（systemScheme）。
    private var effectiveScheme: ColorScheme {
        entry.preferredScheme ?? systemScheme
    }

    /// 浅色 → 白；深色 → 接近黑的灰（避免纯黑过于硬）。直接用字面 Color，
    /// 不走 UIKit semantic color，确保 env override 后这里能跟上。
    private var widgetBg: Color {
        effectiveScheme == .dark ? Color(white: 0.06) : .white
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                small
            default:
                medium
            }
        }
        // 先把 env 锁到 effectiveScheme — 子树里的 .primary / .secondary
        // 才会跟着翻。
        .environment(\.colorScheme, effectiveScheme)
        .widgetBackground(widgetBg)
    }

    // 158x158 — 月份 + 收支结余三行 + 记一笔按钮
    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            monthHeader
            VStack(alignment: .leading, spacing: 6) {
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
            VStack(alignment: .leading, spacing: 10) {
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
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(entry.month)")
                    .font(.system(size: 38, weight: .light))
                    .foregroundColor(.primary)
                Text(KKI18n.string(forKey: "月"))
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.primary)
            }
        }
    }

    private func statRow(_ label: String, value: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.secondary)
            Spacer()
            Text(formatPrice(value))
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.primary)
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
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(BookMonthTheme.brandGreen)
                .cornerRadius(4)
        }
    }
}
