//
//  CalendarSheetViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - DashboardSheetViewController
final class DashboardSheetViewController: UIViewController {
    private let selectedDate: Date
    private let initialMemo: String
    private let takenAt: Date?
    private let onDataChanged: (PillStatus?, String) -> Void
    private let onTimeChanged: ((Date) -> Void)?
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let disposeBag = DisposeBag()
    
    private var currentStatus: PillStatus?
    var titleText: String?
    private typealias str = AppStrings.Dashboard
    
    private var sideEffectTags: [SideEffectTag] = []
    private var selectedTagIndices: Set<Int> = []
    
    // MARK: - Bottom Sheet Properties
    
    private let sheetHeight: CGFloat = 480
    private var currentSheetY: CGFloat = 0
    
    // MARK: - UI Components
    
    private let dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()
    
    private let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.borderGray
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.headline5(.semibold)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()
    
    // MARK: - Status Selection Components
    
    private let statusButtonsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.grayBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let statusButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        return stack
    }()
    
    private lazy var notTakenButton = createStatusButton(title: str.guideMissed, tag: 0)
    private lazy var takenButton = createStatusButton(title: str.taken, tag: 1)
    private lazy var takenDoubleButton = createStatusButton(title: str.takenDouble, tag: 2)
    
    private var selectedButtonTag: Int = -1
    
    // MARK: - Time Setting Button
    
    private let timeSettingButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: AppStrings.Setting.timeSettingTitle, iconSystemName: "clock")
        return button
    }()
    
    // MARK: - Side Effect Tags CollectionView
    
    private let sideEffectSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 컨디션"
        label.font = Typography.body1(.semibold)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private lazy var sideEffectCollectionView: UICollectionView = {
        let layout = createCollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SideEffectTagCell.self, forCellWithReuseIdentifier: SideEffectTagCell.identifier)
        collectionView.register(SideEffectAddButtonCell.self, forCellWithReuseIdentifier: SideEffectAddButtonCell.identifier)
        return collectionView
    }()
    
    // MARK: - ViewModel & Relays (MVVM I/O)
    
    private let viewModel: DefaultDashboardSheetViewModel
    private let requestDismissRelay = PublishRelay<Void>()
    
    // MARK: - Initialization
    
    init(
        selectedDate: Date,
        initialMemo: String = "",
        takenAt: Date? = nil,
        initialStatus: PillStatus? = nil,
        userDefaultsManager: UserDefaultsManagerProtocol,
        onDataChanged: @escaping (PillStatus?, String) -> Void,
        onTimeChanged: ((Date) -> Void)? = nil
    ) {
        self.selectedDate = selectedDate
        self.initialMemo = initialMemo
        self.takenAt = takenAt
        self.onDataChanged = onDataChanged
        self.onTimeChanged = onTimeChanged
        self.currentStatus = initialStatus
        self.userDefaultsManager = userDefaultsManager
        self.viewModel = DefaultDashboardSheetViewModel(
            selectedDate: selectedDate,
            initialMemo: initialMemo,
            initialStatus: initialStatus
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupGestures()
        loadSideEffectTags()
        setupTimeSettingButton()
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        
        containerView.addSubview(handleBar)
        containerView.addSubview(contentStackView)
        
        subtitleLabel.text = titleText ?? title
        contentStackView.addArrangedSubview(subtitleLabel)
        
        setupStatusButtons()
        
        // 부작용 태그 섹션 추가
        contentStackView.addArrangedSubview(sideEffectSectionLabel)
        contentStackView.addArrangedSubview(sideEffectCollectionView)
        
        setupConstraints()
    }
    
    private func setupStatusButtons() {
        contentStackView.addArrangedSubview(statusButtonsContainer)
        
        statusButtonsContainer.addSubview(statusButtonsStack)
        statusButtonsStack.addArrangedSubview(notTakenButton)
        statusButtonsStack.addArrangedSubview(takenButton)
        statusButtonsStack.addArrangedSubview(takenDoubleButton)
        
        contentStackView.addArrangedSubview(timeSettingButton)
    }
    
    private func setupConstraints() {
        dimmedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(sheetHeight)
            make.top.equalTo(view.snp.bottom)
        }
        
        handleBar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(5)
        }
        
        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(handleBar.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        statusButtonsContainer.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        statusButtonsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        timeSettingButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        
        sideEffectCollectionView.snp.makeConstraints { make in
            make.height.equalTo(120) // 3줄 정도 높이
        }
    }
    
    private func setupGestures() {
        let dimmedTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmedViewTap))
        dimmedView.addGestureRecognizer(dimmedTapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        containerView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupTimeSettingButton() {
        if let takenAt = takenAt {
            let timeString = takenAt.formatted(style: .time24Hour)
            timeSettingButton.setValue(timeString)
        } else {
            timeSettingButton.setValue("-")
        }
        
        timeSettingButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentTimePickerBottomSheet()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Side Effect Tags
    
    private func loadSideEffectTags() {
        let allTags = userDefaultsManager.loadSideEffectTags()
        sideEffectTags = allTags.filter { $0.isVisible }.sorted { $0.order < $1.order }
        sideEffectCollectionView.reloadData()
    }
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(80),
            heightDimension: .absolute(36)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(36)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(8)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    // MARK: - MVVM Binding
    
    private func bindViewModel() {
        let input = DefaultDashboardSheetViewModel.Input(
            viewDidAppear: rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
                .map { _ in () }
                .take(1),
            tapNotTaken: notTakenButton.rx.tap.asObservable(),
            tapTaken: takenButton.rx.tap.asObservable(),
            tapTakenDouble: takenDoubleButton.rx.tap.asObservable(),
            memoText: Observable.just(""), // 메모 기능 제거됨
            requestDismiss: requestDismissRelay.asObservable()
        )
        
        let output = viewModel.transform(input)
        
        output.shouldShowSheet
            .emit(onNext: { [weak self] in
                self?.showBottomSheet()
            })
            .disposed(by: disposeBag)
        
        output.selectedIndex
            .drive(onNext: { [weak self] index in
                guard let self, let tag = index else { return }
                self.selectButton(tag: tag)
            })
            .disposed(by: disposeBag)
        
        output.isMemoPlaceholderHidden
            .drive()
            .disposed(by: disposeBag)
        
        output.dismiss
            .emit(onNext: { [weak self] status, memo in
                guard let self else { return }
                self.onDataChanged(status, memo)
                self.hideBottomSheet()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Status Button Creation
    
    private func createStatusButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.tag = tag
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(AppColor.textGray, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        return button
    }
    
    // MARK: - Selection UI
    
    private func selectButton(tag: Int) {
        let buttons = [notTakenButton, takenButton, takenDoubleButton]
        selectedButtonTag = tag
        
        buttons.forEach { button in
            let isSelected = button.tag == tag
            
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5
            ) {
                button.isSelected = isSelected
                button.backgroundColor = isSelected ? AppColor.pillGreen800 : .clear
                button.titleLabel?.font = isSelected
                ? .systemFont(ofSize: 14, weight: .semibold)
                : .systemFont(ofSize: 14, weight: .medium)
                
                if isSelected {
                    button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                    button.layer.shadowColor = AppColor.pillGreen800.cgColor
                    button.layer.shadowOffset = CGSize(width: 0, height: 2)
                    button.layer.shadowOpacity = 0.3
                    button.layer.shadowRadius = 4
                } else {
                    button.transform = .identity
                    button.layer.shadowOpacity = 0
                }
            }
        }
    }
    
    func setInitialSelection(for status: PillStatus) {
        let tag: Int
        switch status {
        case .missed, .scheduled, .todayNotTaken, .todayDelayed, .todayDelayedCritical:
            tag = 0
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed, .todayTakenTooEarly, .takenTooEarly:
            tag = 1
        case .takenDouble:
            tag = 2
        case .rest:
            tag = -1
        }
        
        guard tag >= 0 else { return }
        selectButton(tag: tag)
        switch tag {
        case 0: notTakenButton.sendActions(for: .touchUpInside)
        case 1: takenButton.sendActions(for: .touchUpInside)
        case 2: takenDoubleButton.sendActions(for: .touchUpInside)
        default: break
        }
        currentStatus = status
    }
    
    // MARK: - Bottom Sheet Animations
    
    private func showBottomSheet() {
        containerView.snp.updateConstraints { make in
            make.top.equalTo(view.snp.bottom).offset(-sheetHeight)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimmedView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideBottomSheet(completion: (() -> Void)? = nil) {
        containerView.snp.updateConstraints { make in
            make.top.equalTo(view.snp.bottom)
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.dimmedView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleDimmedViewTap() {
        requestDismissRelay.accept(())
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            let shouldDismiss = translation.y > sheetHeight / 3 || velocity.y > 1000
            
            if shouldDismiss {
                requestDismissRelay.accept(())
            } else {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.5
                ) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func handleSheetDismiss() {
        requestDismissRelay.accept(())
    }
    
    // MARK: - Time Picker
    
    private func presentTimePickerBottomSheet() {
        let initialTime = takenAt ?? Date()
        let timePickerSheet = TimePickerBottomSheet(initialTime: initialTime)
        
        timePickerSheet.selectedTime
            .take(1)
            .subscribe(onNext: { [weak self] selectedTime in
                guard let self = self else { return }
                
                let timeString = selectedTime.formatted(style: .time24Hour)
                self.timeSettingButton.setValue(timeString)
                
                self.onTimeChanged?(selectedTime)
            })
            .disposed(by: disposeBag)
        
        present(timePickerSheet, animated: false)
    }
    
    // MARK: - Navigation
    
    private func presentSideEffectManagement() {
        let managementVC = SideEffectManagementViewController(userDefaultsManager: userDefaultsManager)
        navigationController?.pushViewController(managementVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension DashboardSheetViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sideEffectTags.count + 1 // +1 for add button
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // 마지막 셀은 + 버튼
        if indexPath.item == sideEffectTags.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SideEffectAddButtonCell.identifier, for: indexPath) as! SideEffectAddButtonCell
            return cell
        }
        
        // 일반 태그 셀
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SideEffectTagCell.identifier, for: indexPath) as! SideEffectTagCell
        let tag = sideEffectTags[indexPath.item]
        let isSelected = selectedTagIndices.contains(indexPath.item)
        cell.configure(with: tag.name, isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension DashboardSheetViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // + 버튼 클릭
        if indexPath.item == sideEffectTags.count {
            presentSideEffectManagement()
            return
        }
        
        // 태그 선택/해제
        if selectedTagIndices.contains(indexPath.item) {
            selectedTagIndices.remove(indexPath.item)
        } else {
            selectedTagIndices.insert(indexPath.item)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}
