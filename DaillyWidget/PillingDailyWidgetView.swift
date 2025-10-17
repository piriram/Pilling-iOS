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
        ZStack {
            // 배경 이미지
            Image(entry.displayData.backgroundImageName)
                .resizable()
                .scaledToFill()
            
            VStack(spacing: 8) {
                // 상단 아이콘
                Image(entry.displayData.iconImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                Spacer()
                
                // N일차
                if entry.displayData.cycleDay > 0 {
                    Text("\(entry.displayData.cycleDay)일차")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                // 메시지
                Text(entry.displayData.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(16)
        }
        .widgetURL(URL(string: "pillingapp://widget"))
    }
}

// MARK: - Preview

struct PillingDailyWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PillingDailyWidgetView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Placeholder")
            
            PillingDailyWidgetView(
                entry: PillingDailyWidgetEntry(
                    date: Date(),
                    displayData: WidgetDisplayData(
                        cycleDay: 5,
                        message: "잔디가 기다려요",
                        iconImageName: "widget_icon_waiting",
                        backgroundImageName: "widget_background_warning"
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Waiting")
            
            PillingDailyWidgetView(
                entry: PillingDailyWidgetEntry(
                    date: Date(),
                    displayData: WidgetDisplayData(
                        cycleDay: 10,
                        message: "잔디 심기 완료",
                        iconImageName: "widget_icon_completed",
                        backgroundImageName: "widget_background_normal"
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Completed")
        }
    }
}
