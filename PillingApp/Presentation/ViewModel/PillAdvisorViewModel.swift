import Foundation
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

    // MARK: - Initialization

    init() {
        checkAvailability()
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
            - 간단하고 명확한 언어 사용 (전문 용어 최소화)
            - 교육 중심, 공포 조성 금지
            - 한국어로 응답

            행동 규칙:
            - 첫 대화 시 복용 중인 피임약 이름을 물어보세요 (예: 머시론, 야즈, 센스리베 등)
            - 약물 정보 조회 시 pillInfo guidance type 사용
            - 의학적 조언은 반드시 pill guideline tool 사용
            - 약물명을 알면 pillName 파라미터에 포함
            - 가이드라인 인용 시 출처 명시
            - 복잡한 상황은 의료 전문가 상담 권장
            - 2-4 문장으로 간결하게 응답

            약물 구분 중요:
            - 미니필(세라젯 등 POP): 3시간 기준
            - 복합피임약(머시론, 야즈 등 COC): 12시간 기준
            - Tool에서 약물 타입을 확인 후 조언

            안전 규칙 (CRITICAL):
            - DO NOT 가이드라인 tool 없이 의학 조언 제공
            - DO NOT 개인 건강 상태에 대한 가정
            - DO NOT tool 확인 없이 응급 피임 권장
            - DO NOT 진단이나 치료 처방

            포맷 규칙 (CRITICAL):
            - DO NOT use markdown formatting (**, ##, -, etc.)
            - DO NOT use emojis (💊, ⚠️, 📋, etc.)
            - Use plain text only
            - Use line breaks for structure

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
            let stream = try await session.streamResponse(
                to: question,
                generating: PillAdvice.self,
                includeSchemaInPrompt: false,
                options: GenerationOptions(sampling: .greedy)
            )

            for try await partialResponse in stream {
                currentAdvice = partialResponse.content
            }

            // 최종 응답을 메시지로 추가
            if let finalAdvice = currentAdvice {
                let aiMessage = Message(
                    id: UUID(),
                    text: formatAdvice(finalAdvice),
                    isUser: false,
                    timestamp: Date(),
                    advice: finalAdvice
                )
                messages.append(aiMessage)
            }

        } catch let genError as LanguageModelSession.GenerationError {
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
