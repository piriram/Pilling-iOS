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
        Get WHO and MFDS-verified contraceptive pill guidelines and information.
        Use this tool to provide accurate medical advice for:
        - Specific pill information (brand name, ingredients, characteristics)
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

        @Guide(description: "Name of the contraceptive pill (e.g., 머시론, 야즈, 센스리베)")
        var pillName: String?

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
        case pillInfo
        case missedPill
        case vomitingDiarrhea
        case contraindications
        case emergencySymptoms
        case drugInteractions
        case basicUsage
    }

    // MARK: - Tool Implementation

    func call(arguments: Arguments) async throws -> String {
        var guideline: String

        switch arguments.guidanceType {
        case .pillInfo:
            guard let pillName = arguments.pillName else {
                guideline = "약물명을 제공해주세요."
                break
            }
            guideline = PillDatabase.getPillInfo(for: pillName)

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

        return output
    }

    // MARK: - Private Helper

    private func handleMissedPill(arguments: Arguments) -> String {
        // 약물 타입 확인 (POP vs COC)
        var isPOP = false
        if let pillName = arguments.pillName,
           let pill = PillDatabase.findPill(by: pillName) {
            isPOP = (pill.type == .pop)
        }

        guard let delayHours = arguments.delayHours else {
            if isPOP {
                return """
                **프로게스틴 단일 피임약 (미니필) 복용 누락**

                미니필은 매일 같은 시간에 복용해야 하며, **3시간 이상 지연 시** 피임 효과가 떨어질 수 있습니다.

                지연 시간을 알려주시면 더 구체적인 조언을 드릴 수 있습니다.
                """
            } else {
                return PillKnowledgeBase.missedPillGuidelines
            }
        }

        // POP 누락 처리 (3시간 기준)
        if isPOP {
            if delayHours <= 3 {
                return """
                **즉시 복용하세요**

                미니필은 3시간 이내 지연은 괜찮습니다.
                - 즉시 1정 복용
                - 다음 복용은 원래 시간에
                - 피임 효과 유지됨
                """
            } else {
                return """
                **3시간 초과 누락**

                ⚠️ 피임 효과가 저하되었을 수 있습니다.

                **조치**:
                1. 즉시 1정 복용
                2. 다음 복용은 원래 시간에
                3. **48시간 동안 추가 피임 (콘돔) 필수**
                4. 성관계가 있었다면 응급피임 고려

                미니필은 시간 엄수가 매우 중요합니다.
                """
            }
        }

        // COC 누락 처리 (12시간 기준)
        guard let cycleDay = arguments.cycleDay else {
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
