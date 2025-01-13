import UIKit

extension DashboardUI {
    
    enum Icon {
        static let info = UIImage(systemName: "info.circle.fill")
        static let gear = UIImage(systemName: "gearshape")
        static let date = UIImage(systemName: "calendar")
        static let time = UIImage(systemName: "clock.fill")
    }
    
    enum Metric {
        static let columns: CGFloat = 7
        static let gridInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        static let cellMin: CGFloat = 32
        static let cellMax: CGFloat = 72
        static let contentInset: CGFloat = 16
        static let headerImageSide: CGFloat = 96
        static let cornerRadius: CGFloat = 16
        static let actionHeight: CGFloat = 56
        
        static func calculateGridSpacing(for width: CGFloat) -> CGFloat {
            let availableWidth = width - gridInsets.left - gridInsets.right
            let cellWidth = availableWidth / columns
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                return min(max(cellWidth * 0.15, 8), 16)
            } else {
                return min(max(cellWidth * 0.12, 4), 12)
            }
        }
    }
}
