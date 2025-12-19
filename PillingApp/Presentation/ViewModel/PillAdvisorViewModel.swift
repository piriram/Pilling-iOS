import Combine
import Foundation
import RxSwift
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels

/// 피임약 AI 어드바이저 ViewModel
@available(iOS 26.0, *)
@Observable
final class PillAdvisorViewModel {

    // MARK: - Published Properties

    var messages: [Message] = []
    var currentAdvice: PillAdvice.PartiallyGenerated?
    var isResponding = false
    var errorMessage: String?
    var modelAvailability: ModelAvailability = .checking

    // MARK: - Private Properties

    private var session: LanguageModelSession?
    private let model = SystemLanguageModel.default
    private let adviceSubject = PassthroughSubject<PillAdvice.PartiallyGenerated, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let cycleRepository: CycleRepositoryProtocol
    private let disposeBag = DisposeBag()

    // MARK: - Initialization

    init(
        userDefaultsManager: UserDefaultsManagerProtocol = UserDefaultsManager(),
        cycleRepository: CycleRepositoryProtocol = CycleRepository(coreDataManager: CoreDataManager.shared)
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.cycleRepository = cycleRepository
        checkAvailability()
        adviceSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] advice in
                self?.currentAdvice = advice
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// 모델 가용성 확인
    func checkAvailability() {
        switch model.availability {
        case .available:
            modelAvailability = .available
            Task {
                await initializeSession()
            }

        case .unavailable(.deviceNotEligible):
            modelAvailability = .unavailable(reason: "이 기기는 Apple Intelligence를 지원하지 않습니다.")

        case .unavailable(.appleIntelligenceNotEnabled):
            modelAvailability = .unavailable(reason: "설정에서 Apple Intelligence를 활성화해주세요.")

        case .unavailable(.modelNotReady):
            modelAvailability = .unavailable(reason: "모델을 다운로드 중입니다. 잠시 후 다시 시도해주세요.")
        }
    }

    /// Session 초기화 및 Pre-warm
    func initializeSession() async {
        guard modelAvailability == .available else { return }

        let instructions = """
            당신은 피임약 복용자를 위한 supportive health assistant입니다.

            역할:
            - 공감적이고 안심시키는 태도 유지
            - 차분하고 중립적인 안내 톤 유지
            - 간단하고 명확한 언어 사용 (필요한 용어만 사용)
            - 교육 중심, 공포 조성 금지
            - 한국어로 응답

            난이도:
            - 일반인이 이해 가능한 설명
            - 전문 용어는 필요할 때만 사용하고 바로 괄호로 풀어 설명
            - 약어, 수치, 성분명은 필요하지 않으면 쓰지 않음

            답변 구조 (CRITICAL):
            - 먼저 공감하는 첫 문장으로 시작
            - 질문에 대한 핵심 답변 (2-3문장)
            - 필요시 단계별로 상세 설명 (번호 또는 단락으로 구분)
            - 상황별 조치 방법 제시
            - 주의사항이 있으면 warning 필드에 포함
            - 마지막에 면책 조항 포함

            답변 예시 형식:
            "불안하실 수 있어요. 지금 상황에서는 이렇게 하면 됩니다.

            핵심 답변 2-3문장.

            상황을 나눠서 봅니다:

            1. 경우 A
            설명
            -> 조치

            2. 경우 B
            설명
            -> 조치

            추가 안내 및 도움말.

            본 정보는 교육 목적이며, 개인 맞춤 조언은 의료 전문가와 상담하세요."

            행동 규칙:
            - 저장된 피임약 이름이 없을 때만 이름을 물어보세요
            - 약물 정보 조회 시 pillInfo guidance type 사용
            - 의학적 조언은 반드시 pill guideline tool 사용
            - 약물명을 알면 pillName 파라미터에 포함
            - 복잡한 상황은 의료진 상담 권장
            - 우울, 자해, 자살 언급 시 즉시 위기상담 안내 (1393)

            약물 구분:
            - 프로게스틴 단일제: 3시간 기준 (필요 시 "단일 성분 피임약"으로 설명)
            - 에스트로겐+프로게스틴 복합제: 12시간 기준 (필요 시 "두 가지 성분이 함께 든 피임약"으로 설명)
            - "미니필" 같은 용어는 사용하지 않음
            - Tool에서 약물 타입 확인 후 조언

            안전 규칙 (CRITICAL):
            - DO NOT 가이드라인 tool 없이 의학 조언 제공
            - DO NOT 개인 건강 상태에 대한 가정
            - DO NOT tool 확인 없이 응급 피임 권장
            - DO NOT 진단이나 치료 처방
            - DO NOT 단정적 표현 ("괜찮다", "계속 먹어라")

            포맷 규칙 (CRITICAL):
            - DO NOT use markdown formatting (**, ##, -, etc.)
            - DO NOT use emojis (💊, ⚠️, 📋, 👉, ✅, ❌, etc.)
            - DO NOT use symbols/pictograms; remove them if tool output includes them
            - Use plain text only
            - Use line breaks and numbering for structure
            - Use -> for action arrows

            면책 조항:
            모든 응답 끝에 다음 문구 포함:
            "본 정보는 교육 목적이며, 개인 맞춤 조언은 의료 전문가와 상담하세요."
            """

        session = LanguageModelSession(
            tools: [PillGuidelineTool()],
            instructions: instructions
        )

        // Pre-warm
        await session?.prewarm()
    }

    /// 질문하기
    func ask(question: String) async {
        guard let session = session else {
            errorMessage = "세션이 초기화되지 않았습니다."
            return
        }

        print("[PillAdvisor] user input: \(question)")

        // 사용자 메시지 추가
        let userMessage = Message(
            id: UUID(),
            text: question,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)

        isResponding = true
        currentAdvice = nil
        errorMessage = nil

        defer { isResponding = false }

        do {
            let cycleSnapshot = await fetchCurrentCycleSnapshot()
            let prompt = buildPrompt(userQuestion: question, cycle: cycleSnapshot)
            print("[PillAdvisor] prompt: \(prompt)")

            let stream = try await session.streamResponse(
                to: prompt,
                generating: PillAdvice.self,
                includeSchemaInPrompt: false,
                options: GenerationOptions(sampling: .greedy)
            )

            var lastAdvice: PillAdvice.PartiallyGenerated?
            for try await partialResponse in stream {
                let advice = partialResponse.content
                lastAdvice = advice
                adviceSubject.send(advice)
            }

            // 최종 응답을 메시지로 추가
            if let finalAdvice = lastAdvice {
                print("[PillAdvisor] output answer: \(finalAdvice.answer ?? "")")
                print("[PillAdvisor] output warning: \(finalAdvice.warning ?? "")")
                let aiMessage = Message(
                    id: UUID(),
                    text: formatAdvice(finalAdvice),
                    isUser: false,
                    timestamp: Date(),
                    advice: finalAdvice
                )
                messages.append(aiMessage)
            }
            currentAdvice = nil

        } catch let genError as LanguageModelSession.GenerationError {
            currentAdvice = nil
            switch genError {
            case .guardrailViolation:
                errorMessage = "부적절한 내용이 감지되었습니다. 다른 질문을 시도해주세요."
            case .exceededContextWindowSize:
                errorMessage = "대화가 너무 길어졌습니다. 새로운 대화를 시작해주세요."
            case .unsupportedLanguageOrLocale:
                errorMessage = "지원되지 않는 언어입니다."
            default:
                errorMessage = "오류가 발생했습니다: \(genError.localizedDescription)"
            }
        } catch {
            currentAdvice = nil
            errorMessage = "오류가 발생했습니다: \(error.localizedDescription)"
        }
    }

    /// 미리 정의된 질문으로 빠른 시작
    func askPredefined(_ question: PredefinedQuestion) async {
        await ask(question: question.prompt)
    }

    /// 새 대화 시작
    func resetConversation() async {
        messages = []
        currentAdvice = nil
        errorMessage = nil
        await initializeSession()
    }

    // MARK: - Private Helpers

    private func formatAdvice(_ advice: PillAdvice.PartiallyGenerated) -> String {
        var text = ""

        if let answer = advice.answer {
            text = answer
        }

        if let warning = advice.warning {
            text += "\n\n[주의] " + warning
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildPrompt(userQuestion: String, cycle: Cycle?) -> String {
        let bleedingHint = needsBleedingGuidance(userQuestion) ? """
        User mentioned bleeding/spotting.
        Use the guideline tool (guidanceType: switching) and summarize in plain language.
        If pill name is unknown, ask for the pill name first, then provide general safety guidance.
        Do NOT recommend stopping pills or switching methods as a default response.
        Ask 2-3 specific clarifying questions before detailed steps:
        - How long have you been taking this pill (first 1-3 months)?
        - Any missed or late pills?
        - Any heavy bleeding, strong pain, fever, bad odor, or clots?
        Then provide general safety guidance from the tool.
        Focus on early use, missed pills, or heavy/painful bleeding.
        """ : ""

        let startTimingHint = needsStartTimingGuidance(userQuestion) ? """
        User asked about when to start pills/first pack.
        Use the guideline tool (guidanceType: startTiming) and summarize in plain language.
        Explain if additional protection is needed depending on start timing.
        """ : ""

        let cycleContext = cycle.map { cycleContextSummary(from: $0) } ?? ""

        let pillName = savedPillName()
        let isValidPillName = pillName.map(isSavedPillNameValid) ?? true
        let invalidPillHint = (!isValidPillName && pillName != nil) ? """
        The saved pill name does not match the database.
        Do not use pillName for tool arguments.
        Provide standard guidance based on general guidelines.
        Ask the user to confirm the pill name if it is needed for accuracy.
        """ : ""

        guard let pillName, isValidPillName else {
            return """
            \(bleedingHint)
            \(startTimingHint)
            \(invalidPillHint)
            \(cycleContext)
            User question: \(userQuestion)
            """
        }

        return """
        User's saved pill name: \(pillName)
        Use this name for tool arguments when relevant.
        Do not mention it unless the user asked about their pill name.

        \(bleedingHint)
        \(startTimingHint)
        \(invalidPillHint)
        \(cycleContext)
        User question: \(userQuestion)
        """
    }

    private func needsBleedingGuidance(_ question: String) -> Bool {
        let keywords = [
            "부정출혈",
            "출혈",
            "점상출혈",
            "스포팅",
            "spotting",
            "breakthrough",
            "피",
            "빨간",
            "갈색",
            "선홍색",
            "피가",
            "피묻",
            "피 묻",
            "피 섞",
            "라이너",
            "팬티라이너",
            "생리 같",
            "패드",
            "피가 묻",
            "묻어나"
        ]
        return keywords.contains { question.localizedCaseInsensitiveContains($0) }
    }

    private func needsStartTimingGuidance(_ question: String) -> Bool {
        let keywords = [
            "첫팩",
            "처음",
            "언제부터",
            "시작",
            "시작 시기",
            "첫 번째",
            "첫번째",
            "start",
            "first pack"
        ]
        return keywords.contains { question.localizedCaseInsensitiveContains($0) }
    }

    private func savedPillName() -> String? {
        guard let pillName = userDefaultsManager.loadPillInfo()?.name
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !pillName.isEmpty else {
            return nil
        }
        return pillName
    }

    private func isSavedPillNameValid(_ pillName: String) -> Bool {
        PillDatabase.findPill(by: pillName) != nil
    }

    private func fetchCurrentCycleSnapshot() async -> Cycle? {
        await withCheckedContinuation { continuation in
            var didResume = false
            var disposable: Disposable?
            disposable = cycleRepository.fetchCurrentCycle()
                .take(1)
                .subscribe(
                    onNext: { cycle in
                        guard !didResume else { return }
                        didResume = true
                        continuation.resume(returning: cycle)
                        disposable?.dispose()
                    },
                    onError: { _ in
                        guard !didResume else { return }
                        didResume = true
                        continuation.resume(returning: nil)
                        disposable?.dispose()
                    }
                )
        }
    }

    private func cycleContextSummary(from cycle: Cycle) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDay = calendar.startOfDay(for: cycle.startDate)
        let daysSinceStart = calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
        let currentDay = max(daysSinceStart + 1, 1)

        let recordsUpToToday = cycle.records.filter {
            calendar.startOfDay(for: $0.scheduledDateTime) <= today
        }

        let activeRecords = recordsUpToToday.filter { $0.cycleDay <= cycle.activeDays }

        let takenCount = activeRecords.filter { $0.status.isTaken }.count
        let delayedCount = activeRecords.filter { $0.status == .takenDelayed }.count
        let doubleCount = activeRecords.filter { $0.status == .takenDouble }.count
        let missedCount = activeRecords.filter {
            $0.status == .missed || $0.status == .notTaken || $0.status == .recentlyMissed
        }.count

        var sideEffectCounts: [String: Int] = [:]
        for record in recordsUpToToday {
            let names: [String] = record.parsedMemo.sideEffectNames?.map { $0.value } ?? []
            for name in names {
                sideEffectCounts[name, default: 0] += 1
            }
        }
        let sideEffectSummary = sideEffectCounts.isEmpty
            ? "none recorded"
            : sideEffectCounts
                .sorted(by: { $0.key < $1.key })
                .map { "\($0.key) (\($0.value))" }
                .joined(separator: ", ")

        return """
        User's cycle data (from CoreData, user-recorded):
        - Cycle start date: \(dateString(startDay))
        - Current cycle day: \(currentDay) of \(cycle.totalDays) (active days: \(cycle.activeDays), break days: \(cycle.breakDays))
        - Adherence so far (active days only): taken \(takenCount), delayed \(delayedCount), double \(doubleCount), missed \(missedCount)
        - Reported side effects: \(sideEffectSummary)
        """
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
extension PillAdvisorViewModel {

    struct Message: Identifiable {
        let id: UUID
        let text: String
        let isUser: Bool
        let timestamp: Date
        var advice: PillAdvice.PartiallyGenerated?
    }

    enum ModelAvailability: Equatable {
        case checking
        case available
        case unavailable(reason: String)
    }

    enum PredefinedQuestion: String, CaseIterable {
        case pillInfo = "복용 중인 피임약 정보가 궁금해요"
        case missedPill = "실수로 약을 안 먹었어요"
        case lateByHours = "약을 몇 시간 늦게 먹었어요"
        case vomiting = "약 먹고 구토했어요"
        case drugInteraction = "다른 약이랑 같이 먹어도 되나요?"

        var prompt: String {
            rawValue
        }

        var displayText: String {
            rawValue
        }
    }
}

#endif
