//
//  PillingDailyWidgetEntry.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import WidgetKit

import WidgetKit
import SwiftUI

// MARK: - PillingDailyWidgetEntry

struct PillingDailyWidgetEntry: TimelineEntry {
    let date: Date
    let displayData: WidgetDisplayData
    
    static var placeholder: PillingDailyWidgetEntry {
        PillingDailyWidgetEntry(
            date: Date(),
            displayData: WidgetDisplayData(
                cycleDay: 1,
                message: "잔디를 심어보세요!",
                iconImageName: "widget_icon_plant",
                backgroundImageName: "widget_background_normal"
            )
        )
    }
    
    static var empty: PillingDailyWidgetEntry {
        PillingDailyWidgetEntry(
            date: Date(),
            displayData: WidgetDisplayData(
                cycleDay: 0,
                message: "...",
                iconImageName: "widget_icon_rest",
                backgroundImageName: "widget_background_normal"
            )
        )
    }
}



