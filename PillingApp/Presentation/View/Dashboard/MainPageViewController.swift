//
//  MainPageViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/8/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class MainPageViewController: UIPageViewController {
    
    // MARK: - Properties
    
    private let disposeBag = DisposeBag()
    private var pages: [UIViewController] = []
    private var currentIndex: Int = 0
    
    // MARK: - Common UI Components
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "background_taken"))
    
    private let historyButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let gearButton = UIButton(type: .system)
    
    private let pageControl = UIPageControl()
    private let bottomButton = UIButton(type: .system)
    
    // MARK: - Initialization
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCommonViews()
        setupNavigationBar()
        setupPages()
        setupPageViewController()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .left, .right, .bottom]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = .clear
        
        let historyBarButton = UIBarButtonItem(customView: historyButton)
        let infoBarButton = UIBarButtonItem(customView: infoButton)
        let gearBarButton = UIBarButtonItem(customView: gearButton)
        
        navigationItem.rightBarButtonItems = [gearBarButton, infoBarButton, historyBarButton]
    }
    
    private func setupCommonViews() {
        view.backgroundColor = AppColor.bg
        
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        setupTopButtons()
        setupBottomComponents()
        view.addSubview(pageControl)
        view.addSubview(bottomButton)
        
        setupConstraints()
    }
    
    private func setupTopButtons() {
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = AppColor.secondary
        infoButton.snp.makeConstraints { $0.size.equalTo(30) }
        
        historyButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        historyButton.tintColor = AppColor.secondary
        historyButton.snp.makeConstraints { $0.size.equalTo(30) }
        
        gearButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        gearButton.tintColor = AppColor.secondary
        gearButton.snp.makeConstraints { $0.size.equalTo(30) }
    }
    
    private func setupBottomComponents() {
        pageControl.numberOfPages = 2
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = AppColor.pillGreen800
        pageControl.pageIndicatorTintColor = AppColor.notYetGray
        pageControl.isUserInteractionEnabled = false
        
        bottomButton.setTitle(AppStrings.Dashboard.takePillButton, for: .normal)
        bottomButton.setTitleColor(.label, for: .normal)
        bottomButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        bottomButton.backgroundColor = AppColor.pillGreen200
        bottomButton.layer.cornerRadius = 12
    }
    
    private func setupConstraints() {
        let contentInset: CGFloat = 16
        
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(220)
        }
        
        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(bottomButton.snp.top).offset(-28)
            make.centerX.equalToSuperview()
            make.height.equalTo(12)
        }
        
        bottomButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(contentInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(70)
        }
    }
    
    private func setupPages() {
        let dashboardViewModel = DIContainer.shared.makeDashboardViewModel()
        let dashboardVC = DashboardViewController(viewModel: dashboardViewModel)
        dashboardVC.shouldHideCommonViews = true
        dashboardVC.parentPageController = self
        
        let stasticsViewModel = DIContainer.shared.makeStasticsViewModel()
        let stasticsVC = StasticsViewController(viewModel: stasticsViewModel)
        
        pages = [dashboardVC, stasticsVC]
    }
    
    private func setupPageViewController() {
        dataSource = self
        delegate = self
        
        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: false, completion: nil)
            currentIndex = 0
        }
    }
    
    private func setupActions() {
        infoButton.rx.tap
            .bind { [weak self] in
                if let dashboardVC = self?.pages.first as? DashboardViewController {
                    dashboardVC.presentInfoFloatingViewFromParent()
                }
            }
            .disposed(by: disposeBag)
        
        gearButton.rx.tap
            .bind { [weak self] in
                let vm = DIContainer.shared.makeSettingViewModel()
                let vc = SettingViewController(viewModel: vm)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        historyButton.rx.tap
            .bind { [weak self] in
                let vm = DIContainer.shared.makePillCycleHistoryViewModel()
                let vc = CycleHistoryViewController(viewModel: vm)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        bottomButton.rx.tap
            .bind { [weak self] in
                if let dashboardVC = self?.pages.first as? DashboardViewController {
                    dashboardVC.takePillFromParent()
                }
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    
    func moveToPage(at index: Int, animated: Bool = true) {
        guard index >= 0, index < pages.count, index != currentIndex else { return }
        
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        currentIndex = index
        
        setViewControllers([pages[index]], direction: direction, animated: animated, completion: nil)
    }
    
    func updateBackgroundImage(_ imageName: String) {
        backgroundImageView.image = UIImage(named: imageName)
    }
    
    func updateBottomButton(title: String, backgroundColor: UIColor, isEnabled: Bool) {
        bottomButton.setTitle(title, for: .normal)
        bottomButton.backgroundColor = backgroundColor
        bottomButton.isEnabled = isEnabled
    }
}

// MARK: - UIPageViewControllerDataSource

extension MainPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else {
            return nil
        }
        return pages[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < pages.count - 1 else {
            return nil
        }
        return pages[index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension MainPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let currentViewController = pageViewController.viewControllers?.first,
              let index = pages.firstIndex(of: currentViewController) else {
            return
        }
        
        currentIndex = index
        pageControl.currentPage = index
        
        // 통계 화면일 때 히스토리 버튼 숨기기
        if index == 1 {
            let infoBarButton = UIBarButtonItem(customView: infoButton)
            let gearBarButton = UIBarButtonItem(customView: gearButton)
            navigationItem.rightBarButtonItems = [gearBarButton, infoBarButton]
        } else {
            let historyBarButton = UIBarButtonItem(customView: historyButton)
            let infoBarButton = UIBarButtonItem(customView: infoButton)
            let gearBarButton = UIBarButtonItem(customView: gearButton)
            navigationItem.rightBarButtonItems = [gearBarButton, infoBarButton, historyBarButton]
        }
    }
}
