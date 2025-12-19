# Foundation Models Framework 완벽 가이드

> WWDC 세션: Meet the Foundation Models framework
> 발표자: Erik, Yifei

## 목차

1. [개요](#1-개요)
2. [모델 소개 및 Playground](#2-모델-소개-및-playground)
3. [Guided Generation](#3-guided-generation)
4. [Streaming](#4-streaming)
5. [Tool Calling](#5-tool-calling)
6. [Stateful Sessions](#6-stateful-sessions)
7. [Developer Tooling](#7-developer-tooling)

---

## 1. 개요

### 핵심 특징

- **온디바이스 실행**: 모든 데이터가 기기 내에서 처리 (프라이버시 보호)
- **오프라인 작동**: 인터넷 연결 불필요
- **OS 내장**: 앱 크기 증가 없음
- **무료**: API 키 불필요, 비용 없음
- **Swift API**: 타입 안전한 네이티브 인터페이스

### 지원 플랫폼

- macOS
- iOS
- iPadOS
- visionOS

### 모델 사양

- **파라미터**: 30억 개 (각각 2비트 양자화)
- **최적화 작업**: 요약, 추출, 분류 등
- **제약**: 세계 지식, 고급 추론에는 부적합 (디바이스 규모 모델)

> ⚠️ **중요**: 서버 규모 LLM과 달리, 작업을 작은 조각으로 나눠야 함

### 활용 사례

✅ 적합한 작업:
- 텍스트 요약
- 정보 추출
- 분류
- 개인화된 검색 제안
- 짧은 콘텐츠 생성

❌ 부적합한 작업:
- 광범위한 세계 지식 필요
- 복잡한 추론
- 최신 이벤트 정보

---

## 2. 모델 소개 및 Playground

### Xcode Playground로 빠른 테스트

앱을 재빌드하지 않고 프롬프트를 즉시 테스트할 수 있습니다.

```swift
import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()
    let response = try await session.respond(
        to: "What's a good name for a trip to Japan? Respond only with a title"
    )
}
```

### 반복 테스트

프로젝트의 타입에 접근 가능:

```swift
#Playground {
    let session = LanguageModelSession()

    for landmark in ModelData.shared.landmarks {
        let response = try await session.respond(
            to: "What's a good name for a trip to \(landmark.name)? Respond only with a title"
        )
    }
}
```

**장점**:
- 여러 입력에 대해 프롬프트 품질 즉시 확인
- 빠른 반복 개발
- 결과가 캔버스에 실시간 표시

---

## 3. Guided Generation

### 문제: 구조화되지 않은 출력

기본적으로 LLM은 자연어 텍스트를 생성합니다.

**전통적 해결책**:
```swift
let response = await session.respond(
    to: "Generate search suggestions in JSON format: {\"suggestions\": [...]}"
)
// 문제:
// - JSON 파싱 필요
// - 구조적 오류 가능성 (잘못된 JSON)
// - 복잡한 에러 핸들링
```

### 해결책: @Generable 매크로

**타입 안전한 구조화된 출력**:

```swift
@Generable
struct SearchSuggestions {
    @Guide(description: "A list of suggested search terms", .count(4))
    var searchTerms: [String]
}
```

**사용**:

```swift
let prompt = """
    Generate a list of suggested search terms for an app
    about visiting famous landmarks.
    """

let response = try await session.respond(
    to: prompt,
    generating: SearchSuggestions.self
)

print(response.content.searchTerms)
// ["Eiffel Tower", "Great Wall of China", ...]
```

### @Generable 지원 타입

#### 프리미티브
- `String`
- `Int`
- `Double`
- `Float`
- `Decimal`
- `Bool`

#### 컬렉션
- `Array`: `[String]`, `[Int]` 등

#### 복합 타입

```swift
@Generable
struct Itinerary {
    var destination: String
    var days: Int
    var budget: Float
    var rating: Double
    var requiresVisa: Bool
    var activities: [String]
    var emergencyContact: Person  // 중첩된 Generable
    var relatedItineraries: [Itinerary]  // 재귀 타입도 가능!
}
```

### @Guide로 세밀한 제어

```swift
@Generable
struct Product {
    @Guide(description: "Product name in English")
    var name: String

    @Guide(description: "Price in USD", .range(10...1000))
    var price: Double

    @Guide(description: "Available colors", .count(3))
    var colors: [String]
}
```

**Guide 옵션**:
- `.count(n)`: 정확히 n개
- `.minimumCount(n)`: 최소 n개
- `.maximumCount(n)`: 최대 n개
- `.range(x...y)`: 숫자 범위

### Constrained Decoding

Guided Generation의 핵심 기술:

1. **구조적 정확성 보장**: 잘못된 JSON, 타입 불일치 불가능
2. **단순한 프롬프트**: 형식 지정 불필요, 동작에만 집중
3. **정확도 향상**: 구조가 명확하면 모델이 더 정확한 내용 생성
4. **추론 속도 향상**: 최적화 가능

---

## 4. Streaming

### 문제: Delta 방식의 한계

전통적 스트리밍 (Delta):

```swift
var accumulated = ""
for try await delta in stream {
    accumulated += delta  // 개발자가 수동으로 누적
    // 구조화된 데이터라면? 파싱 지옥...
}
```

### 해결책: Snapshot 방식

Foundation Models는 **부분 생성된 스냅샷**을 스트리밍합니다.

```swift
let stream = session.streamResponse(
    to: "Craft a 3-day itinerary to Mt. Fuji.",
    generating: Itinerary.self
)

for try await partial in stream {
    print(partial)
    // Itinerary.PartiallyGenerated(
    //     name: "Mt. Fuji Adventure",
    //     days: [Day(...), nil, nil]  // 점진적으로 채워짐
    // )
}
```

### PartiallyGenerated 타입

`@Generable` 매크로가 자동으로 생성:

```swift
@Generable
struct Itinerary {
    var name: String
    var days: [Day]
}

// 확장하면:
extension Itinerary {
    struct PartiallyGenerated {
        var name: String?      // 모든 프로퍼티가 Optional
        var days: [Day]?
    }
}
```

### SwiftUI 통합

```swift
struct ItineraryView: View {
    let session: LanguageModelSession
    let dayCount: Int
    let landmarkName: String

    @State
    private var itinerary: Itinerary.PartiallyGenerated?

    var body: some View {
        VStack {
            if let name = itinerary?.name {
                Text(name)
                    .font(.title)
            }

            if let days = itinerary?.days {
                ForEach(days.indices, id: \.self) { index in
                    if let day = days[index] {
                        DayView(day: day)
                    }
                }
            }

            Button("Start") {
                Task {
                    let prompt = """
                        Generate a \(dayCount) itinerary
                        to \(landmarkName).
                        """

                    let stream = session.streamResponse(
                        to: prompt,
                        generating: Itinerary.self
                    )

                    for try await partial in stream {
                        self.itinerary = partial  // UI 자동 업데이트!
                    }
                }
            }
        }
    }
}
```

### 베스트 프랙티스

#### 1. 애니메이션으로 레이턴시 숨기기

```swift
if let summary = itinerary?.summary {
    Text(summary)
        .transition(.opacity.combined(with: .scale))
}
```

#### 2. SwiftUI View Identity 주의

```swift
ForEach(days.indices, id: \.self) { index in
    // ⚠️ index를 id로 사용하면 애니메이션 문제 발생 가능
}

ForEach(days, id: \.id) { day in
    // ✅ 안정적인 ID 사용
}
```

#### 3. 프로퍼티 순서 중요

```swift
@Generable
struct Itinerary {
    @Guide(description: "Plans for each day")
    var days: [DayPlan]

    @Guide(description: "A brief summary of plans")
    var summary: String  // 마지막에 선언하면 품질 향상
}
```

**이유**:
- 프로퍼티가 선언 순서대로 생성됨
- 요약은 전체 내용을 본 후 생성하는 게 좋음
- 애니메이션 순서도 영향

---

## 5. Tool Calling

### 왜 Tool Calling인가?

디바이스 규모 모델의 한계를 보완:

1. **실시간/개인 데이터 접근**: 날씨, 캘린더, 위치 정보
2. **사실 확인**: 출처 인용으로 환각(hallucination) 억제
3. **실제 작업 수행**: 앱/시스템/실세계 액션

### Tool 정의

```swift
import WeatherKit
import CoreLocation
import FoundationModels

struct GetWeatherTool: Tool {
    let name = "getWeather"
    let description = "Retrieve the latest weather information for a city"

    @Generable
    struct Arguments {
        @Guide(description: "The city to fetch the weather for")
        var city: String
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        // 1. 위치 찾기
        let places = try await CLGeocoder()
            .geocodeAddressString(arguments.city)

        // 2. 날씨 가져오기
        let weather = try await WeatherService.shared
            .weather(for: places.first!.location!)

        let temperature = weather.currentWeather.temperature.value

        // 3. 구조화된 출력
        let content = GeneratedContent(
            properties: ["temperature": temperature]
        )
        return ToolOutput(content)

        // 또는 자연어 출력:
        // return ToolOutput(
        //     "\(arguments.city)'s temperature is \(temperature) degrees."
        // )
    }
}
```

### Tool 동작 방식

```
[Transcript] (이전 대화 기록)
     ↓
[Instructions + Tools] → Model에 제공
     ↓
[Prompt] "What is the temperature in Cupertino?"
     ↓
[Model Decision] → Tool 호출 필요 여부 판단
     ↓
[Tool Call] getWeather(city: "Cupertino")
     ↓
[FoundationModels Framework] → 자동으로 call() 실행
     ↓
[Tool Output] temperature: 71
     ↓
[Transcript에 추가]
     ↓
[Final Response] "It's 71˚F in Cupertino!"
```

### 세션에 Tool 연결

```swift
let session = LanguageModelSession(
    tools: [GetWeatherTool()],
    instructions: "Help the user with weather forecasts."
)

let response = try await session.respond(
    to: "What is the temperature in Cupertino?"
)

print(response.content)
// "It's 71˚F in Cupertino!"
```

**중요**:
- Tool은 **세션 초기화 시** 연결
- 세션 수명 동안 유지
- 모델이 **자율적으로** 호출 여부 결정

### 피임약 어드바이저 예시

```swift
struct PillGuidelineTool: Tool {
    let name = "getPillGuideline"
    let description = "Get medical guidelines for contraceptive pill delays"

    @Generable
    struct Arguments {
        @Guide(description: "Hours delayed from scheduled time")
        var delayHours: Double

        @Guide(description: "Current day in pill cycle (1-28)")
        var currentDay: Int
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        // 검증된 의학 가이드라인
        let guideline: String

        switch arguments.delayHours {
        case 0..<2:
            guideline = "정상 범위. 피임 효과 유지."
        case 2..<12:
            guideline = "가능한 빨리 복용. 피임 효과 유지."
        case 12...:
            if arguments.currentDay <= 7 || arguments.currentDay >= 22 {
                guideline = "즉시 복용 + 7일간 추가 피임 필요. 성관계 시 응급피임 고려."
            } else {
                guideline = "즉시 복용 + 7일간 추가 피임 필요."
            }
        default:
            guideline = "전문의 상담 필요"
        }

        return ToolOutput(guideline)
    }
}

// 사용
let session = LanguageModelSession(
    tools: [PillGuidelineTool()],
    instructions: "You are a helpful assistant for contraceptive pill users."
)

let response = try await session.respond(
    to: "오늘 약을 5시간 늦게 먹었는데 괜찮을까요? 현재 10일차입니다."
)
// Tool이 자동 호출되어 정확한 가이드라인 제공
```

### 다중 Tool 호출

모델이 필요시 여러 Tool을 동시에 호출:

```swift
// 여행 앱 예시
let session = LanguageModelSession(
    tools: [
        GetRestaurantsTool(),
        GetHotelsTool(),
        GetAttractionsTool()
    ]
)

let response = try await session.respond(
    to: "Plan a trip to Tokyo"
)
// 모델이 3개 Tool 모두 호출 → 통합된 답변 생성
```

---

## 6. Stateful Sessions

### 세션 초기화

```swift
let session = LanguageModelSession(
    model: SystemLanguageModel.default,  // 기본 범용 모델
    tools: [/* tools */],
    instructions: """
        You are a helpful assistant who always
        responds in rhyme.
        """
)
```

### Instructions vs Prompts

| | Instructions | Prompts |
|---|-------------|---------|
| **출처** | 개발자 | 사용자 |
| **우선순위** | 높음 | 낮음 |
| **변경 빈도** | 정적 | 동적 |
| **신뢰** | 신뢰됨 | 신뢰 불가 |

**중요**:
- 모델은 Instructions를 Prompts보다 우선 순위로 처리
- Prompt Injection 공격 방어
- **사용자 입력을 Instructions에 넣지 말 것**

```swift
// ❌ 위험
let instructions = "You are \(userInput)"  // Prompt Injection 가능

// ✅ 안전
let instructions = "You are a travel assistant"
let prompt = userInput
```

### Multi-Turn 대화

```swift
let session = LanguageModelSession()

let firstHaiku = try await session.respond(
    to: "Write a haiku about fishing"
)
print(firstHaiku.content)
// Silent waters gleam,
// Casting lines in morning mist—
// Hope in every cast.

let secondHaiku = try await session.respond(
    to: "Do another one about golf"
)
print(secondHaiku.content)
// Silent morning dew,
// Caddies guide with gentle words—
// Paths of patience tread.

// 대화 기록 확인
print(session.transcript)
// (Prompt) Write a haiku about fishing
// (Response) Silent waters gleam...
// (Prompt) Do another one about golf
// (Response) Silent morning dew...
```

**자동 컨텍스트 유지**:
- 모든 대화가 transcript에 저장
- 이전 대화 참조 가능
- "Do another one" 같은 참조 이해

### isResponding 프로퍼티

```swift
struct HaikuView: View {
    @State
    private var session = LanguageModelSession()

    @State
    private var haiku: String?

    var body: some View {
        if let haiku {
            Text(haiku)
        }

        Button("Go!") {
            Task {
                haiku = try await session.respond(
                    to: "Write a haiku about something you haven't yet"
                ).content
            }
        }
        .disabled(session.isResponding)  // ← 중요!
    }
}
```

**이유**: 모델이 응답 중일 때 새 프롬프트 방지

### 특화된 Use Cases (Adapters)

```swift
let session = LanguageModelSession(
    model: SystemLanguageModel(useCase: .contentTagging)
)
```

**Built-in Use Cases**:
- `.contentTagging`: 토픽 태깅, 엔티티 추출, 주제 감지

### Content Tagging 예시

#### 기본 토픽 추출

```swift
@Generable
struct Result {
    let topics: [String]
}

let session = LanguageModelSession(
    model: SystemLanguageModel(useCase: .contentTagging)
)

let response = try await session.respond(
    to: "I love hiking in the mountains during summer.",
    generating: Result.self
)

print(response.content.topics)
// ["hiking", "mountains", "summer", "outdoors"]
```

#### 커스텀 태깅

```swift
@Generable
struct ActionEmotionResult {
    @Guide(.maximumCount(3))
    let actions: [String]

    @Guide(.maximumCount(3))
    let emotions: [String]
}

let session = LanguageModelSession(
    model: SystemLanguageModel(useCase: .contentTagging),
    instructions: """
        Tag the 3 most important actions and emotions
        in the given input text.
        """
)

let response = try await session.respond(
    to: "She ran quickly, feeling anxious and excited.",
    generating: ActionEmotionResult.self
)

print(response.content.actions)    // ["run"]
print(response.content.emotions)   // ["anxious", "excited"]
```

### 가용성 확인

```swift
struct AvailabilityExample: View {
    private let model = SystemLanguageModel.default

    var body: some View {
        switch model.availability {
        case .available:
            Text("Model is available")
                .foregroundStyle(.green)

        case .unavailable(let reason):
            Text("Model is unavailable")
                .foregroundStyle(.red)
            Text("Reason: \(reason)")
        }
    }
}
```

**Unavailable 이유**:
- Apple Intelligence 미지원 기기
- 지원되지 않는 지역
- 기타 시스템 제약

### 에러 핸들링

```swift
do {
    let response = try await session.respond(to: prompt)
} catch LanguageModelError.guardrailViolation {
    // 안전 가이드라인 위반
    showError("부적절한 내용이 감지되었습니다.")
} catch LanguageModelError.unsupportedLanguage {
    // 지원되지 않는 언어
    showError("해당 언어는 지원되지 않습니다.")
} catch LanguageModelError.contextWindowExceeded {
    // 컨텍스트 길이 초과
    showError("대화가 너무 길어졌습니다. 새로운 세션을 시작하세요.")
} catch {
    showError("알 수 없는 오류: \(error)")
}
```

---

## 7. Developer Tooling

### 1. Xcode Playgrounds

```swift
import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()

    // 프로젝트의 타입 사용 가능
    let myData = MyGenerableType(...)

    let response = try await session.respond(
        to: "Process this data",
        generating: MyGenerableType.self
    )
}
```

**장점**:
- 앱 재빌드 불필요
- 빠른 프롬프트 반복
- 프로젝트 타입 직접 접근

### 2. Instruments 프로파일링

**새로운 템플릿**: Foundation Models Profiling

측정 가능:
- 요청 레이턴시
- 토큰 생성 속도
- 메모리 사용량
- 최적화 기회

**활용**:
- 프롬프트 길이 조정
- Prewarming API 효과 측정
- 성능 개선 정량화

### 3. Feedback Assistant

```swift
let feedback = LanguageModelFeedbackAttachment(
    input: [
        // 입력 프롬프트
    ],
    output: [
        // 모델 출력
    ],
    sentiment: .negative,  // 또는 .positive
    issues: [
        LanguageModelFeedbackAttachment.Issue(
            category: .incorrect,
            explanation: "모델이 잘못된 의료 정보를 제공했습니다."
        )
    ],
    desiredOutputExamples: [
        [
            // 원하는 출력 예시
        ]
    ]
)

let data = try JSONEncoder().encode(feedback)
// Feedback Assistant에 첨부
```

**피드백 카테고리**:
- `.incorrect`: 부정확한 정보
- `.offensive`: 부적절한 내용
- `.notHelpful`: 도움이 안 됨
- `.other`: 기타

### 4. Adapter Training Toolkit

**고급 사용자 전용**:
- 커스텀 데이터셋으로 어댑터 학습
- 매우 특화된 use case

**주의사항**:
- Apple이 모델 업데이트 시 재학습 필요
- 상당한 책임과 유지보수 부담
- [developer.apple.com](https://developer.apple.com) 참고

---

## 피임약 어드바이저 적용 가이드

### 추천 아키텍처

```swift
// 1. Medical Guideline Tool
struct PillGuidelineTool: Tool {
    let name = "getMedicalGuideline"
    let description = "Get verified medical guidelines for pill delays"

    @Generable
    struct Arguments {
        var delayHours: Double
        var cycleDay: Int
        var hadIntercourse: Bool
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        // 검증된 의학 규칙 (하드코딩)
        return ToolOutput(MedicalRules.getGuideline(arguments))
    }
}

// 2. User Data Tool
struct PillHistoryTool: Tool {
    let name = "getUserPillHistory"
    let description = "Get user's pill-taking history"

    @Generable
    struct Arguments {
        @Guide(description: "Number of recent days to fetch")
        var days: Int
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        // CoreData에서 실제 데이터
        let history = DIContainer.shared.pillRepository
            .fetchHistory(days: arguments.days)
        return ToolOutput(describing: history)
    }
}

// 3. ViewModel
class PillAdvisorViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isResponding = false

    private var session: LanguageModelSession?

    func startSession() async {
        session = LanguageModelSession(
            tools: [
                PillGuidelineTool(),
                PillHistoryTool()
            ],
            instructions: """
                You are a helpful assistant for contraceptive pill users.
                Always use the medical guideline tool for accurate advice.
                Be empathetic and clear in your explanations.
                Always cite the guideline when providing medical advice.
                """
        )
    }

    func ask(question: String) async {
        guard let session = session else { return }

        isResponding = true
        defer { isResponding = false }

        do {
            let response = try await session.respond(to: question)
            messages.append(Message(text: response.content, isUser: false))
        } catch {
            handleError(error)
        }
    }
}

// 4. SwiftUI View
struct PillAdvisorView: View {
    @StateObject var viewModel = PillAdvisorViewModel()
    @State private var question = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                }
            }

            HStack {
                TextField("질문을 입력하세요", text: $question)

                Button("전송") {
                    Task {
                        await viewModel.ask(question: question)
                        question = ""
                    }
                }
                .disabled(viewModel.isResponding)
            }
        }
        .task {
            await viewModel.startSession()
        }
    }
}
```

### 구조화된 조언 (선택사항)

```swift
@Generable
struct PillAdvice {
    @Guide(description: "Current situation summary")
    var situation: String

    @Guide(description: "Immediate action to take")
    var action: String

    @Guide(description: "Whether additional contraception is needed")
    var needsExtraProtection: Bool

    @Guide(description: "Number of days to use extra protection")
    var extraProtectionDays: Int?

    @Guide(description: "Whether doctor consultation is recommended")
    var consultDoctor: Bool

    @Guide(description: "Risk level: low, medium, high")
    var riskLevel: String
}

// UI에서 활용
if advice.needsExtraProtection {
    WarningBanner(
        message: "\(advice.extraProtectionDays!)일간 추가 피임 필요",
        level: advice.riskLevel
    )
}
```

---

## 체크리스트

### 출시 전 확인사항

- [ ] 가용성 확인 구현 (`model.availability`)
- [ ] 에러 핸들링 (guardrail, unsupported language, context exceeded)
- [ ] Prompt Injection 방어 (사용자 입력은 Instructions에 넣지 않기)
- [ ] 의료 규칙 검증 (Tool로 하드코딩된 가이드라인만 사용)
- [ ] 개인정보 보호 (모든 처리가 온디바이스임을 명시)
- [ ] 오프라인 작동 테스트
- [ ] Multi-turn 대화 테스트
- [ ] Streaming UI 반응성 확인
- [ ] `isResponding` 상태 처리

### 성능 최적화

- [ ] Playground로 프롬프트 최적화
- [ ] Instruments로 레이턴시 측정
- [ ] 짧고 명확한 Instructions 작성
- [ ] 필요한 Tool만 연결
- [ ] Prewarming API 고려 (자주 사용하는 경우)

### 품질 보장

- [ ] 다양한 케이스로 테스트 (2시간, 12시간, 24시간 지연 등)
- [ ] 엣지 케이스 확인 (1일차, 7일차, 21일차, 28일차)
- [ ] 부적절한 입력 처리 (욕설, 관련 없는 질문)
- [ ] Feedback Assistant로 문제 보고

---

## 추가 학습 자료

### WWDC 세션
- "Explore prompt design and safety for on-device Foundation models"
- "Integrate Foundation Models into your app" (Code Along)
- "Making use of Apple Intelligence and machine learning"

### 문서
- [developer.apple.com - Foundation Models](https://developer.apple.com/documentation/FoundationModels)
- Built-in Use Cases 문서
- Adapter Training Toolkit

### 관련 프레임워크
- Vision (이미지 분석)
- Speech (음성-텍스트)
- Natural Language (텍스트 분석)
- Create ML (모델 파인튜닝)
