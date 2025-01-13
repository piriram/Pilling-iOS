import UIKit

struct DatePickerConfiguration {
    
    // MARK: - DateRange
    
    struct DateRange {
        let minimumDate: Date?
        let maximumDate: Date?
        
        static var defaultRange: DateRange {
            let calendar = Calendar.current
            let currentDate = Date()
            let minDate = calendar.date(byAdding: .day, value: -28, to: currentDate)
            let maxDate = calendar.date(byAdding: .day, value: 28, to: currentDate)
            return DateRange(minimumDate: minDate, maximumDate: maxDate)
        }
    }
    
    // MARK: - Metrics
    
    enum Metrics {
        static let containerHeight: CGFloat = 500
        static let cornerRadius: CGFloat = 20
        static let handleBarWidth: CGFloat = 40
        static let handleBarHeight: CGFloat = 5
        static let handleBarTopOffset: CGFloat = 12
        static let pickerTopOffset: CGFloat = 24
        static let horizontalInset: CGFloat = 16
        static let bottomInset: CGFloat = 20
        
        static let shadowOpacity: Float = 0.1
        static let shadowOffset = CGSize(width: 0, height: -2)
        static let shadowRadius: CGFloat = 10
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let presentationDuration: TimeInterval = 0.35
        static let dismissalDuration: TimeInterval = 0.25
        static let springDamping: CGFloat = 0.85
        static let springVelocity: CGFloat = 0.5
        static let debounceMilliseconds: Int = 300
        static let dismissDelay: TimeInterval = 0.1
    }
    
    // MARK: - Gesture
    
    enum Gesture {
        static let dismissThreshold: CGFloat = 100
        static let dismissVelocity: CGFloat = 800
        static let panSpringDuration: TimeInterval = 0.25
        static let panSpringDamping: CGFloat = 0.8
        static let panSpringVelocity: CGFloat = 0.5
    }
    
    // MARK: - Colors
    
    enum Colors {
        static let dimmedBackground = UIColor.black.withAlphaComponent(0.4)
        static let containerBackground = UIColor.white
        static let handleBar = UIColor(white: 0.85, alpha: 1.0)
        static let pickerTint = AppColor.pillGreen200
    }
}
