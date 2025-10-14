//
//  SceneDelegate.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/11/25.
//

import UIKit
import IQKeyboardManagerSwift
import RxSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private let disposeBag = DisposeBag()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        configureIQKeyboardManager()
        
        // Window 생성
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // 기록 중인 사이클이 있는지 확인
        checkExistingCycle { hasExistingCycle in
            DispatchQueue.main.async {
                if hasExistingCycle {
                    // 기록 중인 사이클이 있으면 DashboardViewController
                    self.showDashboard()
                } else {
                    // 기록 중인 사이클이 없으면 PillSettingViewController
                    self.showPillSetting()
                }
                
                window.makeKeyAndVisible()
            }
        }
    }
    
    private func configureIQKeyboardManager() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistance = 60
    }
    
    private func checkExistingCycle(completion: @escaping (Bool) -> Void) {
        let repository = DIContainer.shared.makePillCycleRepository()
        
        repository.fetchCurrentCycle()
            .subscribe(onNext: { cycle in
                completion(cycle != nil)
            }, onError: { _ in
                completion(false)
            })
            .disposed(by: disposeBag)
    }
    
    private func showDashboard() {
        let viewModel = DIContainer.shared.makeDashboardViewModel()
        let dashboardVC = DashboardViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: dashboardVC)
        window?.rootViewController = navigationController
    }
    
    private func showPillSetting() {
        let viewModel = DIContainer.shared.makePillSettingViewModel()
        let pillSettingVC = PillSettingViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: pillSettingVC)
        navigationController.navigationBar.isHidden = false
        window?.rootViewController = navigationController
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
}
