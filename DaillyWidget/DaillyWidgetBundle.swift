//
//  DaillyWidgetBundle.swift
//  DaillyWidget
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import WidgetKit
import SwiftUI

@main
struct DaillyWidgetBundle: WidgetBundle {
    var body: some Widget {
        DaillyWidget()
        DaillyWidgetControl()
    }
}
