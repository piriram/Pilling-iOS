import UIKit

final class DashboardViewTransitionManager {
    
    // MARK: - Types
    
    enum ViewIndex: Int {
        case dashboard = 0
        case statistics = 1
    }
    
    // MARK: - Properties
    
    private weak var containerView: UIView?
    private weak var infoView: UIView?
    private weak var statisticsView: UIView?
    private(set) var currentViewIndex: ViewIndex = .dashboard
    
    // MARK: - Callbacks
    
    var onViewIndexChanged: ((ViewIndex) -> Void)?
    
    // MARK: - Initialization
    
    init(
        containerView: UIView,
        infoView: UIView,
        statisticsView: UIView
    ) {
        self.containerView = containerView
        self.infoView = infoView
        self.statisticsView = statisticsView
        setupSwipeGestures()
    }
    
    // MARK: - Setup
    
    private func setupSwipeGestures() {
        guard let containerView = containerView else { return }
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        containerView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        containerView.addGestureRecognizer(swipeRight)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleSwipeLeft() {
        if currentViewIndex == .dashboard {
            switchToView(index: .statistics, direction: .left)
        }
    }
    
    @objc private func handleSwipeRight() {
        if currentViewIndex == .statistics {
            switchToView(index: .dashboard, direction: .right)
        }
    }
    
    // MARK: - View Switching
    
    func switchToView(index: ViewIndex, direction: UISwipeGestureRecognizer.Direction) {
        guard index != currentViewIndex,
              let containerView = containerView,
              let infoView = infoView,
              let statisticsView = statisticsView else { return }
        
        let fromView = currentViewIndex == .dashboard ? infoView : statisticsView
        let toView = index == .dashboard ? infoView : statisticsView
        
        currentViewIndex = index
        onViewIndexChanged?(index)
        
        // Animation preparation
        toView.isHidden = false
        toView.alpha = 0
        
        let screenWidth = containerView.bounds.width
        let translateX: CGFloat = direction == .left ? screenWidth : -screenWidth
        
        toView.transform = CGAffineTransform(translationX: translateX, y: 0)
        
        UIView.animate(withDuration: 0.3, animations: {
            fromView.alpha = 0
            fromView.transform = CGAffineTransform(translationX: -translateX, y: 0)
            
            toView.alpha = 1
            toView.transform = .identity
        }) { _ in
            fromView.isHidden = true
            fromView.transform = .identity
        }
    }
}
