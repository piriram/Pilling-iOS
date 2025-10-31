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
        
        VStack(spacing: 4) {
            // 상단 아이콘
            Image(entry.displayData.iconImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
            
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
                .minimumScaleFactor(0.5)
            
        }
        .containerBackground(for: .widget) {
            Image(entry.displayData.backgroundImageName)
                .resizable()
                .scaledToFill()
        }
        .widgetURL(URL(string: "pillingapp://widget"))
        
    }
}
