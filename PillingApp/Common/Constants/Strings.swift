//
//  Strings.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/27/25.
//

import Foundation

enum Strings {
    enum PillSetting {
        static let navigationTitle = NSLocalizedString("pill_setting.navigation_title", comment: "네비게이션 타이틀")
        static let mainTitle = NSLocalizedString("pill_setting.main_title", comment: "메인 타이틀")
        static let subtitle = NSLocalizedString("pill_setting.subtitle", comment: "서브 타이틀")
        static let pillTypeButtonTitle = NSLocalizedString("pill_setting.pill_type_button_title", comment: "약 종류 버튼")
        static let startDateButtonTitle = NSLocalizedString("pill_setting.start_date_button_title", comment: "시작 날짜 버튼")
        static let nextButtonTitle = NSLocalizedString("pill_setting.next_button_title", comment: "다음 버튼")
        static let alertTitle = NSLocalizedString("pill_setting.alert_title", comment: "알림 타이틀")
        static let alertConfirm = NSLocalizedString("pill_setting.alert_confirm", comment: "확인 버튼")
    }
    
    enum TimeSetting {
        static let navigationTitle = NSLocalizedString("time_setting.navigation_title", comment: "네비게이션 타이틀")
        static let title = NSLocalizedString("time_setting.title", comment: "타이틀")
        static let subtitle = NSLocalizedString("time_setting.subtitle", comment: "서브 타이틀")
        static let timeButtonTitle = NSLocalizedString("time_setting.time_button_title", comment: "복용 시간 버튼")
        static let completeButtonTitle = NSLocalizedString("time_setting.complete_button_title", comment: "완료 버튼")
        static let errorAlertTitle = NSLocalizedString("time_setting.error_alert_title", comment: "에러 알림 타이틀")
        static let alertConfirm = NSLocalizedString("time_setting.alert_confirm", comment: "확인 버튼")
        static let settingsAction = NSLocalizedString("time_setting.settings_action", comment: "설정으로 이동 버튼")
    }
    
    
    enum PillTypeBottomSheet {
        static let title = NSLocalizedString("pill_type_bottom_sheet.title", comment: "타이틀")
        static let pillNamePlaceholder = NSLocalizedString("pill_type_bottom_sheet.pill_name_placeholder", comment: "약 이름 플레이스홀더")
        static let takingDaysLabel = NSLocalizedString("pill_type_bottom_sheet.taking_days_label", comment: "복용일 레이블")
        static let breakDaysLabel = NSLocalizedString("pill_type_bottom_sheet.break_days_label", comment: "휴약일 레이블")
        static let warningMessage = NSLocalizedString("pill_type_bottom_sheet.warning_message", comment: "경고 메시지")
        static let confirmButton = NSLocalizedString("pill_type_bottom_sheet.confirm_button", comment: "확인 버튼")
        static let pickerDone = NSLocalizedString("pill_type_bottom_sheet.picker_done", comment: "피커 완료")
        static let pickerCancel = NSLocalizedString("pill_type_bottom_sheet.picker_cancel", comment: "피커 취소")
        static func daysFormat(_ days: Int) -> String {
            return String(format: NSLocalizedString("pill_type_bottom_sheet.days_format", comment: "일수 포맷"), days)
        }
    }
    
}
