import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// AI가 생성하는 피임약 조언 구조체
@available(iOS 26.0, *)
@Generable
struct PillAdvice {
    @Guide(description: "현재 상황에 대한 요약")
    var situation: String

    @Guide(description: "즉시 취해야 할 조치")
    var immediateAction: String

    @Guide(description: "피임 효과 상태: maintained(유지됨), reduced(저하됨), uncertain(불확실)")
    var contraceptiveEffectiveness: ContraceptiveEffectiveness

    @Guide(description: "추가 피임 방법이 필요한지 여부")
    var needsExtraContraception: Bool

    @Guide(description: "추가 피임 필요 일수 (해당 시)")
    var extraContraceptionDays: Int?

    @Guide(description: "응급 피임이 필요한지 여부")
    var needsEmergencyContraception: Bool

    @Guide(description: "의사 상담이 필요한지 여부")
    var consultDoctor: Bool

    @Guide(description: "위험 수준: low(낮음), medium(중간), high(높음), emergency(응급)")
    var riskLevel: RiskLevel

    @Guide(description: "추가 안내 사항")
    var additionalNotes: String?
}

@available(iOS 26.0, *)
@Generable
enum ContraceptiveEffectiveness {
    case maintained  // 유지됨
    case reduced     // 저하됨
    case uncertain   // 불확실
}

@available(iOS 26.0, *)
@Generable
enum RiskLevel {
    case low        // 낮음
    case medium     // 중간
    case high       // 높음
    case emergency  // 응급
}

#endif
