//
//  SceneDelegate.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/11/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Window 생성
        let window = UIWindow(windowScene: windowScene)
        //        
        //        // DIContainer를 통해 ViewModel 생성
        //        let viewModel = DIContainer.shared.makeDashboardViewModel()
        //        
        //        // ViewController 생성 (ViewModel 주입)
        //        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        //        
        //        // NavigationController로 감싸기 (옵션)
        //        let navigationController = UINavigationController(
        //            rootViewController: dashboardViewController
        //        )
        //        navigationController.navigationBar.isHidden = true
        //        
        //        // Window 설정
        //        window.rootViewController = navigationController
        let viewModel = PillSettingViewModel()
        let pillSettingViewController = PillSettingViewController(viewModel: viewModel)
        
        window.rootViewController = pillSettingViewController
        window.makeKeyAndVisible()
        
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

