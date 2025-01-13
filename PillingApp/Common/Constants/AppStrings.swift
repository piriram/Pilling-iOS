import Foundation

enum AppStrings{
    
    enum Common{
        static let alertTitle = "알림"
        static let okBtnTitle = "확인"
        static let errorTitle = "오류"
        static let cancelTitle = "취소"
        static let confirmTitle = "완료"
    }
    
    enum PillSetting{
        static let mainTitle = "복용하고 계신 약을 알려주세요!"
        static let subtitle = "설정은 추후에 변경가능합니다."
        static let btnTitle = "약 종류"
        static let ctnBtnTitle = "복용 시작 날짜"
        static let nextBtnTitle = "다음으로"
        static let navTitle = "약 설정"
        static let nameTitle = "약 이름 (선택 사항)"
        static let takingDays = "복용일"
        static let takingBtn = "24일"
        static let breakLabel = "휴약일"
        static let breakDay = "4일"
        static let warningLabel = "복용일과 휴약일의 합은 28일 이하여야 해요."
        static let settingComplete = "설정 완료"
        static let titleLabel = "복용 정보 입력"
    }
    enum SettingFloating{
        static let titleLabel = "설정 완료!"
        static let subTitleLabel = "매일 알림을 보내드릴게요"
    }
    
    enum Setting{
        static let sectionLabel = "약 설정"
        static let newPillBtn = "새 약 복용 시작하기"
        static let navigationTitle = "설정"
        static let alarmSectionTitle = "알림 설정"
        
        static let timeSettingTitle = "복용 시간"
        static let timeSettingDefault = "오전 9:00"
        
        static let messageSettingTitle = "알림 메시지"
        static let messageSettingDefault = "건강한 하루를 위해..."
        
        static let messageEditorTitle = "알림 메시지 수정"
        static let messageEditorDescription = "받고 싶은 알림 메시지를 입력해주세요"
        static let messageEditorPlaceholder = "알림 메시지 입력"
        
        static let newPillCycleTitle = "새 약 복용 시작"
        static let newPillCycleMessage = "현재 기록된 복용 정보가 모두 삭제됩니다.\n정말로 새로운 약 복용을 시작하시겠습니까?"
        static let newPillCycleConfirm = "시작하기"
        
        static let successTimeUpdated = "복용 시간이 변경되었습니다"
        static let successMessageUpdated = "알림 메시지가 변경되었습니다"
        static let errorTimeUpdateFailed = "시간 변경에 실패했습니다"
        static let errorMessageUpdateFailed = "메시지 변경에 실패했습니다"
        static let errorResetFailed = "초기화에 실패했습니다"
        
        static let permissionErrorGoToSettings = "설정으로 이동"
        
    }
    enum Dashboard {
        static let guideTitle = "필링 가이드"
        static let guideSubtitle = "피임약 복용 상태를 잔디로 알려드려요!"
        static let guideConfirmButton = "확인"
        
        static let guideTaken = "피임약 복용"
        static let guideTakenDouble = "피임약 2알 복용"
        static let guideMissed = "미복용"
        static let taken = "복용"
        static let takenDouble = "2알 복용"
        static let guideToday = "현재"
        
        static let takePillButton = "잔디 심기"
        static let takePillCompleted = "심기 완료!"
        static let restPeriod = "휴약 기간"
        
        static let weekdays = ["월", "화", "수", "목", "금", "토", "일"]
    }
}
