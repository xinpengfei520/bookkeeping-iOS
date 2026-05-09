//
//  WidgetReloader.swift
//  bookkeeping
//
//  WidgetCenter is a Swift-only API. This thin @objc shim lets the
//  Objective-C code base trigger widget timeline reloads after
//  language / theme changes — without it the BookMonth widget would
//  only pick up the new state at its next natural refresh tick
//  (≈30 min) or after a force-remove + re-add.
//

import Foundation
import WidgetKit

@objc(WidgetReloader)
public final class WidgetReloader: NSObject {

    /// Force WidgetKit to fetch fresh timeline entries from every
    /// installed widget the next runloop tick. iOS 14+; no-op below.
    @objc public static func reloadAllTimelines() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
