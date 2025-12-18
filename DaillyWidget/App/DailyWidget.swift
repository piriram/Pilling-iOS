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
        .configurationDisplayName("widget.configuration_display_name")
        .description("widget.configuration_description")
        .supportedFamilies([.systemSmall])
    }
}
