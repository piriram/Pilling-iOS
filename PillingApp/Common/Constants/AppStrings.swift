//
//  AppStrings.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/3/25.
//

import Foundation

enum AppStrings{

    enum Common{
        static let alertTitle = NSLocalizedString("Common.alertTitle", comment: "")
        static let okBtnTitle = NSLocalizedString("Common.okBtnTitle", comment: "")
        static let errorTitle = NSLocalizedString("Common.errorTitle", comment: "")
        static let cancelTitle = NSLocalizedString("Common.cancelTitle", comment: "")
        static let confirmTitle = NSLocalizedString("Common.confirmTitle", comment: "")
    }

    enum PillSetting{
        static let mainTitle = NSLocalizedString("PillSetting.mainTitle", comment: "")
        static let subtitle = NSLocalizedString("PillSetting.subtitle", comment: "")
        static let btnTitle = NSLocalizedString("PillSetting.btnTitle", comment: "")
        static let ctnBtnTitle = NSLocalizedString("PillSetting.ctnBtnTitle", comment: "")
        static let nextBtnTitle = NSLocalizedString("PillSetting.nextBtnTitle", comment: "")
        static let navTitle = NSLocalizedString("PillSetting.navTitle", comment: "")
        static let nameTitle = NSLocalizedString("PillSetting.nameTitle", comment: "")
        static let takingDays = NSLocalizedString("PillSetting.takingDays", comment: "")
        static let takingBtn = NSLocalizedString("PillSetting.takingBtn", comment: "")
        static let breakLabel = NSLocalizedString("PillSetting.breakLabel", comment: "")
        static let breakDay = NSLocalizedString("PillSetting.breakDay", comment: "")
        static let warningLabel = NSLocalizedString("PillSetting.warningLabel", comment: "")
        static let settingComplete = NSLocalizedString("PillSetting.settingComplete", comment: "")
        static let titleLabel = NSLocalizedString("PillSetting.titleLabel", comment: "")
    }
    enum SettingFloating{
        static let titleLabel = NSLocalizedString("SettingFloating.titleLabel", comment: "")
        static let subTitleLabel = NSLocalizedString("SettingFloating.subTitleLabel", comment: "")
    }

    enum Setting{
        static let sectionLabel = NSLocalizedString("Setting.sectionLabel", comment: "")
        static let newPillBtn = NSLocalizedString("Setting.newPillBtn", comment: "")
        static let navigationTitle = NSLocalizedString("Setting.navigationTitle", comment: "")
        static let alarmSectionTitle = NSLocalizedString("Setting.alarmSectionTitle", comment: "")

        static let timeSettingTitle = NSLocalizedString("Setting.timeSettingTitle", comment: "")
        static let timeSettingDefault = NSLocalizedString("Setting.timeSettingDefault", comment: "")

        static let messageSettingTitle = NSLocalizedString("Setting.messageSettingTitle", comment: "")
        static let messageSettingDefault = NSLocalizedString("Setting.messageSettingDefault", comment: "")

        static let messageEditorTitle = NSLocalizedString("Setting.messageEditorTitle", comment: "")
        static let messageEditorDescription = NSLocalizedString("Setting.messageEditorDescription", comment: "")
        static let messageEditorPlaceholder = NSLocalizedString("Setting.messageEditorPlaceholder", comment: "")

        static let newPillCycleTitle = NSLocalizedString("Setting.newPillCycleTitle", comment: "")
        static let newPillCycleMessage = NSLocalizedString("Setting.newPillCycleMessage", comment: "")
        static let newPillCycleConfirm = NSLocalizedString("Setting.newPillCycleConfirm", comment: "")

        static let successTimeUpdated = NSLocalizedString("Setting.successTimeUpdated", comment: "")
        static let successMessageUpdated = NSLocalizedString("Setting.successMessageUpdated", comment: "")
        static let errorTimeUpdateFailed = NSLocalizedString("Setting.errorTimeUpdateFailed", comment: "")
        static let errorMessageUpdateFailed = NSLocalizedString("Setting.errorMessageUpdateFailed", comment: "")
        static let errorResetFailed = NSLocalizedString("Setting.errorResetFailed", comment: "")

        static let permissionErrorGoToSettings = NSLocalizedString("Setting.permissionErrorGoToSettings", comment: "")

    }
    enum Dashboard {
        static let guideTitle = NSLocalizedString("Dashboard.guideTitle", comment: "")
        static let guideSubtitle = NSLocalizedString("Dashboard.guideSubtitle", comment: "")
        static let guideConfirmButton = NSLocalizedString("Dashboard.guideConfirmButton", comment: "")

        static let guideTaken = NSLocalizedString("Dashboard.guideTaken", comment: "")
        static let guideTakenDouble = NSLocalizedString("Dashboard.guideTakenDouble", comment: "")
        static let guideMissed = NSLocalizedString("Dashboard.guideMissed", comment: "")
        static let taken = NSLocalizedString("Dashboard.taken", comment: "")
        static let takenDouble = NSLocalizedString("Dashboard.takenDouble", comment: "")
        static let guideToday = NSLocalizedString("Dashboard.guideToday", comment: "")

        static let takePillButton = NSLocalizedString("Dashboard.takePillButton", comment: "")
        static let takePillCompleted = NSLocalizedString("Dashboard.takePillCompleted", comment: "")
        static let restPeriod = NSLocalizedString("Dashboard.restPeriod", comment: "")

        static let weekdays = [
            NSLocalizedString("Dashboard.monday", comment: ""),
            NSLocalizedString("Dashboard.tuesday", comment: ""),
            NSLocalizedString("Dashboard.wednesday", comment: ""),
            NSLocalizedString("Dashboard.thursday", comment: ""),
            NSLocalizedString("Dashboard.friday", comment: ""),
            NSLocalizedString("Dashboard.saturday", comment: ""),
            NSLocalizedString("Dashboard.sunday", comment: "")
        ]
    }
}
