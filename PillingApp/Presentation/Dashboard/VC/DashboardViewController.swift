//
//  DashboardViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class DashboardViewController: UIViewController {
    
    // MARK: - ViewModels

    private let viewModel: DashboardViewModel
    private let stasticsViewModel: StatisticsViewModel
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let timeProvider: TimeProvider
    private let disposeBag = DisposeBag()

    // MARK: - Managers & Coordinators

    private lazy var coordinator = DashboardCoordinator(navigationController: navigationController)
    private lazy var sheetPresenter = DashboardSheetPresenter(
        viewController: self,
        userDefaultsManager: userDefaultsManager,
        timeProvider: timeProvider
    )
    private var transitionManager: DashboardViewTransitionManager?
    private var bindingManager: DashboardViewBindingManager?
    
    // MARK: - SubViews
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "background_taken"))
    private let topButtonsView = DashboardTopButtonsView()
    private let infoView = DashboardMiddleView()
    private let stasticsView = StatisticsContentView()
    private let bottomView = DashboardBottomView()
    private let containerView = UIView()
    
    // MARK: - Properties
    
    var shouldHideHistoryButton: Bool = false {
        didSet {
            topButtonsView.isHistoryButtonHidden = shouldHideHistoryButton
        }
    }
    
    // MARK: - Initialization

    init(
        viewModel: DashboardViewModel,
        stasticsViewModel: StatisticsViewModel,
        userDefaultsManager: UserDefaultsManagerProtocol,
        timeProvider: TimeProvider
    ) {
        self.viewModel = viewModel
        self.stasticsViewModel = stasticsViewModel
        self.userDefaultsManager = userDefaultsManager
        self.timeProvider = timeProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
        setupTransitionManager()
        setupBindingManager()
        updateBackgroundForToday()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        infoView.updateCalendarLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .left, .right, .bottom]
        
        viewModel.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = AppColor.bg
        
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        view.addSubview(containerView)
        
        containerView.addSubview(infoView)
        containerView.addSubview(stasticsView)
        stasticsView.isHidden = true
        
        view.addSubview(bottomView)
        view.addSubview(topButtonsView)
        
        topButtonsView.isHistoryButtonHidden = shouldHideHistoryButton
    }
    
    private func setupConstraints() {
        DashboardViewLayout.setupConstraints(
            in: view,
            backgroundImageView: backgroundImageView,
            topButtonsView: topButtonsView,
            containerView: containerView,
            infoView: infoView,
            stasticsView: stasticsView,
            bottomView: bottomView
        )
    }
    
    private func setupTransitionManager() {
        transitionManager = DashboardViewTransitionManager(
            containerView: containerView,
            infoView: infoView,
            statisticsView: stasticsView
        )

        transitionManager?.onViewIndexChanged = { [weak self] index in
            self?.handleViewIndexChanged(index)
        }

        // 초기 페이지 컨트롤 상태 설정
        handleViewIndexChanged(.calendar)
    }
    
    private func setupBindingManager() {
        bindingManager = DashboardViewBindingManager(
            viewModel: viewModel,
            stasticsViewModel: stasticsViewModel
        )
        
        bindingManager?.bindAll(
            infoView: infoView,
            bottomView: bottomView,
            topButtonsView: topButtonsView,
            stasticsView: stasticsView,
            coordinator: coordinator,
            sheetPresenter: sheetPresenter,
            onBackgroundUpdate: { [weak self] in
                self?.updateBackgroundForToday()
            },
            onRetryAlert: { [weak self] retryHandler in
                self?.presentRetryAlert(retryHandler: retryHandler)
            }
        )
    }
    
    // MARK: - UI Updates
    
    private func updateBackgroundForToday() {
        guard let cycle = viewModel.currentCycle.value else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let todayRecord = cycle.records.first(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            backgroundImageView.image = UIImage(named: "background")
            return
        }
        
        let adjustedStatus = todayRecord.status.adjustedForDate(todayRecord.scheduledDateTime, calendar: calendar)
        backgroundImageView.image = UIImage(named: adjustedStatus.backgroundImageName)
    }
    
    private func handleViewIndexChanged(_ index: DashboardViewTransitionManager.ViewIndex) {
        bottomView.pageControl.numberOfPages = 2
        bottomView.pageControl.currentPage = index.rawValue
        
        topButtonsView.isHistoryButtonHidden = (index == .statistics)
    }
}
