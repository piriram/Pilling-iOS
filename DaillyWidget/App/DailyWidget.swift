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
        .configurationDisplayName(NSLocalizedString("widget.configuration_display_name", bundle: .main, comment: ""))
        .description(NSLocalizedString("widget.configuration_description", bundle: .main, comment: ""))
        .supportedFamilies([.systemSmall])
    }
}
