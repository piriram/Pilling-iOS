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
    
    private let viewModel: DashboardViewModel
    private let stasticsViewModel: StasticsViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - SubViews
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "background_taken"))
    private let infoView = DashboardMiddleView()
    private let stasticsView = StasticsContentView()
    private let bottomView = DashboardBottomView()
    
    private let containerView = UIView()
    private var currentViewIndex = 0 // 0: Dashboard, 1: Stastics
    
    // MARK: - 상단 버튼들
    private let historyButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let gearButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    var shouldHideHistoryButton: Bool = false {
        didSet {
            historyButton.isHidden = shouldHideHistoryButton
            historyButton.isEnabled = !shouldHideHistoryButton
        }
    }
    
    // MARK: - Initialization
    
    init(viewModel: DashboardViewModel, stasticsViewModel: StasticsViewModel) {
        self.viewModel = viewModel
        self.stasticsViewModel = stasticsViewModel
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
        bindViewModel()
        setupActions()
        updateBackgroundForToday()
        bindAlert()
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
        
        viewModel.reloadData()    }
    
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
        
        setupTopButtons()
        view.addSubview(historyButton)
        view.addSubview(infoButton)
        view.addSubview(gearButton)
        historyButton.isHidden = shouldHideHistoryButton
        historyButton.isEnabled = !shouldHideHistoryButton
        
        setupSwipeGestures()
    }
    
    private func setupConstraints() {
        let contentInset: CGFloat = 16
        
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(220)
        }
        
        gearButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            make.trailing.equalToSuperview().inset(contentInset)
            make.size.lessThanOrEqualTo(30)
        }
        infoButton.snp.makeConstraints { make in
            make.centerY.equalTo(gearButton)
            make.trailing.equalTo(gearButton.snp.leading).offset(-8)
            make.size.lessThanOrEqualTo(30)
        }
        historyButton.snp.makeConstraints { make in
            make.centerY.equalTo(gearButton)
            make.trailing.equalTo(infoButton.snp.leading).offset(-8)
            make.size.lessThanOrEqualTo(30)
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
                self?.showPeriodSelectionAlert(periodList: periodList)
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
    
    // MARK: - Actions
    private func setupActions() {
        infoButton.rx.tap
            .bind { [weak self] in
                self?.presentInfoFloatingView()
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
                guard let self = self else { return }
                let vm = DIContainer.shared.makePillCycleHistoryViewModel()
                let vc = CycleHistoryViewController(viewModel: vm)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        bottomView.takePillButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.takePill()
            }
            .disposed(by: disposeBag)
        
        infoView.onCalendarCellSelected = { [weak self] index, item in
            self?.presentCalendarSheet(for: index, item: item)
        }
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
    
    // MARK: - Presentation
    
    private func presentCalendarSheet(for index: Int, item: DayItem) {
        guard let cycle = viewModel.currentCycle.value else { return }
        
        CalendarSheetPresenter.present(
            from: self,
            selectedIndex: index,
            item: item,
            cycle: cycle
        ) { [weak self] idx, status, memo, takenAt in
            self?.viewModel.updateState(at: idx, to: status, memo: memo, takenAt: takenAt)
        }
        
    }
    
    private func presentInfoFloatingView() {
        let infoView = DashboardGuideView()
        infoView.onConfirm = { [weak infoView] in
            infoView?.dismiss()
        }
        infoView.show(in: self.view)
    }
    
    /// ViewModel의 alert 이벤트를 바인딩
    func bindAlert() {
        viewModel.showRetryAlert
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.presentRetryAlert(){[weak self] in
                    self?.viewModel.reloadData()
                    
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupTopButtons() {
        // info
        infoButton.setImage(DashboardUI.Icon.info, for: .normal)
        infoButton.tintColor = AppColor.secondary
        
        // history
        historyButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        historyButton.tintColor = AppColor.secondary
        
        // gear
        gearButton.setImage(DashboardUI.Icon.gear, for: .normal)
        gearButton.tintColor = AppColor.secondary
    }
    
    // MARK: - Swipe Gestures
    
    private func setupSwipeGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        containerView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        containerView.addGestureRecognizer(swipeRight)
    }
    
    @objc private func handleSwipeLeft() {
        if currentViewIndex == 0 {
            switchToView(index: 1, direction: .left)
        }
    }
    
    @objc private func handleSwipeRight() {
        if currentViewIndex == 1 {
            switchToView(index: 0, direction: .right)
        }
    }
    
    private func switchToView(index: Int, direction: UISwipeGestureRecognizer.Direction) {
        guard index != currentViewIndex else { return }
        
        let fromView = currentViewIndex == 0 ? infoView : stasticsView
        let toView = index == 0 ? infoView : stasticsView
        
        currentViewIndex = index
        
        // 페이지 컨트롤 업데이트
        bottomView.pageControl.numberOfPages = 2
        bottomView.pageControl.currentPage = index
        
        // 히스토리 버튼 표시/숨김
        historyButton.isHidden = (index == 1)
        historyButton.isEnabled = (index == 0)
        
        // 애니메이션 준비
        toView.isHidden = false
        toView.alpha = 0
        
        let screenWidth = view.bounds.width
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
    
    private func showPeriodSelectionAlert(periodList: [PeriodRecordDTO]) {
        let alert = UIAlertController(title: "기간 선택", message: nil, preferredStyle: .actionSheet)
        
        for (index, data) in periodList.enumerated() {
            let action = UIAlertAction(title: "\(data.startDate) - \(data.endDate)", style: .default) { [weak self] _ in
                self?.stasticsViewModel.selectPeriod(at: index)
            }
            if index == stasticsViewModel.getCurrentIndex() {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancelTitle, style: .cancel))
        
        present(alert, animated: true)
    }
}
