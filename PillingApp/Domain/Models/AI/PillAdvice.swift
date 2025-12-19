import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// AI가 생성하는 피임약 조언 구조체 (최소 구조)
@available(iOS 26.0, *)
@Generable
struct PillAdvice {
    @Guide(description: "주 답변 내용. 자연스럽고 이해하기 쉽게 작성")
    var answer: String

    @Guide(description: "경고 또는 주의사항 (선택적). 중요한 경우에만 사용")
    var warning: String?
}

#endif
