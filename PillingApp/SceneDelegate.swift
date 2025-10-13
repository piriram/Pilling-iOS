//
//  SceneDelegate.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/11/25.
//

import UIKit
import IQKeyboardManagerSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        configureIQKeyboardManager()
        
        // Window 생성
        let window = UIWindow(windowScene: windowScene)
        
        let viewModel = PillSettingViewModel()
        let pillSettingViewController = PillSettingViewController(viewModel: viewModel)

        // Wrap with a navigation controller
        let navigationController = UINavigationController(rootViewController: pillSettingViewController)
        navigationController.navigationBar.isHidden = false

        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        self.window = window
    }
    
    private func configureIQKeyboardManager() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistance = 40
        
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
