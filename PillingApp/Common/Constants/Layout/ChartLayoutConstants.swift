import UIKit

// MARK: - Chart Layout Constants
enum ChartLayoutConstants {
    // 공통 상수
    static let holeRadius: CGFloat = 0.72
    static let transparentCircleRadius: CGFloat = 0.72
    static let verticalInset: CGFloat = 10
    
    // 중앙 콘텐츠
    static let centerIconSize: CGFloat = 60
    static let centerIconCornerRadius: CGFloat = 20
    static let centerStackSpacing: CGFloat = 4
    
    // DonutChartView 전용 상수
    enum Data {
        static let sliceSpace: CGFloat = 0
        static let selectionShift: CGFloat = 0
        static let centerTitleFontSize: CGFloat = 16
        static let centerPercentageFontSize: CGFloat = 32
        static let animationDuration: Double = 0.8
    }
    
    // Empty 상태 전용 상수
    enum Empty {
        static let closeIconSize: CGFloat = 24
        static let closeIconOffset: CGFloat = 8
    }
    
    // Arrow 버튼
    enum ArrowButton {
        static let horizontalInset: CGFloat = 40
        static let width: CGFloat = 18
        static let height: CGFloat = 30
    }
}
