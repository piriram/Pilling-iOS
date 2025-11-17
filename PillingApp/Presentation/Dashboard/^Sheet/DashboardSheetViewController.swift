//
//  DashboardSheetViewController.swift
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
    
    // MARK: - Properties
    
    private let onDataChanged: (PillStatus?, String) -> Void
    private let onTimeChanged: ((Date) -> Void)?
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let disposeBag = DisposeBag()
    
    var titleText: String?
    
    private typealias str = AppStrings.Dashboard
    
    // MARK: - Components
    
    private lazy var sheetAnimator = DashboardSheetAnimator(
        viewController: self,
        sheetHeight: 480
    )
    
    private let statusSelectionView = StatusSelectionView()
    
    private lazy var sideEffectTagsView = SideEffectTagsView(
        userDefaultsManager: userDefaultsManager
    )
    
    // MARK: - UI Components
    
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
    
    private let timeSettingButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: AppStrings.Setting.timeSettingTitle, iconSystemName: "clock")
        return button
    }()
    
    // MARK: - ViewModel & Relays
    
    private let viewModel: DefaultDashboardSheetViewModel
    private let requestDismissRelay = PublishRelay<Void>()
    private let timeChangedRelay = PublishRelay<Date>()
    
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
        self.onDataChanged = onDataChanged
        self.onTimeChanged = onTimeChanged
        self.userDefaultsManager = userDefaultsManager

        // 초기 메모에서 부작용 태그 파싱
        let parsedMemo = PillRecordMemo.fromJSONString(initialMemo)

        self.viewModel = DefaultDashboardSheetViewModel(
            selectedDate: selectedDate,
            initialMemo: parsedMemo.text,
            initialStatus: initialStatus,
            takenAt: takenAt
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve

        // 부작용 태그 선택 복원 (뷰가 생성된 후에 설정해야 함)
        DispatchQueue.main.async { [weak self] in
            self?.sideEffectTagsView.setSelectedTagIds(parsedMemo.sideEffectIds)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupGestures()
        bindComponents()
        bindViewModel()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        sheetAnimator.setupViews(in: view)
        
        sheetAnimator.containerView.addSubview(contentStackView)
        
        subtitleLabel.text = titleText ?? title
        contentStackView.addArrangedSubview(subtitleLabel)
        contentStackView.addArrangedSubview(statusSelectionView)
        contentStackView.addArrangedSubview(timeSettingButton)
        contentStackView.addArrangedSubview(sideEffectTagsView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(sheetAnimator.handleBar.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        timeSettingButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }
    
    private func setupGestures() {
        let dimmedTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmedViewTap))
        sheetAnimator.dimmedView.addGestureRecognizer(dimmedTapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        sheetAnimator.containerView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Component Binding
    
    private func bindComponents() {
        sideEffectTagsView.addButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.presentSideEffectManagement()
            })
            .disposed(by: disposeBag)
        
        timeSettingButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentTimePickerBottomSheet()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - ViewModel Binding
    
    private func bindViewModel() {
        let input = DashboardSheetViewModelInput(
            viewDidAppear: rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
                .map { _ in () }
                .take(1),
            tapNotTaken: statusSelectionView.notTakenTapped.asObservable(),
            tapTaken: statusSelectionView.takenTapped.asObservable(),
            tapTakenDouble: statusSelectionView.takenDoubleTapped.asObservable(),
            memoText: Observable.just(""),
            requestDismiss: requestDismissRelay.asObservable(),
            timeChanged: timeChangedRelay.asObservable()
        )
        
        let output = viewModel.transform(input)
        
        output.shouldShowSheet
            .emit(onNext: { [weak self] in
                self?.sheetAnimator.show()
            })
            .disposed(by: disposeBag)
        
        output.initialButtonTag
            .drive(onNext: { [weak self] buttonTag in
                self?.statusSelectionView.setInitialSelection(buttonTag: buttonTag)
            })
            .disposed(by: disposeBag)
        
        output.formattedTime
            .drive(onNext: { [weak self] timeString in
                self?.timeSettingButton.setValue(timeString)
            })
            .disposed(by: disposeBag)
        
//        output.isMemoPlaceholderHidden
//            .drive()
//            .disposed(by: disposeBag)
//        
        output.dismiss
            .emit(onNext: { [weak self] status, memoText in
                guard let self else { return }

                // 선택된 부작용 태그 ID 수집
                let selectedTagIds = self.sideEffectTagsView.getSelectedTagIds()

                // PillRecordMemo로 결합하여 JSON 저장
                let pillMemo = PillRecordMemo(text: memoText, sideEffectIds: selectedTagIds)
                let memoJSON = pillMemo.toJSONString()

                self.onDataChanged(status, memoJSON)
                self.sheetAnimator.hide()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleDimmedViewTap() {
        requestDismissRelay.accept(())
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        sheetAnimator.handlePanGesture(gesture) { [weak self] in
            self?.requestDismissRelay.accept(())
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Time Picker
    
    private func presentTimePickerBottomSheet() {
        let timePickerSheet = TimePickerBottomSheet(initialTime: Date())
        
        timePickerSheet.selectedTime
            .take(1)
            .subscribe(onNext: { [weak self] selectedTime in
                guard let self = self else { return }
                self.timeChangedRelay.accept(selectedTime)
                self.onTimeChanged?(selectedTime)
            })
            .disposed(by: disposeBag)
        
        present(timePickerSheet, animated: false)
    }
    
    // MARK: - Navigation
    
    private func presentSideEffectManagement() {
        let managementVC = SideEffectManagementViewController(userDefaultsManager: userDefaultsManager)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.pushViewController(managementVC, animated: true)
    }
}
