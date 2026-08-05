//
//  BookIntents.swift
//  bookkeeping
//
//  Siri / 快捷指令「记一笔」——iOS 16+ 的 AppIntents，直接内嵌在主 target
//  （无需 extension，免费开发者账号可用）。
//
//  落库策略：走与离线记账完全相同的管线 —— 本地 SQLite 先落一笔（临时
//  bookId），同时入 PIN_BOOK_FAILED 离线队列；下次打开 App 时
//  HomeController.replayPendingBookOps 自动补发到服务端并换成正式 id。
//  好处：不用在 intent 进程里做网络 + 登录态处理，弱网/未登录一样能记。
//

import AppIntents
import Foundation

@available(iOS 16.0, *)
struct AddBookEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "记一笔"
    static var description = IntentDescription("快速记一笔账到记呀，打开 App 后自动同步到云端")
    // 后台静默执行，不拉起 App
    static var openAppWhenRun: Bool = false

    @Parameter(title: "金额", requestValueDialog: "记多少钱？")
    var amount: Double

    @Parameter(title: "类别", requestValueDialog: "记到哪个类别？")
    var category: String?

    @Parameter(title: "备注")
    var mark: String?

    static var parameterSummary: some ParameterSummary {
        Summary("记一笔 \(\.$amount) 元") {
            \.$category
            \.$mark
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let price = (amount * 100).rounded() / 100
        guard price > 0 else {
            return .result(dialog: "金额要大于 0 才能记账")
        }

        // 类别：按名称在本地类别表里精确匹配（支出优先），匹配不到用第一个支出类别兜底
        let categories = (UserDefaults.getCategoryModelList() as? [BKCModel]) ?? []
        let wanted = category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let matched = categories.first { $0.name == wanted && !wanted.isEmpty }
            ?? categories.first { !$0.is_income }
            ?? categories.first
        guard let cmodel = matched else {
            return .result(dialog: "还没有可用的记账类别，请先打开记呀完成初始化")
        }

        let now = Date()
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: now)

        let model = BookDetailModel()
        model.bookId = Int(truncating: BookDetailModel.getBookId())      // 临时 id，补发成功后换服务端 id
        model.categoryId = cmodel.id
        model.price = price
        model.year = parts.year ?? 0
        model.month = parts.month ?? 0
        model.day = parts.day ?? 0
        let trimmedMark = mark?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        model.mark = trimmedMark.isEmpty ? cmodel.name : trimmedMark

        // 本地 SQLite 落库 + 入离线队列（下次打开 App 自动补发到服务端）
        UserDefaults.insertBook(model)
        UserDefaults.enqueuePendingAdd(model)
        // 小组件立刻反映新账单
        WidgetReloader.reloadAllTimelines()

        // 向系统捐赠本次执行：Siri 会逐步提高本 App 在"记一笔/记账"类口令上的
        // 匹配权重（模板短语是模糊匹配，容易被同类 App 抢走，捐赠是官方的纠偏手段）
        _ = try? await IntentDonationManager.shared.donate(intent: self)

        let priceText = String(format: "%.2f", price)
        return .result(dialog: "已记一笔\(cmodel.name) ¥\(priceText)，打开记呀后自动同步")
    }
}

@available(iOS 16.0, *)
struct BookAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddBookEntryIntent(),
            // 模板短语是模糊匹配："记一笔/记账"是高频词，容易被其它记账 App 抢走。
            // 多给变体（App 名在句首/句中、独特后缀"快记"）提高命中率；
            // 真正 100% 可靠的触发是用户在快捷指令 App 里包一层自命名指令
            // （SiriShortcutsController 里有指引入口）。
            phrases: [
                "用\(.applicationName)记一笔",
                "\(.applicationName)记一笔",
                "\(.applicationName)记账",
                "用\(.applicationName)记账",
                "\(.applicationName)记个账",
                "\(.applicationName)快记",
                "在\(.applicationName)记一笔",
                "在\(.applicationName)里记一笔账",
            ],
            shortTitle: "记一笔",
            systemImageName: "plus.circle.fill"
        )
    }
}

/// 供 ObjC 侧（AppDelegate）在启动时刷新 App Shortcuts 注册。
/// 短语列表变更后老安装不会自动更新，显式刷一次保证生效。
@objc(KKAppShortcutsRefresher)
public final class KKAppShortcutsRefresher: NSObject {
    @objc public static func refresh() {
        if #available(iOS 16.0, *) {
            BookAppShortcuts.updateAppShortcutParameters()
        }
    }
}
