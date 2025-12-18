import WidgetKit

import WidgetKit
import SwiftUI

// MARK: - PillingDailyWidgetEntry

struct DailyWidgetEntry: TimelineEntry {
    let date: Date
    let displayData: WidgetDisplayData
    
    static var placeholder: DailyWidgetEntry {
        DailyWidgetEntry(
            date: Date(),
            displayData: WidgetDisplayData(
                cycleDay: 1,
                message: NSLocalizedString("widget.message_plant_grass", bundle: .main, comment: ""),
                iconImageName: "widget_icon_plant",
                backgroundImageName: "widget_background_normal"
            )
        )
    }

    static var empty: DailyWidgetEntry {
        DailyWidgetEntry(
            date: Date(),
            displayData: WidgetDisplayData(
                cycleDay: 0,
                message: NSLocalizedString("widget.message_setup_pill", bundle: .main, comment: ""),
                iconImageName: "widget_icon_rest",
                backgroundImageName: "widget_background_normal"
            )
        )
    }
}



