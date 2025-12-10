# GA & 로컬라이제이션 사용 가이드

## GA (Google Analytics) 사용법

### 1. 현재 상태
- **개발 환경**: 콘솔에만 로그 출력 (ConsoleAnalyticsService)
- **프로덕션**: Firebase 연동 준비 완료 (설치 후 자동 활성화)

### 2. 새로운 이벤트 추가하기

#### Step 1: AnalyticsEvent.swift에 이벤트 추가
```swift
// PillingApp/Domain/Entity/AnalyticsEvent.swift

enum AnalyticsEvent {
    // 기존 이벤트...

    // 새로운 이벤트 추가
    case newFeatureUsed(featureName: String)

    var name: String {
        switch self {
        // 기존 케이스...
        case .newFeatureUsed:
            return "new_feature_used"
        }
    }

    var parameters: [String: Any] {
        switch self {
        // 기존 케이스...
        case .newFeatureUsed(let featureName):
            return ["feature_name": featureName]
        }
    }
}
```

#### Step 2: UseCase에서 사용
```swift
// 어떤 UseCase든 analytics를 주입받아 사용
final class SomeUseCase {
    private let analytics: AnalyticsServiceProtocol?

    init(analytics: AnalyticsServiceProtocol? = nil) {
        self.analytics = analytics
    }

    func execute() {
        // 비즈니스 로직 실행 후
        analytics?.logEvent(.newFeatureUsed(featureName: "awesome_feature"))
    }
}
```

### 3. Firebase 연동하기 (선택사항)

#### Step 1: Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 생성
3. iOS 앱 등록
4. `GoogleService-Info.plist` 다운로드

#### Step 2: 프로젝트에 추가
1. `GoogleService-Info.plist`를 Xcode 프로젝트에 드래그
2. Package Dependencies에 Firebase SDK 추가:
   - File → Add Package Dependencies
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Product: `FirebaseAnalytics` 선택

#### Step 3: AppDelegate 수정
```swift
import FirebaseCore

func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
    FirebaseApp.configure()  // 추가
    // 기존 코드...
}
```

#### Step 4: FirebaseAnalyticsService.swift 주석 해제
```swift
// 파일 상단 주석 해제
import FirebaseAnalytics

// logEvent 메서드 주석 해제
Analytics.logEvent(event.name, parameters: event.parameters)
```

### 4. 이벤트 확인하기

#### 개발 환경
Xcode 콘솔에 다음과 같이 출력됩니다:
```
📊 [Analytics] pill_taken
   Parameters: ["date": "2024-01-01T12:00:00Z", "status": "taken"]
```

#### Firebase Console
1. Firebase Console → Analytics → Events
2. 실시간으로 이벤트 확인 가능

---

## 로컬라이제이션 사용법

### 1. 기본 사용

```swift
// AppStrings를 통한 사용 (권장)
label.text = AppStrings.Dashboard.guideTitle  // 자동으로 현재 언어에 맞게 번역됨
button.setTitle(AppStrings.Common.confirmTitle, for: .normal)

// 직접 키를 사용하는 방법 (권장하지 않음)
let title = "dashboard.guide_title".localized  // "필링 가이드" 또는 "Pilling Guide"
```

### 2. 새로운 번역 추가하기

#### Step 1: Localizable.strings에 키 추가

**한국어 (ko.lproj/Localizable.strings)**
```
"feature.new_button" = "새로운 버튼";
```

**영어 (en.lproj/Localizable.strings)**
```
"feature.new_button" = "New Button";
```

#### Step 2: 코드에서 사용
```swift
label.text = "feature.new_button".localized
```

### 3. 파라미터가 있는 번역

#### 단일 파라미터
```swift
// AppStrings를 통한 사용 (권장)
let days = 5
let message = AppStrings.Message.daysUntilStart(days)  // "복용 시작까지 5일 남았어요" 또는 "5 days until start"
```

#### 복수 파라미터
```swift
// AppStrings를 통한 사용 (권장)
let metaText = AppStrings.History.cellMetaFormat(activeDays: 24, breakDays: 4, time: "09:00")
// "복용 24일 · 휴약 4일 · 예정시각 09:00" 또는 "24 days active · 4 days break · Scheduled 09:00"
```

#### 직접 키를 사용하는 방법 (권장하지 않음)
```swift
let count = 5
let message = "pill.count".localized(with: count)  // "5개의 약"

let time = "12:00"
let status = "pill.taken_at".localized(with: time)  // "12:00에 복용 완료"
```

### 4. 새로운 언어 추가하기

#### Step 1: Xcode에서 언어 추가
1. Project → Info → Localizations
2. `+` 버튼 클릭
3. 언어 선택 (예: 일본어)

#### Step 2: Localizable.strings 파일 생성
Xcode가 자동으로 `ja.lproj/Localizable.strings` 생성

#### Step 3: 번역 추가
```
"common.confirm" = "確認";
"dashboard.title" = "ダッシュボード";
```

### 5. 복수형 처리

복수형은 `.stringsdict` 파일에서 자동 처리됩니다:

```swift
// 영어: "1 day until start" vs "5 days until start"
// 한국어: "복용 시작까지 1일 남았어요" vs "복용 시작까지 5일 남았어요"
let message1 = AppStrings.Message.daysUntilStart(1)
let message5 = AppStrings.Message.daysUntilStart(5)
```

### 6. 유지보수 팁

#### 번역 키 네이밍 규칙
```
[화면명].[요소명]
예:
- dashboard.guide_title
- setting.navigation_title
- message.plant_today_grass
```

#### 새로운 문자열 추가하기
1. `AppStrings.swift`에 새로운 프로퍼티 추가
2. `ko.lproj/Localizable.strings`에 한국어 번역 추가
3. `en.lproj/Localizable.strings`에 영어 번역 추가
4. 복수형이 필요하면 `.stringsdict` 파일에도 추가

#### 번역 누락 확인
Xcode에서 빌드 시 자동으로 경고가 표시됩니다.

#### 번역 파일 정리
주기적으로 사용하지 않는 키를 삭제하세요.

---

## 전체 구조

```
PillingApp/
├── Domain/
│   ├── Protocol/
│   │   └── AnalyticsServiceProtocol.swift    # Analytics 인터페이스
│   └── Entity/
│       └── AnalyticsEvent.swift               # 이벤트 Enum (여기에 추가)
├── Infra/
│   ├── ConsoleAnalyticsService.swift          # 개발용 구현체
│   └── FirebaseAnalyticsService.swift         # 프로덕션 구현체
├── Resources/
│   ├── ko.lproj/
│   │   ├── Localizable.strings                # 한국어 번역
│   │   └── Localizable.stringsdict            # 한국어 복수형 처리
│   └── en.lproj/
│       ├── Localizable.strings                # 영어 번역
│       └── Localizable.stringsdict            # 영어 복수형 처리
└── Common/
    ├── Constants/
    │   └── AppStrings.swift                   # 중앙 집중식 문자열 관리 (자동 번역)
    └── Extension/
        └── String+Localized.swift             # 번역 헬퍼

```

---

## 구현 완료 사항

### GA (Google Analytics)
- ✅ Protocol 기반 아키텍처 (`AnalyticsServiceProtocol`)
- ✅ Enum 기반 이벤트 관리 (`AnalyticsEvent`)
- ✅ 개발/프로덕션 환경 자동 분리 (`ConsoleAnalyticsService`, `FirebaseAnalyticsService`)
- ✅ DI Container 통합
- ✅ UseCase에 Analytics 주입 (예: `TakePillUseCase`)

### 로컬라이제이션
- ✅ 한국어/영어 번역 파일 (`Localizable.strings`)
- ✅ 복수형 처리 (`Localizable.stringsdict`)
- ✅ AppStrings 중앙 집중화 (모든 하드코딩된 문자열 수집)
- ✅ AppStrings의 자동 번역 적용 (`.localized` 사용)
- ✅ String Extension 헬퍼 (`String+Localized.swift`)
- ✅ 파라미터가 있는 번역 지원

### 사용 가능한 문자열 카테고리
- Common (공통: 확인, 취소, 완료 등)
- PillSetting (약 설정)
- SettingFloating (설정 완료 플로팅)
- Setting (설정 화면)
- Dashboard (대시보드)
- Widget (위젯)
- History (히스토리)
- Statistics (통계)
- Message (앱 메시지 - 20+ 가지)
- Error (에러 메시지)
- TimeSetting (시간 설정)

---

## 자주 묻는 질문

### Q1. GA 이벤트를 언제 추가하나요?
**A.** 사용자 행동을 추적하고 싶을 때마다 AnalyticsEvent에 새로운 case를 추가하세요.

### Q2. 번역이 안 나타나요.
**A.**
1. Localizable.strings에 키가 있는지 확인
2. 빌드 클린 후 재빌드
3. 시뮬레이터 언어 설정 확인

### Q3. Firebase 없이 GA만 사용할 수 있나요?
**A.** 네, 개발 환경에서는 ConsoleAnalyticsService가 자동으로 사용됩니다.

### Q4. 이벤트를 삭제하고 싶어요.
**A.**
1. AnalyticsEvent.swift에서 해당 case 제거
2. 사용하는 곳에서 호출 제거
3. 컴파일 에러 확인

### Q5. 언어별로 다른 레이아웃이 필요한가요?
**A.** Auto Layout을 사용하면 텍스트 길이에 따라 자동으로 조정됩니다.
