//
//  Strings.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/27/25.
//

import Foundation

enum Strings {
    enum PillSetting {
        static let navigationTitle = "약 설정"
        static let mainTitle = "복용하고 계신 약을 알려주세요!"
        static let subtitle = "설정은 추후에 변경가능합니다."
        static let pillTypeButtonTitle = "약 종류"
        static let startDateButtonTitle = "복용 시작 날짜"
        static let nextButtonTitle = "다음으로"
        static let alertTitle = "알림"
        static let alertConfirm = "확인"
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
}
