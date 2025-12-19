import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// 한국에서 판매되는 경구피임약 데이터베이스
@available(iOS 26.0, *)
struct PillDatabase {

    // MARK: - 약물 정보 구조체

    struct PillInfo {
        let name: String
        let type: PillType
        let estrogen: String?
        let estrogenDose: Double?
        let progestin: String
        let packType: PackType
        let indicationFocus: [Indication]
        let missedPillRule: MissedPillRule
        let lactationAllowed: Bool
        let thromboRiskHigh: Bool
        let notes: String?
    }

    enum PillType {
        case coc  // 복합경구피임약
        case pop  // 프로게스틴 단일
    }

    enum PackType {
        case standard21  // 21+7
        case extended24  // 24+4
        case continuous28  // 28일 연속
    }

    enum Indication {
        case contraception      // 피임
        case pms               // 월경전증후군
        case pcos              // 다낭성난소증후군
        case acne              // 여드름
        case hirsutism         // 다모증
        case edema             // 부종
    }

    enum MissedPillRule {
        case coc12Hour  // 12시간 기준
        case pop3Hour   // 3시간 기준 (미니필)
    }

    // MARK: - 약물 데이터베이스

    static let pills: [PillInfo] = [
        // 에티닐에스트라디올 + 데소게스트렐
        PillInfo(
            name: "머시론",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "데소게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: "한국에서 가장 널리 사용되는 피임약"
        ),

        PillInfo(
            name: "머시론21정",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "데소게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        PillInfo(
            name: "멜리안",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "데소게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        // 에티닐에스트라디올 + 드로스피레논
        PillInfo(
            name: "야즈",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 20,
            progestin: "드로스피레논",
            packType: .extended24,
            indicationFocus: [.contraception, .pms, .acne, .edema],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: true,
            notes: "PMS, 여드름, 부종 개선 효과. 24+4 복용법"
        ),

        PillInfo(
            name: "야스민",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "드로스피레논",
            packType: .standard21,
            indicationFocus: [.contraception, .pms, .acne, .edema],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: true,
            notes: "PMS, 여드름, 부종 개선 효과"
        ),

        PillInfo(
            name: "센스리베",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "드로스피레논",
            packType: .standard21,
            indicationFocus: [.contraception, .pms, .acne, .edema],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: true,
            notes: "드로스피레논 계열"
        ),

        // 에티닐에스트라디올 + 레보노르게스트렐
        PillInfo(
            name: "마이보라",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "레보노르게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        PillInfo(
            name: "트리퀼라",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "레보노르게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: "3상성 피임약"
        ),

        PillInfo(
            name: "라벨라",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "레보노르게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        PillInfo(
            name: "미니보라",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "레보노르게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        PillInfo(
            name: "에이리스",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "레보노르게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        // 에티닐에스트라디올 + 게스토덴
        PillInfo(
            name: "페미론",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "게스토덴",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        PillInfo(
            name: "멜리아",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "게스토덴",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        // 에티닐에스트라디올 + 노르게스트메이트
        PillInfo(
            name: "오르소사이클렌",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 35,
            progestin: "노르게스트메이트",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        // 에티닐에스트라디올 + 시프로테론
        PillInfo(
            name: "다이안느35",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 35,
            progestin: "시프로테론",
            packType: .standard21,
            indicationFocus: [.contraception, .acne, .hirsutism, .pcos],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: true,
            notes: "여드름, 다모증, PCOS 치료 목적. 혈전 위험 높음"
        ),

        // 기타
        PillInfo(
            name: "로지논",
            type: .coc,
            estrogen: "에티닐에스트라디올",
            estrogenDose: 30,
            progestin: "노르게스트렐",
            packType: .standard21,
            indicationFocus: [.contraception],
            missedPillRule: .coc12Hour,
            lactationAllowed: false,
            thromboRiskHigh: false,
            notes: nil
        ),

        // 프로게스틴 단일 (POP)
        PillInfo(
            name: "세라젯",
            type: .pop,
            estrogen: nil,
            estrogenDose: nil,
            progestin: "데소게스트렐",
            packType: .continuous28,
            indicationFocus: [.contraception],
            missedPillRule: .pop3Hour,
            lactationAllowed: true,
            thromboRiskHigh: false,
            notes: "미니필. 수유부, 혈전 위험 시 사용. 시간 엄수 필수 (±3시간)"
        )
    ]

    // MARK: - 검색 메서드

    static func findPill(by name: String) -> PillInfo? {
        let normalized = name.lowercased()
            .replacingOccurrences(of: "정", with: "")
            .replacingOccurrences(of: " ", with: "")

        return pills.first { pill in
            let pillName = pill.name.lowercased()
                .replacingOccurrences(of: "정", with: "")
                .replacingOccurrences(of: " ", with: "")
            return pillName.contains(normalized) || normalized.contains(pillName)
        }
    }

    static func getPillsByProgestin(_ progestin: String) -> [PillInfo] {
        pills.filter { $0.progestin.lowercased().contains(progestin.lowercased()) }
    }

    static func getPillsByIndication(_ indication: Indication) -> [PillInfo] {
        pills.filter { $0.indicationFocus.contains(indication) }
    }

    static func getHighThromboRiskPills() -> [PillInfo] {
        pills.filter { $0.thromboRiskHigh }
    }

    static func getLactationSafePills() -> [PillInfo] {
        pills.filter { $0.lactationAllowed }
    }

    static func getPillInfo(for pillName: String) -> String {
        guard let pill = findPill(by: pillName) else {
            return "약물 정보를 찾을 수 없습니다. 정확한 약물명을 확인해주세요."
        }

        var info = """
        # \(pill.name)

        **타입**: \(pill.type == .coc ? "복합경구피임약 (COC)" : "프로게스틴 단일 (미니필)")

        **성분**:
        """

        if let estrogen = pill.estrogen, let dose = pill.estrogenDose {
            info += "\n- \(estrogen) \(Int(dose))μg"
        }
        info += "\n- \(pill.progestin)"

        info += "\n\n**복용법**: \(packTypeDescription(pill.packType))"

        if !pill.indicationFocus.isEmpty {
            let indications = pill.indicationFocus.map { indicationDescription($0) }.joined(separator: ", ")
            info += "\n\n**특징**: \(indications)"
        }

        if pill.thromboRiskHigh {
            info += "\n\n⚠️ **혈전 위험**: 드로스피레논/시프로테론 계열은 혈전 위험이 다소 높습니다."
        }

        if pill.lactationAllowed {
            info += "\n\n✅ **수유 중 사용 가능**"
        }

        if let notes = pill.notes {
            info += "\n\n**참고**: \(notes)"
        }

        return info
    }

    // MARK: - Helper

    private static func packTypeDescription(_ type: PackType) -> String {
        switch type {
        case .standard21: return "21일 복용 + 7일 휴약"
        case .extended24: return "24일 복용 + 4일 휴약"
        case .continuous28: return "28일 연속 복용"
        }
    }

    private static func indicationDescription(_ indication: Indication) -> String {
        switch indication {
        case .contraception: return "피임"
        case .pms: return "월경전증후군 개선"
        case .pcos: return "다낭성난소증후군 치료"
        case .acne: return "여드름 개선"
        case .hirsutism: return "다모증 치료"
        case .edema: return "부종 개선"
        }
    }
}

#endif
