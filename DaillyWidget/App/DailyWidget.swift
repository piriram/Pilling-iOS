import WidgetKit
import SwiftUI

// MARK: - DaillyWidget

struct DaillyWidget: Widget {
    let kind: String = "DaillyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyWidgetProvider()) { entry in
            DailyWidgetView(entry: entry)
                .environment(\.colorScheme, .light)
        }
        .configurationDisplayName("약 복용 위젯")
        .description("오늘의 복용 상태를 확인하세요")
        .supportedFamilies([.systemSmall])
    }
}
