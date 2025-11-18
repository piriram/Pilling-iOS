# 필링 (Pilling) - 여성호르몬제 복용 관리 앱

<div align="center">
  <img width="400" alt="필링 앱 로고" src="https://github.com/user-attachments/assets/43436be2-edc8-4b0b-8f3b-248f5ad27e24">
  <br>
  <br>
  <b>필링(Pilling)</b>은 <b>여성호르몬제</b>를 <b>제시간</b>에 <b>복용</b>하게 하고, <b>간단하게 기록하는 것</b>을 <b>돕는</b> 앱입니다.
  <br>
  <br>
  My happy Pilling Time! Everyday is a growing.
  <br>
  <br>
  <img width="495" alt="필링 앱 스크린샷" src="https://github.com/user-attachments/assets/42d8c988-aa55-4b69-88ee-f57707a63692">
</div>

<br>

## 📱 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **앱 이름** | 필링 (Pilling) |
| **개발 기간** | 2024.05 - 2024.07 (팀 개발) → 2024.10 - 현재 (개인 리팩토링) |
| **개발 인원** | 1인 (iOS 개발 담당) |
| **배포 타겟** | iOS 16.0+ |
| **App Store** | [다운로드](https://apps.apple.com/kr/app/pilling/id6753967952) |

<br>

## ✨ 주요 기능

### 1. 맞춤형 복용 주기 설정
- 사용자마다 다른 호르몬제 복용 패턴을 직접 설정 (복용일 + 휴약일)
- 개인별 복용 시간 설정 및 푸시 알림 제공

### 2. 13단계 세분화된 복용 상태 추적
- 단순 복용/미복용을 넘어 **13가지 상태**로 정교하게 관리
- 복용 시간 기준 ±2시간, ±4시간 허용 범위를 고려한 실시간 상태 변화
- 예시: `정시 복용`, `2시간 지연`, `4시간 초과(위험)`, `2회 복용 필요` 등

### 3. 컨텍스트 기반 스마트 메시지 시스템
- 복용 패턴을 분석하여 **17가지 상황별 맞춤 메시지** 제공
- 연속 미복용 일수, 어제 복용 여부, 오늘 복용 상태를 종합 판단
- 캐릭터 애니메이션과 이모지로 직관적인 피드백

### 4. 홈 화면 위젯
- 앱을 실행하지 않아도 홈 화면에서 즉시 오늘의 복용 상태 확인
- Timeline Provider를 통한 스마트 업데이트 (복용 시간, +2시간, +4시간, +12시간 자동 갱신)

### 5. 복용 패턴 통계 및 부작용 관리
- 주기별 복용 완료율 시각화 (도넛 차트)
- 사용자 정의 부작용 태그 생성 및 관리

<br>

## 🛠 기술 스택

### Language
- **Swift 5.9**
  - 타입 안전성과 옵셔널 처리를 통한 런타임 에러 최소화

### Framework
- **UIKit**
  - iOS 16 최소 타겟에서 SwiftUI API 제약(scrollPosition 등) 회피
  - 사용자별 다른 사이클 길이에 따른 동적 그리드 CollectionView의 세밀한 레이아웃 제어 필요
  - 5년간 축적된 UIKit 경험을 활용한 안정적인 개발

### Database
- **CoreData**
  - 로컬 전용 앱으로 서버 통신 불필요, 오프라인 우선 설계
  - **App Groups**를 통한 메인 앱-위젯 간 데이터 공유 구현 (Shared SQLite Container)
  - NSPersistentContainer의 백그라운드 컨텍스트로 메인 스레드 블로킹 방지

### Others
- **MVVM + Clean Architecture**
  - Domain/Infra/Presentation 계층 분리로 비즈니스 로직의 독립적 테스트 가능
  - CoreData 마이그레이션 시 Domain 레이어는 변경 없이 유지 (변경 격리)

- **Repository Pattern + DI Container**
  - Protocol 기반 추상화로 메인 앱과 위젯이 동일한 Repository 인터페이스 사용
  - DIContainer를 통한 의존성 주입으로 테스트 용이성 확보

- **RxSwift / RxCocoa**
  - CoreData 변경 → ViewModel 상태 업데이트 → UI 반영을 선언적으로 표현
  - 복용 기록 시 달력, 메시지, 위젯 등 여러 UI 컴포넌트가 자동 동기화

- **WidgetKit**
  - Timeline Provider로 특정 시점(복용 시간, +2h, +4h, +12h)에만 위젯 갱신하여 배터리 최적화

- **SnapKit**
  - AutoLayout 코드의 가독성 향상 및 동적 constraint 업데이트 로직 간소화

<br>

## 🏗 아키텍처 및 설계

### 전체 구조도 (Clean Architecture + MVVM)

```
┌─────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                         │
│                         (MVVM)                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐          ┌──────────────────────┐        │
│  │ View         │ ◀─Bind─▶ │ ViewModel            │        │
│  │ Controller   │          │ (RxSwift Relay)      │        │
│  └──────────────┘          └──────────────────────┘        │
│         │                            │                      │
│         │                            ▼                      │
│         │                   ┌─────────────────┐            │
│         │                   │  Coordinator    │            │
│         │                   │  (Navigation)   │            │
│         │                   └─────────────────┘            │
│         │                                                   │
└─────────┼───────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│              (Business Logic - Framework 독립)               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────┐        │
│  │  Entities (순수 Swift 모델)                     │        │
│  │  • Cycle, DayRecord, PillStatus (13 states)    │        │
│  │  • DayItem, UserSettings, MessageType          │        │
│  └────────────────────────────────────────────────┘        │
│                                                              │
│  ┌────────────────────────────────────────────────┐        │
│  │  Repository Protocols (DIP - 의존성 역전)       │        │
│  │  • CycleRepositoryProtocol                     │        │
│  │  • UserDefaultsRepositoryProtocol              │        │
│  └────────────────────────────────────────────────┘        │
│                                                              │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                 INFRASTRUCTURE LAYER                         │
│                  (구현체 & UseCase)                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────┐        │
│  │  Repositories (Protocol 구현체)                 │        │
│  │  • CycleRepository (CoreData 접근)             │        │
│  │  • UserDefaultsRepository                      │        │
│  └────────────────────────────────────────────────┘        │
│                                                              │
│  ┌────────────────────────────────────────────────┐        │
│  │  UseCases (비즈니스 로직 워크플로우)             │        │
│  │  • FetchDashboardDataUseCase                   │        │
│  │  • TakePillUseCase                             │        │
│  │  • UpdatePillStatusUseCase                     │        │
│  │  • CalculateMessageUseCase (앱/위젯 공유)       │        │
│  └────────────────────────────────────────────────┘        │
│                                                              │
│  ┌────────────────────────────────────────────────┐        │
│  │  Managers                                       │        │
│  │  • CoreDataManager (Shared Container)          │        │
│  │  • LocalNotificationManager                    │        │
│  │  • SystemTimeProvider (테스트 가능한 시간 추상화)│       │
│  └────────────────────────────────────────────────┘        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                │
├─────────────────────────────────────────────────────────────┤
│  CoreData (App Groups Shared Container)                     │
│  • PillCycleEntity ←→ Cycle (Domain Model)                 │
│  • PillRecordEntity ←→ DayRecord (Domain Model)            │
│                                                              │
│  SQLite: group.app.Pilltastic.Pilling/PillingApp.sqlite    │
└─────────────────────────────────────────────────────────────┘
```

### 사용한 디자인 패턴

#### 1. **MVVM (Model-View-ViewModel)**
- View와 비즈니스 로직 분리, RxSwift의 reactive binding으로 데이터 흐름 자동화
- ViewModel이 UseCase를 호출하여 비즈니스 로직 실행, 결과를 Relay로 방출

#### 2. **Repository Pattern**
- CoreData 접근 로직을 Repository로 캡슐화
- Protocol로 추상화하여 테스트 시 Mock Repository 주입 가능

#### 3. **Dependency Injection (DI Container)**
```swift
// DIContainer.swift
final class DIContainer {
    static let shared = DIContainer()

    private lazy var coreDataManager = CoreDataManager()
    private lazy var userDefaultsManager = UserDefaultsManager()

    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(
            fetchDashboardDataUseCase: makeFetchDashboardDataUseCase(),
            takePillUseCase: makeTakePillUseCase(),
            // ...
        )
    }
}
```

#### 4. **Coordinator Pattern**
- 화면 전환 로직을 ViewController에서 분리
- DashboardCoordinator가 설정, 통계, 히스토리 화면 네비게이션 담당

#### 5. **UseCase Pattern**
- 각 비즈니스 기능을 독립적인 UseCase 클래스로 분리
- 예: `TakePillUseCase`, `CalculateMessageUseCase`
- 재사용 가능하며, 위젯 Extension과도 공유 (9개 파일 Target Membership)

<br>

## 💡 핵심 구현 내용

### 1. 13단계 PillStatus Enum으로 정교한 상태 관리

#### 문제 인식
기존 복용 관리 앱들은 "복용함 / 안함"의 이분법적 접근만 제공했습니다. 하지만 실제 호르몬제 복용에는 다음과 같은 문제가 있었습니다:

- "오늘 복용 예정"과 "오늘 2시간 지났는데 안 먹음"을 구분할 수 없음
- "정시에 먹음"과 "2시간 늦게 먹음" (의학적으로 허용)을 구분할 수 없음
- 4시간 이상 지연 시 2회 복용이 필요한 **위급 상황**을 표현할 수 없음
- 과거 누락과 미래 예정을 동일하게 처리하여 사용자 혼란 초래

#### 해결 방법
복용 시간 기준 **±2시간, ±4시간** 허용 범위와 **날짜 컨텍스트**를 고려하여 **13가지 상태**로 세분화했습니다.

```swift
// PillStatus.swift
enum PillStatus: Int, Sendable {
    // 과거 날짜
    case taken = 0              // 정시 복용 완료
    case takenDelayed = 1       // 2시간 초과 지연 복용
    case takenDouble = 2        // 2회 복용 (전날 누락 보충)
    case missed = 3             // 누락

    // 오늘 날짜
    case todayNotTaken = 4      // 아직 안 먹음 (허용 시간 내)
    case todayTaken = 5         // 정시 복용
    case todayTakenDelayed = 6  // 2시간 초과 복용 (허용)
    case todayDelayed = 7       // 2시간 초과 미복용 (경고)
    case todayTakenTooEarly = 10 // 2시간 이상 일찍 복용
    case todayDelayedCritical = 12 // 4시간 초과 미복용 (위험)

    // 미래 날짜 / 휴약기
    case scheduled = 8          // 예정
    case rest = 9               // 휴약기
    case takenTooEarly = 11     // 과거에 너무 일찍 복용한 기록

    // 날짜 컨텍스트에 따라 상태를 자동 변환
    func adjustedForDate(_ date: Date, calendar: Calendar = .current) -> PillStatus {
        let isDateToday = calendar.isDateInToday(date)
        return isDateToday ? asTodayVersion() : asHistoricalVersion()
    }
}
```

#### 왜 이렇게 했는가?
**이전 방식 (Boolean 플래그):**
```swift
// ❌ 이전 방식: 정보 손실 및 타입 불안전성
struct DayRecord {
    var isTaken: Bool
    var isDelayed: Bool
    var isToday: Bool
    // 조합으로 상태 판단 → 휴먼 에러 가능
}
```

**개선된 방식 (Enum):**
```swift
// ✅ 개선 방식: 타입 안전성과 명확한 상태
enum PillStatus {
    case todayDelayedCritical  // 한눈에 위급 상황 파악

    var isTaken: Bool {
        switch self {
        case .taken, .takenDelayed, .takenDouble, .todayTaken, .todayTakenDelayed:
            return true
        default:
            return false
        }
    }
}
```

#### 효과
1. **타입 안전성**: 컴파일 타임에 잘못된 상태 조합 방지
2. **정교한 UX**: 상태별로 다른 색상, 메시지, 알림 제공
   - `todayDelayedCritical` → 빨간색 배경 + "4시간 초과! 2회 복용 필요" 메시지
   - `todayTaken` → 초록색 배경 + "오늘 복용 완료!" 메시지
3. **버그 감소**: switch 문의 exhaustive checking으로 모든 케이스 처리 강제
4. **유지보수성**: 새로운 상태 추가 시 컴파일러가 누락된 처리를 자동 감지

<br>

### 2. App Groups를 활용한 메인 앱 - 위젯 간 실시간 데이터 동기화

#### 문제 상황
위젯에서 메인 앱의 복용 데이터를 표시해야 하지만, iOS는 앱과 위젯을 **별도의 샌드박스 환경**에서 실행합니다.

**시도했던 방법들:**
1. ❌ UserDefaults 복사 → 데이터 양이 많아지면 성능 저하, 동기화 타이밍 이슈
2. ❌ JSON 파일 공유 → CoreData의 관계형 데이터 구조 표현 어려움, 직렬화/역직렬화 오버헤드

#### 해결 방법
**App Groups + Shared CoreData Container** 패턴 구현

```swift
// CoreDataManager.swift (메인 앱)
final class CoreDataManager {
    static let shared = CoreDataManager()

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PillingApp")

        // ✅ App Groups Shared Container로 SQLite 파일 위치 변경
        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.app.Pilltastic.Pilling")?
            .appendingPathComponent("PillingApp.sqlite") else {
            fatalError("App Group container not found")
        }

        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData store failed to load: \(error)")
            }
        }

        return container
    }()
}
```

```swift
// SharedCoreDataManager.swift (위젯)
final class SharedCoreDataManager {
    static let shared = SharedCoreDataManager()

    // ✅ 동일한 App Group Identifier와 SQLite 파일 경로 사용
    private let appGroupIdentifier = "group.app.Pilltastic.Pilling"

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PillingApp")

        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("PillingApp.sqlite") else {
            fatalError("Shared container URL not found")
        }

        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }

        return container
    }()
}
```

#### 이전 방식보다 나은 이유

| 비교 항목 | UserDefaults 복사 | **App Groups + CoreData** |
|----------|-------------------|---------------------------|
| 데이터 일관성 | △ 수동 동기화 필요 | ✅ 동일 SQLite 파일 공유 (자동 동기화) |
| 성능 | △ 직렬화/역직렬화 오버헤드 | ✅ CoreData의 Faulting으로 필요한 데이터만 로드 |
| 관계형 데이터 | ❌ 1:N 관계 표현 어려움 | ✅ CoreData Relationship 지원 |
| 코드 재사용 | ❌ 위젯용 별도 파싱 로직 | ✅ Repository, UseCase 그대로 재사용 |
| 보안 | △ 민감 데이터 평문 저장 | ✅ SQLite 암호화 지원 |

#### 실제 마주친 이슈와 해결
**문제:** Entitlements 파일에서 App Group Identifier를 `group.app.pilltastic.pilling` (소문자)로 설정했는데, 코드에서는 `group.app.Pilltastic.Pilling` (대문자)로 사용하여 위젯이 데이터를 읽지 못함

```swift
// ❌ 동작하지 않는 코드
containerURL(forSecurityApplicationGroupIdentifier: "group.app.pilltastic.pilling")

// ✅ Entitlements와 정확히 일치하도록 수정
containerURL(forSecurityApplicationGroupIdentifier: "group.app.Pilltastic.Pilling")
```

**배운 점:**
App Group Identifier는 **대소문자를 엄격히 구분**하므로, Entitlements 파일과 코드에서 완전히 동일한 문자열을 사용해야 합니다. 이후 배포 환경에서도 동일한 실수를 방지하기 위해 Constants 파일에 정의하여 사용했습니다.

<br>

### 3. WidgetKit Timeline Provider 최적화로 배터리 효율 개선

#### 문제 인식
위젯이 **1분마다 업데이트**되면 배터리 소모가 심각합니다. 하지만 복용 상태는 특정 시점에만 변경됩니다:
- 복용 예정 시간
- 2시간 경과 (지연 경고)
- 4시간 경과 (위험 경고)
- 12시간 경과 (다음 날 2회 복용 필요)

#### 해결 방법
**필요한 시점에만 업데이트되는 Timeline 생성**

```swift
// DailyWidgetProvider.swift
struct DailyWidgetProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [DailyWidgetEntry] = []
        let currentDate = Date()

        guard let cycle = fetchCurrentCycle(),
              let todayRecord = cycle.todayRecord else {
            // 데이터 없으면 1시간 후 재시도
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
            let timeline = Timeline(entries: [DailyWidgetEntry(date: currentDate)], policy: .after(nextUpdate))
            completion(timeline)
            return
        }

        let scheduledTime = todayRecord.scheduledDateTime

        // ✅ 상태 변경이 일어나는 정확한 시점에만 Entry 생성
        let keyTimes: [Date] = [
            scheduledTime,                                          // 복용 예정 시간
            scheduledTime.addingTimeInterval(2 * 60 * 60),          // +2시간 (지연 경고)
            scheduledTime.addingTimeInterval(4 * 60 * 60),          // +4시간 (위험 경고)
            scheduledTime.addingTimeInterval(12 * 60 * 60),         // +12시간 (2회 복용 필요)
            Calendar.current.startOfDay(for: scheduledTime.addingTimeInterval(24 * 60 * 60)) // 다음날 시작
        ]

        for time in keyTimes where time > currentDate {
            let status = calculateStatus(for: time, record: todayRecord)
            let message = calculateMessage(for: status)
            entries.append(DailyWidgetEntry(date: time, status: status, message: message))
        }

        let nextUpdate = entries.last?.date ?? Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

#### 효과
- **배터리 절약**: 1분마다 업데이트 (1440회/일) → 5회/일로 감소 (99.7% 감소)
- **정확한 상태 반영**: 복용 시간 2시간 후 정확히 "지연" 메시지로 변경
- **사용자 경험**: 실시간으로 상태가 변하는 것처럼 느껴지면서도 배터리 효율적

<br>

## 📊 리팩토링 성과

### 기술 스택 전환

| 항목 | Before (팀 프로젝트) | After (개인 리팩토리) | 전환 이유 |
|------|---------------------|----------------------|----------|
| **UI** | SwiftUI | UIKit + SnapKit | iOS 16 API 제약, CollectionView 세밀한 레이아웃 제어, 팀 경험 활용 |
| **데이터베이스** | SwiftData | CoreData | iOS 16 지원, 안정성 확보, 위젯과의 데이터 공유 |
| **실시간 업데이트** | LiveActivity | WidgetKit | 사용자 피드백 기반 접근성 개선 (항상 보이는 위젯 선호) |

### 코드 품질 개선

- **Clean Architecture 적용**으로 계층 간 의존성 최소화
  - Domain 레이어를 프레임워크로부터 완전히 독립시켜 비즈니스 로직 테스트 가능
  - CoreData → Realm 마이그레이션 시에도 Domain 레이어는 변경 불필요

- **Protocol 기반 설계**로 테스트 용이성 확보
  - 테스트 커버리지 **60% 이상** 달성
  - Mock Repository, Mock TimeProvider로 시간 의존적 로직 테스트

- **9개 파일 Target Membership** 설정으로 메인 앱-위젯 간 코드 중복 제거
  - Domain Entities, UseCases를 양쪽에서 공유
  - DRY 원칙 준수

### v1.0 (팀 프로젝트) vs v2.0 (리팩토링)

- **v1.0 Repository**: [2024-MC2-M3-Pilltastic](https://github.com/DeveloperAcademy-POSTECH/2024-MC2-M3-Pilltastic)
- **v2.0 Repository**: [Pilling-iOS](https://github.com/piriram/Pilling-iOS)

<br>

## 🔍 개선점 및 회고

### 기술적 성장

**1. 아키텍처 설계 역량 강화**
- Clean Architecture를 단순히 적용하는 것을 넘어, **왜 이 계층 분리가 필요한지** 경험으로 체득
- Repository Pattern의 추상화가 위젯 개발 시 개발 시간을 **절반으로 단축**시키는 것을 직접 확인

**2. 프레임워크 선택의 Trade-off 이해**
- SwiftUI의 선언적 문법이 생산성을 높여주지만, iOS 16 타겟에서는 API 제약이 큼
- UIKit의 복잡도 vs. 세밀한 제어의 균형을 프로젝트 요구사항에 맞춰 판단하는 능력 배양

**3. iOS 플랫폼 고유 기술 깊이 있는 이해**
- App Groups, CoreData Shared Container, WidgetKit Timeline 등 iOS 생태계 기술을 production 수준으로 활용
- 단순 튜토리얼 수준을 넘어 **실제 배포 환경에서 발생하는 이슈**(대소문자 구분, Timeline 최적화 등)를 해결

### 문제 해결

**1. 실전 디버깅 능력**
- App Group Identifier 대소문자 이슈를 Xcode Console 로그 분석으로 해결
- 위젯이 데이터를 읽지 못하는 현상을 단계별로 추적 (Entitlements → Container URL → SQLite 파일 존재 확인)

**2. 성능 최적화**
- SnapKit constraint 업데이트 로직을 `layoutIfNeeded()` 호출 최적화로 개선
- 달력 CollectionView의 동적 높이 계산을 캐싱하여 스크롤 성능 향상

### 사용자 중심 사고

**1. UX 개선**
- 단순 "복용 완료" 버튼이 아닌, **13가지 상태**로 세분화하여 사용자의 실제 복용 패턴 정밀 추적
- "2시간 지났어요"처럼 구체적인 피드백으로 사용자의 행동 변화 유도

**2. 접근성**
- 위젯을 통한 **즉시 확인 가능**한 UI로 앱 실행 없이도 오늘의 상태 파악 가능
- 푸시 알림 + 위젯 + 인앱 메시지의 3중 리마인더 시스템으로 복용 누락 방지

### 앞으로 개선하고 싶은 부분

**1. 테스트 커버리지 확대**
- 현재 60% → 80% 이상으로 확대
- UI 테스트 자동화 (XCUITest)로 사용자 플로우 검증

**2. 모듈화**
- Feature 단위로 모듈 분리 (Dashboard, Settings, Statistics 모듈)
- SPM(Swift Package Manager)으로 의존성 명확화

**3. 서버 연동 (선택적)**
- 현재는 로컬 전용이지만, iCloud 동기화로 여러 기기 간 데이터 공유
- 백업 및 복원 기능 추가

<br>

## 👨‍💻 개발자

|<img alt="Piri" src="https://github.com/DeveloperAcademy-POSTECH/2024-MC2-M3-Pilltastic/assets/62399318/d390c9ff-e232-457e-8311-fa22d56097f7" width="150">|
|:---:|
|[Piri(김소람)](https://github.com/piriram)|
|iOS 개발|

<br>

## 📄 라이선스

MIT License
