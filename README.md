# Pilling (필링) — 여성호르몬제(피임약) 복용 기록 iOS 앱

> 실제 패키지 구조를 차용한 **캘린더 기반 UI**와 **지능형 알림**으로 28일 사이클 복용을 쉽고 정확하게 관리합니다.

### [App Store Link](https://apps.apple.com/us/app/pilling/id6753967952) 
### [필링 ver1 github Link](https://github.com/DeveloperAcademy-POSTECH/2024-MC2-M3-Pilltastic)


## 프로젝트 개요

* **개발 기간**: 2025-10-11 ~ 진행중
* **개발 환경**: Xcode 16+, iOS 16+, Swift 5.9


---

## 핵심 기능

### 1) 시각적 28일 사이클 관리

* 7x4 그리드 캘린더로 전체 사이클 일괄 확인
* 상태 색상 코딩

  * 초록: 복용 완료 / 연두: 오늘 예정 / 노랑: 지연 / 회색: 휴약
* 현재 일차 표시: `n일차/28`

### 2) 지능형 알림

* 지정 시간 로컬 알림
* **2시간 지연 감지** 및 경고 알림 (Time Sensitive)
* 위젯을 통한 빠른 상태 확인

### 3) 상태별 피드백

* 3D 잔디 캐릭터 표정 변화
* 상태 메시지: “2시간 초과”, “오늘은 쉬는 날”, “잘하고 있어요”

### 4) 캘린더 기반 이력 관리

* 원탭 복용 기록, 자동 시간 저장
* 상태별 색상 표시/수정/삭제
* **Gamification**: 상태 아이콘 + 짧고 긍정적인 카피, 행동 유도형 버튼 라벨

### 5) 통계

* 월/연도별 복용률
* 지연 빈도, 시간대 패턴 분석

---

## 아키텍처

**MVVM + Clean Architecture**
View → ViewModel(Input/Output) → UseCase → Repository → (Core Data / UserDefaults)

```
┌─────────────────────────────────────────────────┐
│            Presentation Layer                    │
│  (UI, ViewController, ViewModel)                 │
└─────────────────┬───────────────────────────────┘
                  │ depends on
┌─────────────────▼───────────────────────────────┐
│              Domain Layer                        │
│     (Entity, UseCase, Business Logic)            │
└─────────────────┬───────────────────────────────┘
                  │ depends on
┌─────────────────▼───────────────────────────────┐
│               Data Layer                         │
│      (Repository, CoreData, UserDefaults)        │
└──────────────────────────────────────────────────┘
                  ▲
                  │ uses
┌─────────────────┴───────────────────────────────┐
│          Infrastructure Layer                    │
│  (TimeProvider, NotificationManager, etc)        │
└──────────────────────────────────────────────────┘
```


---


## 기술 스택

* **UI**: UIKit, SnapKit
* **Reactive**: RxSwift, RxCocoa
* **Architecture**: MVVM + Clean Architecture
* **Storage**: Core Data, UserDefaults
* **Notifications**: UNUserNotificationCenter, WidgetKit
* **Testing**: XCTest
* **Etc.**: IQKeyboardManager


