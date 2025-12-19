import Foundation

/// 피임약 가이드라인 지식 베이스
/// 출처: 식품의약품안전처 허가 의약품 첨부문서 (머시론정 기준)
struct PillKnowledgeBase {

    // MARK: - 복용 누락 대응 규칙

    static let missedPillGuidelines = """
    # 복용 누락 시 대응 규칙

    ## 공통 원칙
    - 연속 7일 이상 복용 유지가 중요
    - 휴약 기간이 7일을 초과해서는 안 됨

    ## 12시간 이내 누락
    - 즉시 1정 복용
    - 다음 정제는 평소 시간에 복용
    - **피임 효과 유지**

    ## 12시간 초과 누락

    ### 1주차 누락 (1~7일)
    - 잊은 마지막 정제 즉시 복용 (2정 동시 복용 가능)
    - 이후 정상 복용
    - **7일간 콘돔 병행 필수**
    - 이전 7일 내 성관계 있었다면 임신 가능성 안내

    ### 2주차 누락 (8~14일)
    - 잊은 마지막 정제 즉시 복용
    - 직전 7일간 정상 복용했으면 추가 피임 불필요
    - 그렇지 않거나 2정 이상 누락 시 → **7일 차단피임**

    ### 3주차 누락 (15~21일)
    휴약 없이 조정 필요

    선택 ①
    - 잊은 마지막 정제 즉시 복용
    - 현재 포장 종료 후 **휴약 없이 새 포장 시작**

    선택 ②
    - 현재 포장 중단
    - 누락일 포함 7일 휴약 후 새 포장 시작

    ※ 이후 첫 휴약기에 출혈 없으면 임신 가능성 고려
    """

    // MARK: - 구토/설사 대응

    static let vomitingDiarrheaGuidelines = """
    # 구토·설사 발생 시

    - 복용 후 **3~4시간 이내 구토 → 흡수 실패**
    - 추가 1정 복용 필요
    - 추가 복용이 어렵다면 **복용 누락 규칙 적용**
    - 심한 위장장애 지속 시 **추가 피임 병행**
    """

    // MARK: - 절대 금기사항

    static let contraindicationsGuidelines = """
    # 절대 사용 금기 (즉시 복용 중단 및 의료진 상담)

    다음 중 하나라도 해당 시 복용 중단:

    - 정맥·동맥 혈전증 또는 병력
    - 35세 이상 흡연자
    - 국소 신경학적 증상이 있는 편두통
    - 중증 간질환 또는 간종양
    - 유방암 등 성호르몬 관련 악성종양
    - 진단되지 않은 질 출혈
    - 임신 또는 임신 의심
    - 수유부
    - C형 간염 DAA 병용 중
    - 유당 불내증(해당 제제에 한함)
    """

    // MARK: - 즉시 병원 안내 증상 (ACHES)

    static let emergencySymptoms = """
    # 즉시 병원 방문이 필요한 증상 (ACHES)

    다음 증상이 나타나면 즉시 응급실 또는 병원 방문:

    - **A**bdominal pain: 심한 복통
    - **C**hest pain: 갑작스러운 흉통·호흡곤란
    - **H**eadache: 심한 두통 또는 시야 이상
    - **E**ye problems: 시력 변화
    - **S**evere leg pain: 편측 다리 통증·부종

    이는 혈전증의 가능성이 있는 증상입니다.
    """

    // MARK: - 약물 상호작용

    static let drugInteractionsGuidelines = """
    # 약물 상호작용 (피임 실패 위험)

    다음 약물 복용 시 피임 효과 감소:

    - 리팜핀 (결핵 치료제)
    - 항경련제 (페니토인, 페노바르비탈, 카르바마제핀 등)
    - 세인트존스워트 (St. John's Wort)
    - 일부 HIV·C형간염 치료제
    - 모다피닐

    **병용 기간 + 중단 후 28일까지 차단피임 필수**
    """

    // MARK: - 기본 복용 원칙

    static let basicUsageGuidelines = """
    # 기본 복용 원칙

    - 1일 1정, 매일 대략 같은 시간에 복용
    - 물과 함께 복용
    - 포장에 표시된 순서대로 복용
    - **21일 연속 복용 + 7일 휴약**
    - 휴약 기간 중 소퇴성 출혈 발생 가능
    - 출혈이 끝나지 않아도 **8일째 새 포장 시작**
    """

    // MARK: - Helper 메서드

    /// 복용 누락 시간에 따른 가이드라인 반환
    static func getMissedPillGuideline(delayHours: Double, cycleDay: Int) -> String {
        if delayHours <= 12 {
            return """
            **12시간 이내 누락**

            - 즉시 1정 복용
            - 다음 정제는 평소 시간에 복용
            - **피임 효과 유지**
            """
        }

        // 12시간 초과
        if cycleDay >= 1 && cycleDay <= 7 {
            // 1주차
            return """
            **12시간 초과 누락 - 1주차**

            - 잊은 마지막 정제 즉시 복용 (2정 동시 복용 가능)
            - 이후 정상 복용
            - **7일간 콘돔 병행 필수**
            - 이전 7일 내 성관계 있었다면 임신 가능성 안내
            """
        } else if cycleDay >= 8 && cycleDay <= 14 {
            // 2주차
            return """
            **12시간 초과 누락 - 2주차**

            - 잊은 마지막 정제 즉시 복용
            - 직전 7일간 정상 복용했으면 추가 피임 불필요
            - 그렇지 않거나 2정 이상 누락 시 → **7일 차단피임**
            """
        } else {
            // 3주차
            return """
            **12시간 초과 누락 - 3주차**

            휴약 없이 조정 필요:

            선택 ①
            - 잊은 마지막 정제 즉시 복용
            - 현재 포장 종료 후 **휴약 없이 새 포장 시작**

            선택 ②
            - 현재 포장 중단
            - 누락일 포함 7일 휴약 후 새 포장 시작

            ※ 이후 첫 휴약기에 출혈 없으면 임신 가능성 고려
            """
        }
    }

    /// 상황별 가이드라인 검색
    static func getGuideline(for topic: Topic) -> String {
        switch topic {
        case .missedPill:
            return missedPillGuidelines
        case .vomitingDiarrhea:
            return vomitingDiarrheaGuidelines
        case .contraindications:
            return contraindicationsGuidelines
        case .emergencySymptoms:
            return emergencySymptoms
        case .drugInteractions:
            return drugInteractionsGuidelines
        case .basicUsage:
            return basicUsageGuidelines
        }
    }

    /// 가이드라인 주제
    enum Topic {
        case missedPill
        case vomitingDiarrhea
        case contraindications
        case emergencySymptoms
        case drugInteractions
        case basicUsage
    }
}
