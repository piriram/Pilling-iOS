import Foundation

/// 본앱과 위젯에서 공통으로 사용하는 메시지 결과 타입
struct MessageResult {
    let text: String
    let widgetText: String?
    let characterImageName: String
    let iconImageName: String
    let backgroundImageName: String
}
