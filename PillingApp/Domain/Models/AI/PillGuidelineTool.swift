import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// 피임약 가이드라인 Tool
/// WHO/식약처 승인 가이드라인을 기반으로 정확한 의료 정보 제공
@available(iOS 26.0, *)
struct PillGuidelineTool: Tool {

    // MARK: - Tool Protocol

    let name = "getPillGuideline"

    let description = """
        Get WHO and MFDS-verified contraceptive pill guidelines.
        Use this tool to provide accurate medical advice for:
        - Missed pill situations
        - Vomiting/diarrhea after taking pill
        - Drug interactions
        - Emergency symptoms
        - Contraindications
        """

    // MARK: - Arguments

    @Generable
    struct Arguments {
        @Guide(description: "Type of guidance needed")
        var guidanceType: GuidanceType

        @Guide(description: "Hours delayed from scheduled time (for missed pill)")
        var delayHours: Double?

        @Guide(description: "Current day in 21-day cycle (1-21)")
        var cycleDay: Int?

        @Guide(description: "Whether unprotected intercourse occurred in past 7 days")
        var hadUnprotectedIntercourse: Bool?

        @Guide(description: "Whether user took pills correctly in the past 7 days")
        var correctPastSevenDays: Bool?
    }

    @Generable
    enum GuidanceType {
        case missedPill
        case vomitingDiarrhea
        case contraindications
        case emergencySymptoms
        case drugInteractions
        case basicUsage
    }

    // MARK: - Tool Implementation

    func call(arguments: Arguments) async throws -> ToolOutput {
        var guideline: String

        switch arguments.guidanceType {
        case .missedPill:
            guideline = handleMissedPill(arguments: arguments)

        case .vomitingDiarrhea:
            guideline = PillKnowledgeBase.vomitingDiarrheaGuidelines

        case .contraindications:
            guideline = PillKnowledgeBase.contraindicationsGuidelines

        case .emergencySymptoms:
            guideline = PillKnowledgeBase.emergencySymptoms

        case .drugInteractions:
            guideline = PillKnowledgeBase.drugInteractionsGuidelines

        case .basicUsage:
            guideline = PillKnowledgeBase.basicUsageGuidelines
        }

        // 출처 명시
        let output = """
            [출처: 식품의약품안전처 허가 의약품 첨부문서]

            \(guideline)

            ---
            본 정보는 교육 목적이며, 개인 맞춤 조언은 의료 전문가와 상담하세요.
            """

        return ToolOutput(output)
    }

    // MARK: - Private Helper

    private func handleMissedPill(arguments: Arguments) -> String {
        guard let delayHours = arguments.delayHours,
              let cycleDay = arguments.cycleDay else {
            return PillKnowledgeBase.missedPillGuidelines
        }

        // 구체적인 상황에 맞는 가이드라인 제공
        let specificGuideline = PillKnowledgeBase.getMissedPillGuideline(
            delayHours: delayHours,
            cycleDay: cycleDay
        )

        // 추가 정보
        var additionalInfo = ""

        if delayHours > 12 {
            if let hadIntercourse = arguments.hadUnprotectedIntercourse, hadIntercourse {
                additionalInfo += "\n\n⚠️ **중요**: 이전 7일 내 성관계가 있었으므로 임신 가능성을 고려해야 합니다."
            }

            if cycleDay >= 1 && cycleDay <= 7 {
                if let hadIntercourse = arguments.hadUnprotectedIntercourse, hadIntercourse {
                    additionalInfo += "\n응급 피임을 고려하시고, 의료 전문가와 상담하세요."
                }
            }
        }

        return specificGuideline + additionalInfo
    }
}

#endif
