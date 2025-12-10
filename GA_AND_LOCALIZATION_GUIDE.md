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
// 간단한 번역
let title = "dashboard.title".localized  // "대시보드" 또는 "Dashboard"

// 버튼 텍스트
button.setTitle("common.confirm".localized, for: .normal)
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

#### Step 1: Localizable.strings에 포맷 추가

**한국어**
```
"pill.count" = "%d개의 약";
"pill.taken_at" = "%@에 복용 완료";
```

**영어**
```
"pill.count" = "%d pills";
"pill.taken_at" = "Taken at %@";
```

#### Step 2: 코드에서 사용
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

### 5. 유지보수 팁

#### 번역 키 네이밍 규칙
```
[화면명].[요소명]
예:
- dashboard.title
- settings.notification
- pill.status.taken
```

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
│   │   └── Localizable.strings                # 한국어 번역
│   └── en.lproj/
│       └── Localizable.strings                # 영어 번역
└── Common/
    └── Extension/
        └── String+Localized.swift             # 번역 헬퍼

```

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
