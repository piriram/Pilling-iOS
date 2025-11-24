import UIKit
import IQKeyboardManagerSwift
import RxSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private let disposeBag = DisposeBag()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        configureIQKeyboardManager()

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let wasReset = VersionManager.shared.checkAndResetIfNeeded()

        if wasReset {
            showPillSetting()
            window.makeKeyAndVisible()
            return
        }

        checkExistingCycle { hasExistingCycle in
            DispatchQueue.main.async {
                if hasExistingCycle {
                    self.showDashboard()
                } else {
                    self.showPillSetting()
                }

                window.makeKeyAndVisible()
            }
        }
    }
    
    private func configureIQKeyboardManager() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
    }
    
    private func checkExistingCycle(completion: @escaping (Bool) -> Void) {
        let repository = DIContainer.shared.getPillCycleRepository()
        
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
        let stasticsViewModel = DIContainer.shared.makeStasticsViewModel()
        let userDefaultsManager = DIContainer.shared.getUserDefaultsManager()
        let timeProvider = DIContainer.shared.timeProvider
        let dashboardVC = DashboardViewController(
            viewModel: viewModel,
            stasticsViewModel: stasticsViewModel,
            userDefaultsManager: userDefaultsManager,
            timeProvider: timeProvider
        )
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
    private func showTest() {
        let viewModel = DIContainer.shared.makeStasticsViewModel()
        let pillSettingVC = StasticsViewController(viewModel: viewModel)
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
