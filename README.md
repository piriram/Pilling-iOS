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

## 프로젝트 개요

여성호르몬제를 규칙적으로 복용하고 간단하게 기록할 수 있도록 돕는 iOS 앱

**기간:** 2024.05 - 2024.07 (팀 개발) → 2025.10 - 진행 중 (개인 리팩토링)  
**역할:** iOS 개발  
**배포 타겟:** iOS 16+

**GitHub:** [Pilling-iOS](https://github.com/piriram/Pilling-iOS)  
**App Store:** [다운로드](https://apps.apple.com/kr/app/pilling/id6753967952)

---

## 주요 기능

- 약마다 다른 사이클 직접 설정 지원 (복용일 + 휴약일)
- 복용 시간 ±2시간 허용 범위 내 상태 추적
- 9가지 세분화된 복용 상태 시각화
- 홈 화면 위젯을 통한 즉시 확인
- 복용 패턴 기반 맞춤 메시지 제공

---

## 기술 스택 및 선택 이유

### 아키텍처

**MVVM + Clean Architecture**
- **선택 이유:** MVP 개발 일정 내에서 빠른 기능 추가와 유지보수를 동시에 확보하기 위해 계층을 Domain/Data/Presentation으로 분리
- **효과:** 비즈니스 로직(UseCase)을 독립적으로 테스트 가능하게 만들어 CoreData 마이그레이션 시에도 Domain 레이어는 변경 없이 유지

```
Presentation Layer (MVVM)
├── Views: UIKit + SnapKit
└── ViewModels: RxSwift 기반 바인딩

Domain Layer
├── Entities: PillCycle, PillRecord, DayItem
├── UseCases: 비즈니스 로직 캡슐화
└── Repository Protocols: DIP 적용

Data Layer
├── CoreData: 영구 저장소
├── Repositories: Protocol 구현체
└── DataSources: CoreData 접근 계층

Infrastructure Layer
├── AnalyticsService: GA4 추적
└── TimeProvider: 타임존 처리
```

**Repository Pattern + DI**
- **선택 이유:** CoreData 구현체를 Protocol로 추상화하여 위젯 Extension과 메인 앱이 동일한 인터페이스로 데이터 접근
- **효과:** 위젯 개발 시 메인 앱의 CoreData 로직을 그대로 재사용하여 개발 시간 단축

```swift
protocol PillCycleRepositoryProtocol {
    func fetchCurrentCycle() -> Observable<PillCycle?>
    func updateRecord(_ record: PillRecord) -> Observable<Void>
}
```

### UI

**UIKit + SnapKit**
- **SwiftUI 대신 선택한 이유:**
  - iOS 16 최소 타겟에서 일부 SwiftUI API 제약 회피 (ScrollView의 scrollPosition, scrollTargetBehavior 등)
  - 사용자별 다른 사이클 길이에 따른 동적 그리드 CollectionView의 세밀한 레이아웃 제어 필요
  - 5년간 축적된 UIKit 경험을 활용한 빠른 개발
- **SnapKit 도입 이유:** AutoLayout 코드의 가독성 향상 및 constraint 업데이트 로직 간소화

**구체적 사례:**
```swift
// CollectionView 동적 높이 계산
func collectionView(_ collectionView: UICollectionView, 
                    layout: UICollectionViewLayout, 
                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = (collectionView.bounds.width - spacing * 6) / 7
    return CGSize(width: width, height: width)
}

// 계산된 높이를 즉시 다른 뷰에 적용
let totalHeight = calculateCollectionViewHeight()
collectionViewHeightConstraint.update(offset: totalHeight)
```

### 반응형 프로그래밍

**RxSwift + RxCocoa**
- **선택 이유:** CoreData 변경 → ViewModel 상태 업데이트 → UI 반영의 데이터 흐름을 선언적으로 표현
- **효과:** 복용 기록 시 달력, 메시지, 위젯 등 여러 UI 컴포넌트가 자동으로 동기화

```swift
// 단일 데이터 소스에서 여러 UI 자동 업데이트
dashboardStateRelay
    .observe(on: MainScheduler.instance)
    .bind(to: calendarView.rx.items)
    .disposed(by: disposeBag)
```

### 데이터베이스

**CoreData**
- **선택 이유:**
  - 로컬 전용 앱으로 서버 통신 불필요
  - App Groups를 통한 앱-위젯 간 데이터 공유 구현 용이
  - NSPersistentContainer의 백그라운드 컨텍스트로 메인 스레드 블로킹 방지
- **구현 전략:** Shared Container를 사용해 메인 앱과 위젯이 동일한 SQLite 파일 접근

```swift
// App Groups로 컨테이너 공유
let storeURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.app.Pilltastic.Pilling")?
    .appendingPathComponent("PillingApp.sqlite")
```

### Extensions

**WidgetKit**
- **선택 이유:** 사용자가 앱을 열지 않고도 홈 화면에서 오늘의 복용 상태를 즉시 확인 가능
- **구현 특징:** Timeline Provider에서 CoreData를 직접 읽어 1시간마다 업데이트, 복용 상태 변경 시 `WidgetCenter.shared.reloadAllTimelines()` 호출

### 분석

**Google Analytics (Firebase)**
- **선택 이유:** 사용자 행동 패턴 분석을 위한 무료 분석 도구
- **구현 특징:**
  - ATT(App Tracking Transparency) 프레임워크 통합으로 GDPR/CCPA 규제 준수
  - Protocol 기반 AnalyticsService로 추후 다른 분석 도구로 교체 가능하도록 설계
  - 민감한 복용 데이터는 수집하지 않고 사용 패턴만 익명 수집

### 테스트

**XCTest**
- **선택 이유:** UseCase와 ViewModel의 비즈니스 로직 검증
- **테스트 전략:** TimeProvider Protocol을 Mock으로 교체하여 타임존 변경 시나리오 테스트

---

## 핵심 구현 사항

### 1. PillStatus Enum 세분화

**문제 인식**

피임약 복용 앱에서 단순히 "복용함/안함"만으로는 사용자의 실제 복용 패턴을 정확히 추적할 수 없었습니다.

- "오늘 복용 예정"과 "오늘 2시간 지났는데 안 먹음"을 구분 불가
- "정시에 먹음"과 "2시간 늦게 먹음"을 구분 불가
- 과거에 누락된 복용과 미래 예정 복용을 동일하게 처리
- 휴약기를 별도로 표현 불가

**해결 방법**

복용 시간 ±2시간 허용 범위와 날짜를 기준으로 복용 상태를 9가지로 세분화했습니다.

```swift
enum PillStatus {
    // 과거
    case taken              // 정시 복용 완료
    case takenDelayed       // 지연 복용 (2시간 초과)
    case missed             // 누락
    
    // 오늘
    case todayNotTaken      // 아직 안 먹음 (2시간 이내)
    case todayTaken         // 복용 완료 (2시간 이내)
    case todayTakenDelayed  // 복용 완료 (2시간 초과)
    case todayDelayed       // 아직 안 먹음 (2시간 초과)
    
    // 미래/휴약
    case scheduled          // 예정
    case rest               // 휴약기
}
```

**효과**
- 사용자의 복용 패턴을 정밀하게 추적
- 상태별 맞춤 피드백 제공 가능 (예: "2시간 초과! 빨리 복용하세요")
- 타입 안전성 확보로 버그 방지
- 28일 캘린더 그리드에서 직관적인 색상 매핑 가능

### 2. 앱-위젯 간 데이터 공유

**문제 상황**

위젯에서 앱의 복용 데이터를 실시간으로 표시해야 하지만, 기본적으로 앱과 위젯은 별도의 샌드박스 환경에서 동작합니다.

**해결 방법**

App Groups와 Shared CoreData Container를 구현했습니다.

```swift
// SharedCoreDataManager
final class SharedCoreDataManager {
    static let shared = SharedCoreDataManager()
    
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

---

## 리팩토링 성과

### 기술 스택 전환

| 항목 | Before (팀 프로젝트) | After (개인 리팩토링) | 이유 |
|------|---------------------|----------------------|------|
| UI | SwiftUI | UIKit + SnapKit | iOS 16 API 제약, 세밀한 레이아웃 제어 |
| 데이터베이스 | SwiftData | CoreData | iOS 16 지원, 안정성 확보 |
| 알림 | LiveActivity | WidgetKit | 사용자 접근성 개선 |

### 버전 히스토리
- **v1.0:** 팀 프로젝트 버전 
  - [v1.0 Repository 보기](https://github.com/DeveloperAcademy-POSTECH/2024-MC2-M3-Pilltastic)


### 코드 품질 개선

- Clean Architecture 적용으로 계층 간 의존성 최소화
- Protocol 기반 설계로 테스트 용이성 확보 (테스트 커버리지 60% 이상)
- RxSwift를 통한 선언적 프로그래밍 패러다임 적용
- 9개 공유 파일 Target Membership 설정으로 코드 중복 제거

---

## 회고

### 기술적 성장

- Clean Architecture와 RxSwift를 실무 수준으로 적용하며 아키텍처 설계 역량 향상
- UIKit과 SwiftUI의 장단점을 이해하고 프로젝트 요구사항에 맞는 기술 선택 능력 배양
- App Groups, CoreData, WidgetKit 등 iOS 플랫폼 고유 기술에 대한 깊은 이해

### 문제 해결

- App Groups 대소문자 이슈 등 실제 production 환경에서 발생 가능한 문제를 경험하고 해결
- SnapKit constraint 업데이트 로직 최적화를 통해 AutoLayout 메커니즘에 대한 이해도 향상

### 사용자 중심 사고

- 단순히 기능 구현을 넘어 사용자 경험을 고려한 상태 세분화 및 피드백 시스템 설계
- 위젯을 통한 즉시 접근성 제공으로 사용자 편의성 극대화

---

## 개발자

|<img alt="Piri" src="https://github.com/DeveloperAcademy-POSTECH/2024-MC2-M3-Pilltastic/assets/62399318/d390c9ff-e232-457e-8311-fa22d56097f7" width="150">|
|:---:|
|[Piri(김소람)](https://github.com/piriram)|
|iOS 개발|



---

## 라이선스

MIT License
