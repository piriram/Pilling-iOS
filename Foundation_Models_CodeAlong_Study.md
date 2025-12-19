# Foundation Models Framework Code-Along 완벽 가이드

> WWDC 세션: Foundation Models Framework Code Along
> 발표자: Shashank (Technology Evangelist, Apple)

## 목차

1. [개요 및 준비](#1-개요-및-준비)
2. [Chapter 1: 기본 프롬프팅](#chapter-1-기본-프롬프팅)
3. [Chapter 2: Guided Generation](#chapter-2-guided-generation)
4. [Chapter 3: 프롬프팅 테크닉](#chapter-3-프롬프팅-테크닉)
5. [Chapter 4: Streaming 응답](#chapter-4-streaming-응답)
6. [Chapter 5: Tool Calling](#chapter-5-tool-calling)
7. [Chapter 6: 성능 최적화](#chapter-6-성능-최적화)

---

## 1. 개요 및 준비

### 우리가 만들 앱

**시작점**: 간단한 랜드마크 리스트 앱

**최종 결과**: AI 기반 여행 계획 앱
- 랜드마크 선택 시 3일 여행 일정 자동 생성
- 실시간 스트리밍으로 UI가 점진적으로 생성됨
- 실제 호텔/레스토랑 이름 포함 (Tool Calling)
- 지도 표시를 위한 구조화된 데이터

### 시스템 요구사항

**필수**:
- Apple Silicon Mac
- macOS Sequoia (Tahoe)
- Xcode 26
- Apple Intelligence 활성화

**대안**: iOS 26이 설치된 iPhone도 가능

### 리소스

1. **Startup Project**: Xcode 프로젝트 파일 (모든 UI/에셋 포함)
2. **Step-by-Step Guide**: 웹 페이지의 상세 가이드
3. **Live Support**: Slido Q&A

### 프로젝트 구조

```
Foundation Models Code Along/
├── Playgrounds/
│   └── Playground.swift          # 프롬프트 실험용
├── ViewModels/
│   ├── ItineraryGenerator.swift  # 핵심 로직
│   └── FindPointsOfInterestTool.swift  # Tool 정의
└── Views/
    ├── LandmarksView.swift       # 랜드마크 리스트
    ├── LandmarkDetailView.swift  # 가용성 체크
    ├── 2-LandmarkTripView.swift  # 생성 버튼 + 텍스트 표시
    └── 3-ItineraryView.swift     # 구조화된 UI
```

**코드 찾기 팁**:
- 파일에 `// MARK: Code-Along Chapter X` 주석 포함
- Find Navigator에서 "Chapter X" 검색

### 개발 워크플로우

```
1. Playground에서 실험
    ↓
2. ViewModel에 핵심 로직 구현
    ↓
3. View에서 UI 표시
```

---

## Chapter 1: 기본 프롬프팅

### 학습 목표

- Language Model Session 생성
- 첫 번째 프롬프트 전송 및 응답 받기
- Instructions로 모델 동작 정의
- 가용성 체크 및 에러 처리

### 1.1 Playground: 첫 프롬프트

**목표**: 온디바이스 모델에 첫 요청 보내기

```swift
import FoundationModels
import Playgrounds

#Playground {
    // Step 1: Session 생성
    let session = LanguageModelSession()

    // Step 2: 프롬프트 전송
    let response = try await session.respond(
        to: "Generate a 3-day itinerary to Paris"
    )

    // 결과 확인
    print(response.content)
    // "Certainly! Here's a 3-day itinerary for exploring Paris..."
}
```

**Canvas 사용**:
- Playground 작성 시 오른쪽에 Canvas 자동 표시
- `Editor > Canvas` 메뉴로 토글 가능
- 새로고침 버튼으로 코드 재실행

**주의사항**:
- 첫 번째 호출 시 약간의 지연 발생 (모델 로딩)
- 출력은 비구조화된 자연어 텍스트
- 완전히 온디바이스, 오프라인 작동

### 1.2 Playground: Instructions 추가

**목표**: Instructions로 일관되고 고품질의 결과 얻기

```swift
#Playground {
    let instructions = """
        Your job is to create an itinerary for the user.
        Each day needs an activity, hotel, and restaurant.
        Always include a title, a short description,
        and a day-by-day plan.
        """

    let session = LanguageModelSession(
        instructions: instructions
    )

    let response = try await session.respond(
        to: "Generate a 3-day itinerary to Paris"
    )

    print(response.content)
    // 이제 activity, hotel, restaurant가 포함된 응답
}
```

**Instructions vs Prompts**:

| | Instructions | Prompts |
|---|-------------|---------|
| **출처** | 개발자 | 사용자 |
| **우선순위** | 높음 | 낮음 |
| **목적** | 페르소나, 규칙, 형식 정의 | 구체적 작업 요청 |
| **지속성** | 전체 세션 동안 | 한 번만 |

**중요**:
- 모델은 Instructions를 Prompts보다 우선 처리
- Prompt Injection 방어
- **사용자 입력을 Instructions에 절대 포함하지 말 것**

### 1.3 Playground: 가용성 확인

**목표**: 다양한 가용성 상태 처리

```swift
#Playground {
    let model = SystemLanguageModel.default

    switch model.availability {
    case .available:
        print("Foundation model is available and ready to go!")

    case .unavailable(.deviceNotEligible):
        // 기기가 Apple Intelligence 미지원
        print("This device doesn't support Apple Intelligence")

    case .unavailable(.appleIntelligenceNotEnabled):
        // Apple Intelligence가 비활성화됨
        print("Apple Intelligence is not enabled")

    case .unavailable(.modelNotReady):
        // 모델 에셋 다운로드 중
        print("Model is downloading. Try again later.")
    }
}
```

**테스트 방법**:
1. Scheme 설정: Product > Scheme > Edit Scheme
2. "Simulated Foundation Models Availability" 선택
3. 다양한 상태 시뮬레이션

### 1.4 App: LandmarkDetailView 업데이트

**목표**: 가용성 체크하여 적절한 UI 표시

```swift
// LandmarkDetailView.swift

import SwiftUI
import FoundationModels

struct LandmarkDetailView: View {
    let landmark: Landmark

    // MARK: Code-Along Chapter 1
    private let model = SystemLanguageModel.default

    var body: some View {
        ScrollView {
            // 이미지, 설명 등...

            // 가용성에 따라 분기
            switch model.availability {
            case .available:
                LandmarkTripView(landmark: landmark)

            case .unavailable(let reason):
                UnavailabilityView(reason: reason)
            }
        }
    }
}

struct UnavailabilityView: View {
    let reason: SystemLanguageModel.UnavailabilityReason

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
            Text("Trip Planner is unavailable")
            Text(message(for: reason))
                .font(.caption)
        }
    }

    func message(for reason: SystemLanguageModel.UnavailabilityReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This device doesn't support Apple Intelligence"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence has not been turned on"
        case .modelNotReady:
            return "Model is downloading. Please try again later."
        }
    }
}
```

### 1.5 App: ItineraryGenerator 구현

**목표**: Session 초기화 및 itinerary 생성 함수 구현

```swift
// ItineraryGenerator.swift

import Foundation
import FoundationModels

@Observable
class ItineraryGenerator {
    let landmark: Landmark

    // MARK: Code-Along Chapter 1
    var session: LanguageModelSession

    var itineraryContent: String = ""

    init(landmark: Landmark) {
        self.landmark = landmark

        let instructions = """
            Your job is to create an itinerary for the user.
            Each day needs an activity, hotel, and restaurant.
            Always include a title, a short description,
            and a day-by-day plan.
            """

        self.session = LanguageModelSession(
            instructions: instructions
        )
    }

    func generateItinerary(dayCount: Int = 3) async throws {
        let prompt = "Generate a \(dayCount)-day itinerary to \(landmark.name)"

        let response = try await session.respond(to: prompt)

        itineraryContent = response.content
    }
}
```

### 1.6 App: LandmarkTripView 업데이트

**목표**: 생성 버튼 추가 및 결과 표시

```swift
// 2-LandmarkTripView.swift

import SwiftUI
import FoundationModels

struct LandmarkTripView: View {
    let landmark: Landmark

    @State private var requestedItinerary = false
    // MARK: Code-Along Chapter 1
    @State private var itineraryGenerator: ItineraryGenerator?

    var body: some View {
        VStack {
            if !requestedItinerary {
                // 초기 상태
                Text(landmark.name)
                    .font(.title)
                Text(landmark.shortDescription)
            } else {
                // 생성된 itinerary 표시
                if let content = itineraryGenerator?.itineraryContent {
                    Text(content)
                }
            }

            // 생성 버튼
            Button("Generate Itinerary") {
                Task {
                    requestedItinerary = true
                    await itineraryGenerator?.generateItinerary()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .task {
            let generator = ItineraryGenerator(landmark: landmark)
            itineraryGenerator = generator
        }
    }
}
```

### Chapter 1 요약

✅ **달성한 것**:
- Language Model Session 생성
- 프롬프트 전송 및 응답 받기
- Instructions로 모델 가이드
- 가용성 체크
- 앱에 통합

❌ **한계**:
- 비구조화된 텍스트 (파싱 어려움)
- 호텔 이름 추출 불가
- 지도에 표시 불가

➡️ **다음 챕터**: Guided Generation으로 구조화된 데이터 얻기

---

## Chapter 2: Guided Generation

### 학습 목표

- `@Generable` 매크로로 구조화된 출력 정의
- 중첩된 구조 생성
- Swift 타입에 직접 매핑
- 리치 UI 구축

### 문제: 비구조화된 텍스트

```swift
// 현재 상태
let response = try await session.respond(
    to: "Generate a 3-day itinerary to Paris"
)

print(response.content)
// "Day 1: Visit Eiffel Tower. Stay at Hotel ABC. Dine at Restaurant XYZ..."
// 😞 어떻게 호텔 이름만 추출?
// 😞 어떻게 지도에 표시?
```

### 해결책: @Generable

```swift
@Generable
struct SimpleItinerary {
    @Guide(description: "An exciting name for the trip")
    var title: String

    @Guide(description: "A short and engaging description for the trip")
    var description: String

    @Guide(description: "Day-by-day activity plan")
    var days: [String]
}
```

### 2.1 Playground: 간단한 Generable

```swift
#Playground {
    let session = LanguageModelSession()

    let response = try await session.respond(
        to: "Generate a 3-day itinerary to Paris",
        generating: SimpleItinerary.self  // ← 핵심!
    )

    // response.content는 이제 SimpleItinerary 타입!
    let itinerary = response.content
    print(itinerary.title)        // "Parisian Bliss"
    print(itinerary.description)  // "Discover the charm..."
    print(itinerary.days)         // ["Day 1: ...", "Day 2: ...", ...]
}
```

### 2.2 Playground: 복잡한 중첩 구조

```swift
// Itinerary.swift (Models 폴더)

@Generable
struct Itinerary {
    @Guide(description: "An exciting name for the trip")
    var title: String

    @Guide(
        description: "The destination landmark",
        .anyOf(ModelData.landmarks)  // ← 특정 값만 허용
    )
    var destinationName: String

    @Guide(description: "A short and engaging description")
    var description: String

    @Guide(description: "Rationale for this itinerary")
    var rationale: String

    @Guide(description: "Day-by-day plan")
    var days: [DayPlan]  // ← 중첩된 struct
}

@Generable
struct DayPlan {
    var title: String
    var subtitle: String
    var destinationName: String
    var activities: [Activity]  // ← 또 다른 중첩
}

@Generable
struct Activity {
    var type: ActivityType  // ← enum도 generable!
    var title: String
    var description: String
}

@Generable
enum ActivityType {
    case sightseeing
    case foodAndDining
    case shopping
    case hotelAndLodging
}
```

**Playground 테스트**:

```swift
#Playground {
    let session = LanguageModelSession()

    let response = try await session.respond(
        to: "Generate a 3-day itinerary to Grand Canyon",
        generating: Itinerary.self
    )

    let itinerary = response.content
    print(itinerary.title)
    print(itinerary.destinationName)
    print(itinerary.days.count)  // 3

    for day in itinerary.days {
        print(day.title)
        for activity in day.activities {
            print("  - \(activity.type): \(activity.title)")
        }
    }
}
```

### Constrained Decoding

**핵심 메커니즘**:
- 구조적 정확성을 **근본적으로 보장**
- 잘못된 JSON, 타입 불일치 **불가능**
- 모델이 생성 중에 실시간으로 제약 적용

**장점**:
1. **간단한 프롬프트**: 형식 지정 불필요
2. **정확도 향상**: 구조가 명확하면 내용도 정확
3. **속도 향상**: 최적화 가능

### 2.3 App: ItineraryGenerator 업데이트

**목표**: String 대신 Itinerary 타입 생성

```swift
// ItineraryGenerator.swift

@Observable
class ItineraryGenerator {
    let landmark: Landmark
    var session: LanguageModelSession

    // MARK: Code-Along Chapter 2
    var itinerary: Itinerary?  // String → Itinerary

    init(landmark: Landmark) {
        self.landmark = landmark

        // Instructions 단순화 (구조는 Generable에 정의됨)
        let instructions = """
            Your job is to create an itinerary for the user.
            """

        self.session = LanguageModelSession(
            instructions: instructions
        )
    }

    func generateItinerary(dayCount: Int = 3) async throws {
        let prompt = """
            Generate a \(dayCount)-day itinerary to \(landmark.name)
            """

        let response = try await session.respond(
            to: prompt,
            generating: Itinerary.self  // ← 핵심 변경
        )

        itinerary = response.content  // String → Itinerary
    }
}
```

### 2.4 App: LandmarkTripView 업데이트

**목표**: 구조화된 데이터를 ItineraryView로 표시

```swift
// 2-LandmarkTripView.swift

struct LandmarkTripView: View {
    let landmark: Landmark

    @State private var requestedItinerary = false
    @State private var itineraryGenerator: ItineraryGenerator?

    var body: some View {
        VStack {
            if !requestedItinerary {
                Text(landmark.name).font(.title)
                Text(landmark.shortDescription)
            } else {
                // MARK: Code-Along Chapter 2
                if let itinerary = itineraryGenerator?.itinerary {
                    ItineraryView(
                        landmark: landmark,
                        itinerary: itinerary  // 구조화된 데이터
                    )
                }
            }

            Button("Generate Itinerary") {
                Task {
                    requestedItinerary = true
                    await itineraryGenerator?.generateItinerary()
                }
            }
        }
        .task {
            itineraryGenerator = ItineraryGenerator(landmark: landmark)
        }
    }
}
```

### ItineraryView 미리보기

```swift
// 3-ItineraryView.swift

struct ItineraryView: View {
    let landmark: Landmark
    let itinerary: Itinerary

    var body: some View {
        VStack(alignment: .leading) {
            // 제목
            Text(itinerary.title)
                .font(.title)

            // 설명
            Text(itinerary.description)
                .font(.body)

            // Day별 계획
            ForEach(itinerary.days.indices, id: \.self) { index in
                DayView(
                    day: itinerary.days[index],
                    landmark: landmark
                )
            }
        }
    }
}
```

### Chapter 2 요약

✅ **달성한 것**:
- `@Generable`로 구조화된 출력 정의
- 중첩된 복잡한 구조 생성
- Swift 타입에 직접 매핑
- 리치 UI 구축

**핵심 이점**:
- String 파싱 불필요
- 타입 안전성
- 컴파일 타임 검증
- SwiftUI와 완벽 통합

➡️ **다음 챕터**: 프롬프팅 테크닉으로 품질 향상

---

## Chapter 3: 프롬프팅 테크닉

### 학습 목표

- Prompt Builder API로 동적 프롬프트 생성
- One-shot prompting으로 품질 향상
- 예제로 스타일/톤 가이드

### 3.1 Playground: Prompt Builder

**목표**: 조건부 프롬프트 생성

```swift
#Playground {
    let session = LanguageModelSession()

    let kidFriendly = true  // 동적 조건

    let response = try await session.respond(
        to: {
            "Generate a 3-day itinerary to Grand Canyon"

            if kidFriendly {
                "The itinerary must be kid-friendly."
            }
        },
        generating: Itinerary.self
    )

    print(response.content.rationale)
    // "This itinerary provides a safe, engaging and
    //  educational experience for children..."
}
```

**장점**:
- Swift 조건문 사용 가능
- 사용자 선택에 따라 동적 변경
- 코드 재사용성

### 3.2 Playground: One-Shot Prompting

**목표**: 고품질 예제로 모델 가이드

```swift
#Playground {
    let session = LanguageModelSession()

    let response = try await session.respond(
        to: {
            "Generate a 3-day itinerary to Grand Canyon"

            // Golden Example 제공
            "Here is an example of the desired format, \
             but don't copy its content:"
            Itinerary.exampleTripToJapan  // ← 실제 Itinerary 인스턴스
        },
        generating: Itinerary.self
    )
}
```

**exampleTripToJapan**:

```swift
// Itinerary.swift

extension Itinerary {
    static let exampleTripToJapan = Itinerary(
        title: "Discover Japan: A Cultural Journey",
        destinationName: "Tokyo",
        description: """
            Immerse yourself in Japan's rich culture, \
            from ancient temples to modern marvels.
            """,
        rationale: """
            This itinerary balances traditional experiences \
            with contemporary attractions, perfect for \
            first-time visitors.
            """,
        days: [
            DayPlan(
                title: "Day 1: Arrival & Exploration",
                subtitle: "Settle in and explore Tokyo",
                destinationName: "Tokyo",
                activities: [
                    Activity(
                        type: .hotelAndLodging,
                        title: "Check-in at Park Hyatt Tokyo",
                        description: "Luxury hotel with stunning city views"
                    ),
                    Activity(
                        type: .sightseeing,
                        title: "Visit Senso-ji Temple",
                        description: "Tokyo's oldest Buddhist temple"
                    ),
                    Activity(
                        type: .foodAndDining,
                        title: "Dinner at Sukiyabashi Jiro",
                        description: "World-renowned sushi restaurant"
                    )
                ]
            ),
            // Day 2, 3...
        ]
    )
}
```

**핵심**:
- String이 아닌 **실제 Itinerary 인스턴스**
- 스키마 + 내용 + 스타일 모두 학습
- "don't copy its content" 명시

### 3.3 App: ItineraryGenerator 업데이트

**목표**: One-shot example 통합

```swift
// ItineraryGenerator.swift

func generateItinerary(dayCount: Int = 3) async throws {
    // MARK: Code-Along Chapter 3
    let response = try await session.respond(
        to: {
            "Generate a \(dayCount)-day itinerary to \(landmark.name)"

            "Here is an example of the desired format, \
             but don't copy its content:"
            Itinerary.exampleTripToJapan
        },
        generating: Itinerary.self
    )

    itinerary = response.content
}
```

### Chapter 3 요약

✅ **달성한 것**:
- Prompt Builder로 동적 프롬프트
- One-shot prompting으로 품질 향상
- 예제로 스타일/톤 전달

**핵심**:
- `@Generable`: 구조 강제
- **One-shot example**: 관계와 스타일 교육
- 톤/보이스 일관성 확보

➡️ **다음 챕터**: Streaming으로 UX 향상

---

## Chapter 4: Streaming 응답

### 학습 목표

- `streamResponse` API 사용
- `PartiallyGenerated` 타입 이해
- 실시간 UI 업데이트

### 문제: 느린 응답 경험

```swift
// 현재: 모든 응답 대기
let response = try await session.respond(...)
// ⏰ 5-10초 대기...
// ✅ 한 번에 표시

// 사용자: "앱이 멈췄나?"
```

### 해결책: Streaming

```swift
// Streaming: 생성되는 대로 표시
let stream = session.streamResponse(...)
for try await partial in stream {
    // 📊 매 순간 업데이트
    // 😊 사용자: "진행 중이구나!"
}
```

### 4.1 App: ItineraryGenerator 업데이트

**목표**: `respond` → `streamResponse`

```swift
// ItineraryGenerator.swift

@Observable
class ItineraryGenerator {
    let landmark: Landmark
    var session: LanguageModelSession

    // MARK: Code-Along Chapter 4
    var itinerary: Itinerary.PartiallyGenerated?  // ← Optional!

    func generateItinerary(dayCount: Int = 3) async throws {
        let response = try await session.streamResponse(  // ← respond → streamResponse
            to: {
                "Generate a \(dayCount)-day itinerary to \(landmark.name)"
                "Here is an example of the desired format, \
                 but don't copy its content:"
                Itinerary.exampleTripToJapan
            },
            generating: Itinerary.self
        )

        // Async Sequence 반복
        for try await partialResponse in response {
            itinerary = partialResponse.content  // 스냅샷 업데이트
        }
    }
}
```

### PartiallyGenerated 이해

```swift
// @Generable이 자동 생성
@Generable
struct Itinerary {
    var title: String
    var days: [DayPlan]
}

// ↓ 매크로 확장

extension Itinerary {
    struct PartiallyGenerated {
        var title: String?      // ← 모두 Optional
        var days: [DayPlan]?
    }
}
```

**스냅샷 방식**:
```
Time 0: PartiallyGenerated(title: nil, days: nil)
Time 1: PartiallyGenerated(title: "Tokyo Adventure", days: nil)
Time 2: PartiallyGenerated(title: "Tokyo Adventure", days: [Day(...)])
Time 3: PartiallyGenerated(title: "Tokyo Adventure", days: [Day(...), Day(...)])
```

**vs Delta 방식**:
```
Time 0: ""
Time 1: "Tokyo"
Time 2: "Tokyo Adventure"  // 수동 누적 필요
Time 3: "Tokyo Adventure\n\nDay 1..."  // 파싱 지옥
```

### 4.2 App: ItineraryView 업데이트

**목표**: Optional 안전하게 unwrap

```swift
// 3-ItineraryView.swift

struct ItineraryView: View {
    let landmark: Landmark
    let itinerary: Itinerary.PartiallyGenerated  // ← PartiallyGenerated

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: Code-Along Chapter 4
            if let title = itinerary.title {  // ← if let
                Text(title)
                    .font(.title)
            }

            if let description = itinerary.description {
                Text(description)
                    .font(.body)
            }

            if let rationale = itinerary.rationale {
                Text(rationale)
                    .font(.caption)
            }

            if let days = itinerary.days {
                ForEach(days.indices, id: \.self) { index in
                    if let day = days[index] {  // ← 중첩도 Optional
                        DayView(
                            day: day,
                            landmark: landmark
                        )
                    }
                }
            }
        }
    }
}

// DayView.swift
struct DayView: View {
    let day: DayPlan.PartiallyGenerated  // ← 모든 generable

    var body: some View {
        VStack {
            if let title = day.title {
                Text(title)
            }

            if let activities = day.activities {
                ForEach(activities.indices, id: \.self) { index in
                    if let activity = activities[index] {
                        ActivityRow(activity: activity)
                    }
                }
            }
        }
    }
}
```

### SwiftUI 애니메이션 팁

```swift
if let summary = itinerary.summary {
    Text(summary)
        .transition(.opacity.combined(with: .scale))
}
```

**주의사항**:
1. **View Identity**: 안정적인 ID 사용
2. **프로퍼티 순서**: 선언 순서대로 생성됨
   ```swift
   @Generable
   struct Itinerary {
       var days: [DayPlan]
       var summary: String  // ← 마지막에 선언 (품질 향상)
   }
   ```

### Chapter 4 요약

✅ **달성한 것**:
- `streamResponse` API 사용
- `PartiallyGenerated` 처리
- 실시간 UI 업데이트

**UX 개선**:
- 응답 대기 시간 체감 감소
- 진행 상황 즉시 확인
- 콘텐츠 소비 조기 시작

➡️ **다음 챕터**: Tool Calling으로 실제 데이터 통합

---

## Chapter 5: Tool Calling

### 학습 목표

- Tool 개념 이해
- Custom Tool 정의
- Model에 Tool 제공
- Greedy Sampling으로 일관성 확보

### 문제: 제한된 지식

```swift
// 모델이 생성한 호텔 이름
"Hotel 1", "Hotel 2", "Hotel 3"

// 😞 실제 존재하는 호텔인가?
// 😞 지도에 표시 불가
// 😞 모델의 지식은 학습 시점까지로 제한됨
```

### 해결책: Tool Calling

모델이 **실제 데이터/함수**에 접근:
- 실시간 정보 (날씨, 위치)
- 앱 데이터 (사용자 기록)
- API 호출 (MapKit, 서버)

### Tool Calling 동작 방식

```
[Transcript]
    ↓
[Instructions + Tools] → Model에 제공
    ↓
[Prompt] "Generate itinerary to Serengeti"
    ↓
[Model Decision] "호텔/레스토랑 필요 → Tool 호출"
    ↓
[Tool Call 1] findPointsOfInterest(category: .hotels)
[Tool Call 2] findPointsOfInterest(category: .restaurants)
    ↓
[Framework] 자동으로 Tool 실행
    ↓
[Tool Output] ["Serengeti Serena Safari Lodge", "Four Seasons Safari Lodge"]
    ↓
[Transcript에 추가]
    ↓
[Final Response] Tool 출력을 포함한 최종 응답 생성
```

### Greedy Sampling

**문제**: LLM은 기본적으로 랜덤 샘플링 → 매번 다른 응답

**해결**: Greedy Sampling = 항상 가장 확률 높은 토큰 선택

```swift
// 랜덤 샘플링 (기본)
"Tokyo Adventure", "Discover Tokyo", "Tokyo Journey"  // 매번 다름

// Greedy Sampling
"Tokyo Adventure", "Tokyo Adventure", "Tokyo Adventure"  // 항상 동일
```

**Tool Calling에 필수**:
- 테스트/디버깅 가능
- Tool 호출 보장
- 재현 가능

### 5.1 App: Tool 정의

**목표**: FindPointsOfInterestTool 구현

```swift
// FindPointsOfInterestTool.swift

import Foundation
import FoundationModels

class FindPointsOfInterestTool: Tool {
    let landmark: Landmark

    init(landmark: Landmark) {
        self.landmark = landmark
    }

    // MARK: Code-Along Chapter 5

    // Step 1: Tool 이름 및 설명
    let name = "findPointsOfInterest"
    let description = "Find points of interest for a landmark"

    // Step 2: Category enum
    @Generable
    enum Category {
        case hotels
        case restaurants
        // 확장 가능: museums, campgrounds, etc.
    }

    // Step 3: Arguments 정의
    @Generable
    struct Arguments {
        @Guide(description: "The type of destination to look for")
        let pointOfInterest: Category
    }

    // Step 4: call 함수 구현
    func call(arguments: Arguments) async throws -> ToolOutput {
        let results = await getSuggestions(for: arguments.pointOfInterest)
        return ToolOutput(results.joined(separator: ", "))
    }

    // Step 5: Helper 함수
    func getSuggestions(for category: Category) async -> [String] {
        // 실제 앱에서는 MapKit API 호출
        switch category {
        case .restaurants:
            return ["Restaurant 1", "Restaurant 2", "Restaurant 3"]
        case .hotels:
            return ["Hotel 1", "Hotel 2", "Hotel 3"]
        }
    }
}
```

**Tool Protocol 요구사항**:
1. `name`: String
2. `description`: String
3. `Arguments`: Generable 타입
4. `call(arguments:) async throws -> ToolOutput`

### 5.2 Playground: Tool 테스트

```swift
#Playground {
    // Landmark 가져오기
    let landmark = ModelData.landmarks[0]  // Sahara Desert

    // Tool 인스턴스 생성
    let pointsOfInterestTool = FindPointsOfInterestTool(
        landmark: landmark
    )

    // Instructions (Tool 사용 명시!)
    let instructions = InstructionBuilder {
        """
        Your job is to create an itinerary for the user.
        Always use the findPointsOfInterest tool to find
        hotels and restaurants in this landmark.
        """
    }

    // Session에 Tool 연결
    let session = LanguageModelSession(
        tools: [pointsOfInterestTool],  // ← 배열 (여러 Tool 가능)
        instructions: instructions
    )

    // Prompt
    let prompt = "Generate a 3-day itinerary to \(landmark.name)"

    // Greedy Sampling으로 일관성 확보
    let response = try await session.respond(
        to: prompt,
        generating: Itinerary.self,
        options: GenerationOptions(sampling: .greedy)  // ← 핵심!
    )

    print(response.content)
}
```

**결과 확인**:

```swift
// Activity 1
title: "Dine-in at Restaurant 1"
description: "Enjoy a traditional Moroccan dinner at Restaurant 1"

// Activity 2
title: "Stay in Hotel 1 and unwind at Hotel 1"
```

### Transcript 검사

```swift
#Playground {
    // ... (위와 동일)

    let inspectSession = session  // Transcript 확인용

    print(inspectSession.transcript)
}
```

**Transcript 구조**:
```
[0] Instructions
[1] Prompt: "Generate a 3-day itinerary to Sahara Desert"
[2] Tool Calls:
    - findPointsOfInterest(category: .hotels)
    - findPointsOfInterest(category: .restaurants)
[3] Tool Outputs:
    - "Hotel 1, Hotel 2, Hotel 3"
    - "Restaurant 1, Restaurant 2, Restaurant 3"
[4] Response: (Final itinerary with tool data)
```

### 5.3 App: ItineraryGenerator 업데이트

**목표**: Tool 통합 및 Greedy Sampling 적용

```swift
// ItineraryGenerator.swift

@Observable
class ItineraryGenerator {
    let landmark: Landmark
    var session: LanguageModelSession
    var itinerary: Itinerary.PartiallyGenerated?

    init(landmark: Landmark) {
        self.landmark = landmark

        // MARK: Code-Along Chapter 5

        // Tool 생성
        let pointsOfInterestTool = FindPointsOfInterestTool(
            landmark: landmark
        )

        // Instructions (Tool 사용 명시)
        let instructions = InstructionBuilder {
            """
            Your job is to create an itinerary for the user.
            Always use the findPointsOfInterest tool to find
            hotels and restaurants in this landmark.
            """
        }

        // Session에 Tool 연결
        self.session = LanguageModelSession(
            tools: [pointsOfInterestTool],
            instructions: instructions
        )
    }

    func generateItinerary(dayCount: Int = 3) async throws {
        let response = try await session.streamResponse(
            to: {
                "Generate a \(dayCount)-day itinerary to \(landmark.name)"
                "Here is an example of the desired format, \
                 but don't copy its content:"
                Itinerary.exampleTripToJapan
            },
            generating: Itinerary.self,
            options: GenerationOptions(sampling: .greedy)  // ← 추가
        )

        for try await partialResponse in response {
            itinerary = partialResponse.content
        }
    }
}
```

### Chapter 5 요약

✅ **달성한 것**:
- Custom Tool 정의 및 구현
- Tool을 Session에 연결
- Instructions로 Tool 사용 가이드
- Greedy Sampling으로 일관성 확보

**핵심**:
- Tool은 모델의 능력을 확장
- 실시간/개인 데이터 접근
- 사실 확인 및 출처 인용
- 실제 작업 수행

➡️ **다음 챕터**: 성능 최적화

---

## Chapter 6: 성능 최적화

### 학습 목표

- Instruments로 병목 지점 식별
- Pre-warming으로 레이턴시 감소
- Token count 최적화

### 문제: 첫 응답 지연

```
사용자가 "Generate Itinerary" 클릭
    ↓
⏰ 약 700ms 대기  ← 모델 로딩
    ↓
✅ 첫 토큰 생성 시작
```

### 6.1 Instruments로 프로파일링

**실행 방법**:
1. Xcode에서 Run 버튼 길게 누르기
2. "Profile" 선택
3. Blank Template 선택
4. "+" → "Foundation Models" 추가
5. Record 버튼 클릭
6. 앱 사용 (Generate Itinerary)
7. Stop

**분석**:

```
Response Track:
[━━━━━━━━━━━━━━━━━━━━━━━]  전체 세션

Asset Loading Track:
       [━━━━━━━]  ← 700ms 모델 로딩

First Token Track:
              ▼  ← 로딩 후 첫 토큰
```

**발견된 병목**:
1. **Asset Loading**: 첫 요청 시 700ms 소요
2. **Max Token Count**: 1044 토큰 (높음)

### 6.2 최적화 1: Pre-warming

**아이디어**: 사용자가 버튼 누르기 전에 모델 미리 로딩

```swift
// ItineraryGenerator.swift

@Observable
class ItineraryGenerator {
    // ...

    // MARK: Code-Along Chapter 6

    func prewarmModel() async {
        // 기본 pre-warm
        await session.prewarm()

        // 또는 프롬프트 프리픽스 제공 (더 효과적)
        await session.prewarm(
            promptPrefix: {
                "Generate a 3-day itinerary to \(landmark.name)"
            }
        )
    }
}
```

**View에서 호출**:

```swift
// 2-LandmarkTripView.swift

struct LandmarkTripView: View {
    // ...

    var body: some View {
        // ...
    }
    .task {
        let generator = ItineraryGenerator(landmark: landmark)
        itineraryGenerator = generator

        // MARK: Code-Along Chapter 6
        await generator.prewarmModel()  // ← View 로드 시 pre-warm
    }
}
```

**타이밍**:
```
사용자가 랜드마크 클릭
    ↓
LandmarkDetailView 로드
    ↓
🔥 Pre-warm 시작
    ↓
사용자가 설명 읽는 중...
    ↓
모델 로딩 완료 ✅
    ↓
사용자가 "Generate Itinerary" 클릭
    ↓
즉시 응답 시작! 🚀
```

### 6.3 최적화 2: Token Count 감소

**문제**: 프롬프트에 Schema + Example 모두 포함

```swift
// 현재
session.respond(
    to: {
        "Generate a 3-day itinerary to \(landmark.name)"
        Itinerary.exampleTripToJapan  // ← Schema + 내용
    },
    generating: Itinerary.self  // ← Schema 또 포함!
)
// 1044 tokens
```

**해결**: Schema 중복 제거

```swift
// ItineraryGenerator.swift

func generateItinerary(dayCount: Int = 3) async throws {
    let response = try await session.streamResponse(
        to: {
            "Generate a \(dayCount)-day itinerary to \(landmark.name)"
            "Here is an example of the desired format, \
             but don't copy its content:"
            Itinerary.exampleTripToJapan
        },
        generating: Itinerary.self,
        includeSchemaInPrompt: false,  // ← 핵심!
        options: GenerationOptions(sampling: .greedy)
    )

    for try await partialResponse in response {
        itinerary = partialResponse.content
    }
}
```

**결과**:
- 1044 tokens → **700 tokens** (34% 감소)
- 초기 처리 시간 단축
- 응답 속도 향상

### 6.4 Instruments로 검증

**최적화 후 프로파일**:

```
Response Track:
[━━━━━━━━━━━━━━━━]  짧아짐

Asset Loading Track:
[━━━━━━━]  ← 세션 시작 전에 완료! (pre-warm)

First Token Track:
▼  ← 세션 시작 직후 즉시!
```

**개선 사항**:
1. **Asset Loading**: 700ms → 0ms (사용자 체감)
2. **Max Token Count**: 1044 → 700 (34% 감소)
3. **First Token Latency**: 크게 단축

### Chapter 6 요약

✅ **달성한 것**:
- Instruments로 병목 식별
- Pre-warming으로 초기 레이턴시 제거
- Schema 중복 제거로 토큰 감소

**성능 개선 전략**:
1. **측정**: 최적화 전에 프로파일링
2. **Pre-warm**: 사용자 행동 예측
3. **Token 최적화**: 중복 제거

---

## 최종 앱 데모

### 완성된 기능

```swift
// 1. 가용성 체크
switch model.availability {
case .available:
    // 2. Pre-warm (View 로드 시)
    await generator.prewarmModel()

    // 3. Tool 기반 Session 생성
    let session = LanguageModelSession(
        tools: [FindPointsOfInterestTool(...)],
        instructions: "..."
    )

    // 4. Streaming 응답
    let stream = session.streamResponse(
        to: {
            "Generate itinerary..."
            Itinerary.exampleTripToJapan
        },
        generating: Itinerary.self,
        includeSchemaInPrompt: false,
        options: GenerationOptions(sampling: .greedy)
    )

    // 5. 실시간 UI 업데이트
    for try await partial in stream {
        itinerary = partial.content  // SwiftUI 자동 반영
    }
}
```

### 사용자 경험

1. **Serengeti 선택** → Pre-warm 시작 (백그라운드)
2. **설명 읽기** → 모델 로딩 완료
3. **"Generate Itinerary" 클릭** → 즉시 응답 시작
4. **실시간 스트리밍**:
   - Title 먼저 표시
   - Description 추가
   - Day 1, 2, 3 순차적으로 생성
5. **실제 데이터**: "Serengeti Serena Safari Lodge" (Tool 제공)
6. **지도 표시**: 구조화된 데이터로 즉시 매핑

---

## 고급 주제 (추가 학습)

Code-Along에서 다루지 못한 내용:

### 1. Custom Model Adapters

**용도**: 특정 도메인에 특화된 모델

```swift
// Adapter Training Toolkit 사용
// 고급 사용자 전용, 재학습 필요
```

### 2. Dynamic Runtime Schemas

**용도**: 런타임에 스키마 정의

```swift
// @Generable은 컴파일 타임
// 런타임 동적 스키마는 별도 API
```

### 3. Guardrails 및 에러 처리

**안전성 체크**:

```swift
do {
    let response = try await session.respond(to: prompt)
} catch FoundationModelsError.guardrailViolation {
    // 부적절한 콘텐츠 차단
} catch FoundationModelsError.contextWindowExceeded {
    // 대화 너무 길어짐
} catch FoundationModelsError.unsupportedLanguage {
    // 지원되지 않는 언어
}
```

---

## 피임약 어드바이저 적용 가이드

### 구조 매핑

| Code-Along | 피임약 어드바이저 |
|-----------|------------------|
| Landmark | Pill (복용약) |
| Itinerary | PillAdvice (복용 조언) |
| DayPlan | DailySchedule (일일 일정) |
| Activity | Action (조치사항) |
| FindPointsOfInterestTool | PillGuidelineTool |

### 1. Generable 정의

```swift
@Generable
struct PillAdvice {
    @Guide(description: "Current situation summary")
    var situation: String

    @Guide(description: "Immediate action to take")
    var action: String

    @Guide(description: "Risk level: low, medium, high")
    var riskLevel: RiskLevel

    @Guide(description: "Whether additional contraception is needed")
    var needsExtraProtection: Bool

    @Guide(description: "Number of days for extra protection")
    var extraProtectionDays: Int?

    @Guide(description: "Whether to consult a doctor")
    var consultDoctor: Bool
}

@Generable
enum RiskLevel {
    case low
    case medium
    case high
}
```

### 2. Tool 정의

```swift
class PillGuidelineTool: Tool {
    let name = "getPillGuideline"
    let description = "Get verified medical guidelines for pill delays"

    @Generable
    struct Arguments {
        @Guide(description: "Hours delayed from scheduled time")
        var delayHours: Double

        @Guide(description: "Current day in cycle (1-28)")
        var cycleDay: Int

        @Guide(description: "Whether unprotected intercourse occurred")
        var hadIntercourse: Bool
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        let guideline = MedicalGuidelines.getAdvice(
            delayHours: arguments.delayHours,
            cycleDay: arguments.cycleDay,
            hadIntercourse: arguments.hadIntercourse
        )
        return ToolOutput(guideline)
    }
}
```

### 3. Session 설정

```swift
class PillAdvisorViewModel: ObservableObject {
    @Published var advice: PillAdvice.PartiallyGenerated?

    private var session: LanguageModelSession?

    func initialize() async {
        let instructions = """
            You are a supportive health assistant for
            contraceptive pill users.

            Always use the pill guideline tool for medical advice.
            Be empathetic and clear.
            DO NOT provide medical advice without using the tool.
            """

        session = LanguageModelSession(
            tools: [PillGuidelineTool()],
            instructions: instructions
        )

        // Pre-warm
        await session?.prewarm()
    }

    func ask(question: String) async throws {
        let stream = try await session!.streamResponse(
            to: question,
            generating: PillAdvice.self,
            includeSchemaInPrompt: false,
            options: GenerationOptions(sampling: .greedy)
        )

        for try await partial in stream {
            advice = partial.content
        }
    }
}
```

### 4. SwiftUI View

```swift
struct PillAdvisorView: View {
    @StateObject var viewModel = PillAdvisorViewModel()

    var body: some View {
        VStack {
            if let advice = viewModel.advice {
                if let situation = advice.situation {
                    Text(situation)
                        .font(.headline)
                }

                if let action = advice.action {
                    Text(action)
                        .foregroundColor(.blue)
                }

                if let needsExtra = advice.needsExtraProtection,
                   needsExtra,
                   let days = advice.extraProtectionDays {
                    WarningBanner(
                        message: "\(days)일간 추가 피임 필요"
                    )
                }

                if let consultDoctor = advice.consultDoctor,
                   consultDoctor {
                    Button("의사 상담 예약") {
                        // ...
                    }
                }
            }

            TextField("질문을 입력하세요", text: $question)
            Button("전송") {
                Task {
                    try await viewModel.ask(question: question)
                }
            }
        }
        .task {
            await viewModel.initialize()
        }
    }
}
```

---

## 핵심 요약

### 6 Chapters 완성!

| Chapter | 핵심 개념 | 코드 |
|---------|----------|------|
| 1 | 기본 프롬프팅 | `session.respond(to:)` |
| 2 | Guided Generation | `@Generable`, `generating:` |
| 3 | 프롬프팅 테크닉 | One-shot example |
| 4 | Streaming | `streamResponse`, `PartiallyGenerated` |
| 5 | Tool Calling | `Tool` protocol, `tools:` |
| 6 | 성능 최적화 | `prewarm()`, `includeSchemaInPrompt` |

### Best Practices

1. **항상 가용성 체크**
   ```swift
   switch model.availability { ... }
   ```

2. **Generable 활용**
   - String 파싱 대신
   - 타입 안전성
   - SwiftUI 직접 매핑

3. **Streaming 사용**
   - UX 향상
   - `PartiallyGenerated`로 점진적 표시

4. **Tool로 정확성 확보**
   - 검증된 데이터만
   - Instructions로 Tool 사용 명시

5. **성능 최적화**
   - Pre-warm 필수
   - Token count 최소화
   - Instruments로 측정

6. **Greedy Sampling**
   - Tool Calling 시
   - 테스트/디버깅 시

---

## 추가 리소스

### WWDC 세션
- "Meet the Foundation Models framework"
- "Explore prompt design and safety for on-device Foundation models"
- "Making use of Apple Intelligence and machine learning"

### 문서
- [Foundation Models Documentation](https://developer.apple.com/documentation/FoundationModels)
- Sample Project (완성된 코드)
- Developer Forums

### 도구
- Xcode 26
- Instruments (Foundation Models template)
- Playgrounds (#Playground macro)

### 피드백
- 세션 후 설문조사
- Developer Forums: developer.apple.com/forums
- Slido Q&A

---

## 마무리

축하합니다! 🎉

온디바이스 생성형 AI 기능을 처음부터 끝까지 구현했습니다:

✅ 기본 텍스트 생성
✅ 구조화된 Swift 타입 출력
✅ 고품질 프롬프팅
✅ 실시간 스트리밍 UI
✅ Tool로 실제 데이터 통합
✅ 성능 최적화

**이제 여러분 차례입니다!**

피임약 어드바이저, 또는 여러분만의 인텔리전트 앱을 만들어보세요.

Foundation Models Framework로 무엇을 만들지 기대됩니다! 🚀
