//
//  DashboardCoordinator.swift
//  PillingApp
//
//  Created by Claude on 11/11/25.
//

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
}
