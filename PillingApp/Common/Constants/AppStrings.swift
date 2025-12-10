import Foundation

enum AppStrings{

    enum Common{
        static let alertTitle = "common.alert_title".localized
        static let okBtnTitle = "common.ok_button".localized
        static let errorTitle = "common.error_title".localized
        static let cancelTitle = "common.cancel_title".localized
        static let confirmTitle = "common.confirm_title".localized
    }
    
    enum PillSetting{
        static let mainTitle = "pill_setting.main_title".localized
        static let subtitle = "pill_setting.subtitle".localized
        static let btnTitle = "pill_setting.button_title".localized
        static let ctnBtnTitle = "pill_setting.start_date_button".localized
        static let nextBtnTitle = "pill_setting.next_button".localized
        static let navTitle = "pill_setting.nav_title".localized
        static let nameTitle = "pill_setting.name_title".localized
        static let takingDays = "pill_setting.taking_days".localized
        static let takingBtn = "pill_setting.taking_button".localized
        static let breakLabel = "pill_setting.break_label".localized
        static let breakDay = "pill_setting.break_day".localized
        static let warningLabel = "pill_setting.warning_label".localized
        static let settingComplete = "pill_setting.setting_complete".localized
        static let titleLabel = "pill_setting.title_label".localized
    }
    enum SettingFloating{
        static let titleLabel = "setting_floating.title".localized
        static let subTitleLabel = "setting_floating.subtitle".localized
    }
    
    enum Setting{
        static let sectionLabel = "setting.section_label".localized
        static let newPillBtn = "setting.new_pill_button".localized
        static let navigationTitle = "setting.navigation_title".localized
        static let alarmSectionTitle = "setting.alarm_section_title".localized

        static let timeSettingTitle = "setting.time_setting_title".localized
        static let timeSettingDefault = "setting.time_setting_default".localized

        static let messageSettingTitle = "setting.message_setting_title".localized
        static let messageSettingDefault = "setting.message_setting_default".localized

        static let messageEditorTitle = "setting.message_editor_title".localized
        static let messageEditorDescription = "setting.message_editor_description".localized
        static let messageEditorPlaceholder = "setting.message_editor_placeholder".localized

        static let newPillCycleTitle = "setting.new_pill_cycle_title".localized
        static let newPillCycleMessage = "setting.new_pill_cycle_message".localized
        static let newPillCycleConfirm = "setting.new_pill_cycle_confirm".localized

        static let successTimeUpdated = "setting.success_time_updated".localized
        static let successMessageUpdated = "setting.success_message_updated".localized
        static let errorTimeUpdateFailed = "setting.error_time_update_failed".localized
        static let errorMessageUpdateFailed = "setting.error_message_update_failed".localized
        static let errorResetFailed = "setting.error_reset_failed".localized

        static let permissionErrorGoToSettings = "setting.permission_error_go_to_settings".localized

    }
    enum Dashboard {
        static let guideTitle = "dashboard.guide_title".localized
        static let guideSubtitle = "dashboard.guide_subtitle".localized
        static let guideConfirmButton = "dashboard.guide_confirm_button".localized

        static let guideTaken = "dashboard.guide_taken".localized
        static let guideTakenDouble = "dashboard.guide_taken_double".localized
        static let guideMissed = "dashboard.guide_missed".localized
        static let taken = "dashboard.taken".localized
        static let takenDouble = "dashboard.taken_double".localized
        static let guideToday = "dashboard.guide_today".localized

        static let takePillButton = "dashboard.take_pill_button".localized
        static let takePillCompleted = "dashboard.take_pill_completed".localized
        static let restPeriod = "dashboard.rest_period".localized

        static let weekdays = [
            "dashboard.weekday_mon".localized,
            "dashboard.weekday_tue".localized,
            "dashboard.weekday_wed".localized,
            "dashboard.weekday_thu".localized,
            "dashboard.weekday_fri".localized,
            "dashboard.weekday_sat".localized,
            "dashboard.weekday_sun".localized
        ]
    }

    enum Widget {
        static let configurationDisplayName = "widget.configuration_display_name".localized
        static let configurationDescription = "widget.configuration_description".localized
        static let messagePlantGrass = "widget.message_plant_grass".localized
        static let messageSetupPill = "widget.message_setup_pill".localized
        static let messageGrassWaiting = "widget.message_grass_waiting".localized
        static let messageOnePillComplete = "widget.message_one_pill_complete".localized
        static let messageRestTime = "widget.message_rest_time".localized
        static let messageTwoToday = "widget.message_two_today".localized
        static let messageTodayComplete = "widget.message_today_complete".localized
    }

    enum History {
        static let navigationTitle = "history.navigation_title".localized
        static let detailTitle = "history.detail_title".localized
        static let emptyMessage = "history.empty_message".localized
        static let startLabel = "history.start_label".localized
        static let createdLabel = "history.created_label".localized
        static func activeDaysFormat(_ days: Int) -> String {
            return "history.active_days_format".localized(with: days)
        }
        static func breakDaysFormat(_ days: Int) -> String {
            return "history.break_days_format".localized(with: days)
        }
        static let scheduledTimeLabel = "history.scheduled_time_label".localized
        static func cellMetaFormat(activeDays: Int, breakDays: Int, time: String) -> String {
            return "history.cell_meta_format".localized(with: activeDays, breakDays, time)
        }
    }

    enum Statistics {
        static let myRecordTitle = "statistics.my_record_title".localized
        static let takingPillLabel = "statistics.taking_pill_label".localized
        static let chartTitle = "statistics.chart_title".localized
        static let periodSelectionTitle = "statistics.period_selection_title".localized
    }

    enum Message {
        // 기본 메시지
        static let setupRequired = "message.setup_required".localized
        static let restPeriod = "message.rest_period".localized
        static let forgotMe = "message.forgot_me".localized
        static let plantTodayGrass = "message.plant_today_grass".localized
        static let plantSteadily = "message.plant_steadily".localized
        static let pillingSearching = "message.pilling_searching".localized
        static let pillingAngry = "message.pilling_angry".localized
        static let takeTwoPills = "message.take_two_pills".localized
        static let grassGrowingWell = "message.grass_growing_well".localized
        static let missedYesterdayTakeTwo = "message.missed_yesterday_take_two".localized
        static let takeWithinTwoHours = "message.take_within_two_hours".localized
        static let needOnePillMore = "message.need_one_pill_more".localized
        static let tookTooEarly = "message.took_too_early".localized
        static let seeTomorrow = "message.see_tomorrow".localized
        static let startTakingToday = "message.start_taking_today".localized
        static let startTakingTomorrow = "message.start_taking_tomorrow".localized
        static func daysUntilStart(_ days: Int) -> String {
            return "message.days_until_start".localized(with: days)
        }
        static let onePillMore = "message.one_pill_more".localized

        // 위젯용 메시지
        static let widgetPlantGrass = "message.widget_plant_grass".localized
        static let widgetPlantingComplete = "message.widget_planting_complete".localized
        static let widgetGrassWaiting = "message.widget_grass_waiting".localized
        static let widgetRestTime = "message.widget_rest_time".localized
    }

    enum Error {
        static let invalidTimeFormat = "error.invalid_time_format".localized
        static let invalidDateRange = "error.invalid_date_range".localized
        static let unknownError = "error.unknown_error".localized
        static let permissionError = "error.permission_error".localized
        static let notificationPermissionTitle = "error.notification_permission_title".localized
    }

    enum TimeSetting {
        static let mainTitle = "time_setting.main_title".localized
        static let subtitle = "time_setting.subtitle".localized
        static let timeButtonTitle = "time_setting.time_button_title".localized
        static let confirmButton = "time_setting.confirm_button".localized
        static let pickerConfirmButton = "time_setting.picker_confirm_button".localized
        static let navigationTitle = "time_setting.navigation_title".localized
    }
}
