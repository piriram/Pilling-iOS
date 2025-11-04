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

// MARK: - Presentation/Dashboard/Views/DashboardViewController.swift

final class DashboardViewController: UIViewController {
    
    private let viewModel: DashboardViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - SubViews
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "background_taken"))
    private let infoView = DashboardInfoView()
    private let calendarView = DashboardCalendarView()
    private let bottomView = DashboardBottomView()
    
    // MARK: - Properties
    
    var shouldHideHistoryButton: Bool = true {
        didSet {
            infoView.historyButton.isHidden = shouldHideHistoryButton
            infoView.historyButton.isEnabled = !shouldHideHistoryButton
        }
    }
    
    // MARK: - Initialization
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calendarView.updateLayout()
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
        
        view.addSubview(infoView)
        view.addSubview(calendarView)
        view.addSubview(bottomView)
        
        infoView.historyButton.isHidden = shouldHideHistoryButton
        infoView.historyButton.isEnabled = !shouldHideHistoryButton
    }
    
    private func setupConstraints() {
        let contentInset: CGFloat = 16
        
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(220)
        }
        
        infoView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        calendarView.snp.makeConstraints { make in
            make.top.equalTo(infoView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(calendarView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(contentInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        // Calendar items
        viewModel.items
            .asDriver()
            .drive(onNext: { [weak self] items in
                self?.calendarView.applySnapshot(with: items)
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
            .asDriver(onErrorJustReturn: PillCycle(
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
                self?.calendarView.updateWeekdayStart(from: cycle.startDate)
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
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        // Info button
        infoView.infoButton.rx.tap
            .bind { [weak self] in
                self?.presentInfoFloatingView()
            }
            .disposed(by: disposeBag)
        
        // Gear button
        infoView.gearButton.rx.tap
            .bind { [weak self] in
                let vm = DIContainer.shared.makeSettingViewModel()
                let vc = SettingViewController(viewModel: vm)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        // History button
        infoView.historyButton.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                let vm = DIContainer.shared.makePillCycleHistoryViewModel()
                let vc = PillCycleHistoryViewController(viewModel: vm)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        // Take pill button
        bottomView.takePillButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.takePill()
            }
            .disposed(by: disposeBag)
        
        // Calendar cell selection
        calendarView.onCellSelected = { [weak self] index, item in
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
        if #available(iOS 16.0, *) {
            CalendarSheetPresenter.present(
                from: self,
                selectedIndex: index,
                item: item,
                cycle: cycle
            ) { [weak self] idx, status, memo in
                self?.viewModel.updateState(at: idx, to: status, memo: memo)
            }
        }
    }
    
    private func presentInfoFloatingView() {
        let infoView = DashboardGuideView()
        infoView.onConfirm = { [weak infoView] in
            infoView?.dismiss()
        }
        infoView.show(in: self.view)
    }
}
