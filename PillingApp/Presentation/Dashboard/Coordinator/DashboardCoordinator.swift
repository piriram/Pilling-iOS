import UIKit

final class DashboardCoordinator {
    
    // MARK: - Properties
    
    private weak var navigationController: UINavigationController?
    
    // MARK: - Initialization
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    // MARK: - Navigation
    
    func navigateToSettings() {
        guard let navigationController = navigationController else {
            return
        }
        let viewModel = DIContainer.shared.makeSettingViewModel()
        let viewController = SettingViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func navigateToCycleHistory() {
        guard let navigationController = navigationController else {
            return
        }
        let viewModel = DIContainer.shared.makePillCycleHistoryViewModel()
        let viewController = CycleHistoryViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func navigateToPillSetting() {
        guard let navigationController = navigationController else {
            return
        }
        let viewModel = DIContainer.shared.makePillSettingViewModel()
        let viewController = PillSettingViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
