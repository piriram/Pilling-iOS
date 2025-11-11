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
    private let stasticsViewModel: StasticsViewModel
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Managers & Coordinators
    
    private lazy var coordinator = DashboardCoordinator(navigationController: navigationController)
    private lazy var sheetPresenter = DashboardSheetPresenter(
        viewController: self,
        userDefaultsManager: userDefaultsManager
    )
    private var transitionManager: DashboardViewTransitionManager?
    
    // MARK: - SubViews
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "background_taken"))
    private let topButtonsView = DashboardTopButtonsView()
    private let infoView = DashboardMiddleView()
    private let stasticsView = StasticsContentView()
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
        stasticsViewModel: StasticsViewModel,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        self.viewModel = viewModel
        self.stasticsViewModel = stasticsViewModel
        self.userDefaultsManager = userDefaultsManager
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
        
        bindViewModel()
        
        bindTopButtons()
        
        bindBottomView()
        
        bindAlert()
        
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
    
    // MARK: - Touch Debugging
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: view)
            
            // Check which view would receive this touch
            if let hitView = view.hitTest(location, with: event) {
                
                // Check if touch is in button areas
                let topButtonsLocation = touch.location(in: topButtonsView)
                let bottomViewLocation = touch.location(in: bottomView)
                
            } else {
                
            }
        }
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
        let contentInset: CGFloat = 16
        
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(220)
        }
        
        topButtonsView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            make.trailing.equalToSuperview().inset(contentInset)
            make.height.equalTo(30)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        infoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stasticsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(contentInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
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
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        // Calendar items
        viewModel.items
            .asDriver()
            .drive(onNext: { [weak self] items in
                self?.infoView.applyCalendarSnapshot(with: items)
                self?.bottomView.updatePageControl(for: items.count)
            })
            .disposed(by: disposeBag)
        
        // Pill info
        viewModel.pillInfo
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: PillInfo(name: "", takingDays: 0, breakDays: 0))
            .drive(onNext: { [weak self] pillInfo in
                self?.infoView.configure(with: pillInfo)
            })
            .disposed(by: disposeBag)
        
        // Current cycle
        viewModel.currentCycle
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: Cycle(
                id: UUID(),
                cycleNumber: 1,
                startDate: Date(),
                activeDays: 21,
                breakDays: 7,
                scheduledTime: "09:00",
                records: [],
                createdAt: Date()
            ))
            .drive(onNext: { [weak self] cycle in
                self?.infoView.configure(with: cycle)
                self?.infoView.updateCalendarWeekdayStart(from: cycle.startDate)
                self?.updateBackgroundForToday()
            })
            .disposed(by: disposeBag)
        
        // Dashboard message
        viewModel.dashboardMessage
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: DashboardMessage(text: "", imageName: .rest, icon: .rest))
            .drive(onNext: { [weak self] message in
                self?.infoView.configure(with: message)
                self?.updateBackgroundForToday()
            })
            .disposed(by: disposeBag)
        
        // Can take pill
        Observable.combineLatest(
            viewModel.canTakePill.asObservable(),
            viewModel.currentCycle.asObservable()
        )
        .asDriver(onErrorJustReturn: (false, nil))
        .drive(onNext: { [weak self] canTake, cycle in
            self?.bottomView.updateButton(canTake: canTake, cycle: cycle)
        })
        .disposed(by: disposeBag)
        
        // Calendar cell selection
        infoView.onCalendarCellSelected = { [weak self] index, item in
            guard let self = self,
                  let cycle = self.viewModel.currentCycle.value else { return }
            
            self.sheetPresenter.presentCalendarSheet(
                for: index,
                item: item,
                cycle: cycle,
                onStatusUpdate: { [weak self] index, status, memo, takenAt in
                    self?.viewModel.updateState(
                        at: index,
                        to: status,
                        memo: memo,
                        takenAt: takenAt
                    )
                }
            )
        }
        
        bindStasticsViewModel()
    }
    
    private func bindStasticsViewModel() {
        let viewDidLoadSubject = PublishSubject<Void>()
        let leftArrowTappedSubject = PublishSubject<Void>()
        let rightArrowTappedSubject = PublishSubject<Void>()
        let periodButtonTappedSubject = PublishSubject<Void>()
        
        let input = StasticsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            leftArrowTapped: leftArrowTappedSubject.asObservable(),
            rightArrowTapped: rightArrowTappedSubject.asObservable(),
            periodButtonTapped: periodButtonTappedSubject.asObservable()
        )
        
        let output = stasticsViewModel.transform(input: input)
        
        output.currentPeriodData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                self?.stasticsView.configure(with: data)
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(output.isLeftArrowEnabled, output.isRightArrowEnabled)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLeftEnabled, isRightEnabled in
                self?.stasticsView.updateArrowButtons(
                    isLeftEnabled: isLeftEnabled,
                    isRightEnabled: isRightEnabled
                )
            })
            .disposed(by: disposeBag)
        
        output.periodList
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] periodList in
                guard let self = self else { return }
                self.sheetPresenter.showPeriodSelectionAlert(
                    periodList: periodList,
                    currentIndex: self.stasticsViewModel.getCurrentIndex(),
                    onPeriodSelected: { [weak self] index in
                        self?.stasticsViewModel.selectPeriod(at: index)
                    }
                )
            })
            .disposed(by: disposeBag)
        
        stasticsView.leftArrowTapped = {
            leftArrowTappedSubject.onNext(())
        }
        
        stasticsView.rightArrowTapped = {
            rightArrowTappedSubject.onNext(())
        }
        
        stasticsView.periodButtonTapped = {
            periodButtonTappedSubject.onNext(())
        }
        
        viewDidLoadSubject.onNext(())
    }
    
    private func bindTopButtons() {
        
        topButtonsView.historyButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.coordinator.navigateToCycleHistory()
            })
            .disposed(by: disposeBag)
        
        topButtonsView.infoButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.sheetPresenter.presentInfoFloatingView()
            })
            .disposed(by: disposeBag)
        
        topButtonsView.gearButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.coordinator.navigateToSettings()
            })
            .disposed(by: disposeBag)
        
    }
    
    private func bindBottomView() {
        
        bottomView.takePillButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.takePill()
            })
            .disposed(by: disposeBag)
        
    }
    
    private func bindAlert() {
        viewModel.showRetryAlert
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.presentRetryAlert { [weak self] in
                    self?.viewModel.reloadData()
                }
            })
            .disposed(by: disposeBag)
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

