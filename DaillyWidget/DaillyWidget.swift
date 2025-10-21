//
//  DaillyWidget.swift
//  DaillyWidget
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import WidgetKit
import SwiftUI

// MARK: - DaillyWidget

struct DaillyWidget: Widget {
    let kind: String = "DaillyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PillingDailyWidgetProvider()) { entry in
            PillingDailyWidgetView(entry: entry)
        }
        .configurationDisplayName("피임약 복용 위젯")
        .description("오늘의 복용 상태를 확인하세요")
        .supportedFamilies([.systemSmall])
    }
}

