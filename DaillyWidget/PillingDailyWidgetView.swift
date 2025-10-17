//
//  PillingDailyWidgetView.swift
//  DaillyWidgetExtension
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import SwiftUI
import WidgetKit

// MARK: - PillingDailyWidgetView

struct PillingDailyWidgetView: View {
    let entry: PillingDailyWidgetEntry
    
    var body: some View {
        
        VStack(spacing: 8) {
            // 상단 아이콘
            Image(entry.displayData.iconImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
            
            // N일차
            if entry.displayData.cycleDay > 0 {
                Text("\(entry.displayData.cycleDay)일차")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // 메시지
            Text(entry.displayData.message)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Spacer()
        }
        .containerBackground(for: .widget) {
            Image(entry.displayData.backgroundImageName)
                .resizable()
                .scaledToFill()
        }
        .widgetURL(URL(string: "pillingapp://widget"))
        Spacer()
    }
}

// MARK: - Preview Provider

#Preview("잔디를 심어보세요 - Small", as: .systemSmall) {
    DaillyWidget()
} timeline: {
    PillingDailyWidgetEntry(
        date: Date(),
        displayData: WidgetDisplayData(
            cycleDay: 3,
            message: "잔디를 심어보세요!",
            iconImageName: "widget_icon_plant",
            backgroundImageName: "widget_background_normal"
        )
    )
}

#Preview("잔디가 기다려요 - Small", as: .systemSmall) {
    DaillyWidget()
} timeline: {
    PillingDailyWidgetEntry(
        date: Date(),
        displayData: WidgetDisplayData(
            cycleDay: 5,
            message: "잔디가 기다려요",
            iconImageName: "widget_icon_waiting",
            backgroundImageName: "widget_background_warning"
        )
    )
}

#Preview("잔디 심기 완료 - Small", as: .systemSmall) {
    DaillyWidget()
} timeline: {
    PillingDailyWidgetEntry(
        date: Date(),
        displayData: WidgetDisplayData(
            cycleDay: 10,
            message: "잔디 심기 완료",
            iconImageName: "widget_icon_completed",
            backgroundImageName: "widget_background_normal"
        )
    )
}

#Preview("지금은 쉬는 시간 - Small", as: .systemSmall) {
    DaillyWidget()
} timeline: {
    PillingDailyWidgetEntry(
        date: Date(),
        displayData: WidgetDisplayData(
            cycleDay: 25,
            message: "지금은 쉬는 시간",
            iconImageName: "widget_icon_rest",
            backgroundImageName: "widget_background_normal"
        )
    )
}

#Preview("잔디를 심어보세요 - Medium", as: .systemMedium) {
    DaillyWidget()
} timeline: {
    PillingDailyWidgetEntry(
        date: Date(),
        displayData: WidgetDisplayData(
            cycleDay: 7,
            message: "잔디를 심어보세요!",
            iconImageName: "widget_icon_plant",
            backgroundImageName: "widget_background_normal"
        )
    )
}

#Preview("잔디가 기다려요 - Medium", as: .systemMedium) {
    DaillyWidget()
} timeline: {
    PillingDailyWidgetEntry(
        date: Date(),
        displayData: WidgetDisplayData(
            cycleDay: 12,
            message: "잔디가 기다려요",
            iconImageName: "widget_icon_waiting",
            backgroundImageName: "widget_background_warning"
        )
    )
}

#Preview("잔디 심기 완료 - Large", as: .systemLarge) {
    DaillyWidget()
} timeline: {
    PillingDailyWidgetEntry(
        date: Date(),
        displayData: WidgetDisplayData(
            cycleDay: 15,
            message: "잔디 심기 완료",
            iconImageName: "widget_icon_completed",
            backgroundImageName: "widget_background_normal"
        )
    )
}
