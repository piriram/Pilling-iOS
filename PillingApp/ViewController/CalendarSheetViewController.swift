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

// MARK: - Presentation/Dashboard/Views/CalendarSheetViewController.swift

final class CalendarSheetViewController: UIViewController {
    private let selectedDate: Date
    private let onSelectStatus: (PillStatus, String) -> Void
    private let disposeBag = DisposeBag()
    
    private var currentStatus: PillStatus?
    var titleText: String?
    
    // MARK: - Bottom Sheet Properties
    
    private let sheetHeight: CGFloat = 350
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
    
    private let memoTextView: UITextView = {
        let textView = UITextView()
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.font = .systemFont(ofSize: 15, weight: .regular)
        textView.textColor = AppColor.textBlack
        textView.backgroundColor = AppColor.grayBackground
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = AppColor.borderGray.cgColor
        textView.isScrollEnabled = true
        textView.textContainer.lineFragmentPadding = 0
        textView.keyboardDismissMode = .interactive
        return textView
    }()
    
    private let memoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "메모를 입력하세요"
        label.textColor = AppColor.textGray
        label.font = .systemFont(ofSize: 15, weight: .regular)
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
    
    private lazy var notTakenButton = createStatusButton(title: "미복용", tag: 0)
    private lazy var takenButton = createStatusButton(title: "복용", tag: 1)
    private lazy var takenDoubleButton = createStatusButton(title: "2알 복용", tag: 2)
    
    private var selectedButtonTag: Int = -1
    
    // MARK: - Initialization
    
    init(selectedDate: Date, onSelectStatus: @escaping (PillStatus, String) -> Void) {
        self.selectedDate = selectedDate
        self.onSelectStatus = onSelectStatus
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
        bindStatusButtons()
        bindMemoTextView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showBottomSheet()
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
        
        contentStackView.addArrangedSubview(memoTextView)
        memoTextView.addSubview(memoPlaceholderLabel)
        
        setupConstraints()
    }
    
    private func setupStatusButtons() {
        contentStackView.addArrangedSubview(statusButtonsContainer)
        
        statusButtonsContainer.addSubview(statusButtonsStack)
        statusButtonsStack.addArrangedSubview(notTakenButton)
        statusButtonsStack.addArrangedSubview(takenButton)
        statusButtonsStack.addArrangedSubview(takenDoubleButton)
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
        
        memoTextView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
        
        memoPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalTo(memoTextView).inset(12)
            make.leading.equalTo(memoTextView).inset(12)
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
    
    // MARK: - Binding
    
    private func bindStatusButtons() {
        let buttons = [notTakenButton, takenButton, takenDoubleButton]
        
        buttons.forEach { button in
            button.rx.tap
                .bind { [weak self] in
                    guard let self = self else { return }
                    self.selectButton(tag: button.tag)
                    
                    let status = self.determineStatus(for: button.tag)
                    
                    if let status = status {
                        self.currentStatus = status
                        self.hideBottomSheet {
                            self.onSelectStatus(status, self.memoTextView.text ?? "")
                        }
                    }
                }
                .disposed(by: disposeBag)
        }
    }
    
    private func bindMemoTextView() {
        memoPlaceholderLabel.isHidden = !(memoTextView.text?.isEmpty ?? true)
        
        memoTextView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind { [weak self] hasText in
                self?.memoPlaceholderLabel.isHidden = hasText
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Status Logic
    
    private func determineStatus(for tag: Int) -> PillStatus? {
        switch tag {
        case 0:
            let calendar = Calendar.current
            let isToday = calendar.isDateInToday(selectedDate)
            let isInPast = selectedDate < calendar.startOfDay(for: Date())
            return isToday ? .scheduled : (isInPast ? .missed : .todayNotTaken)
        case 1:
            return .taken
        case 2:
            return .takenDouble
        default:
            return nil
        }
    }
    
    private func selectButton(tag: Int) {
        let buttons = [notTakenButton, takenButton, takenDoubleButton]
        selectedButtonTag = tag
        
        buttons.forEach { button in
            let isSelected = button.tag == tag
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
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
        case .missed, .scheduled, .todayNotTaken, .todayDelayed:
            tag = 0
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed, .todayTakenTooEarly, .takenTooEarly:
            tag = 1
        case .takenDouble:
            tag = 2
        case .rest:
            tag = -1
        }
        
        if tag >= 0 {
            selectButton(tag: tag)
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
        handleSheetDismiss()
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
                hideBottomSheet {
                    self.handleSheetDismiss()
                }
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
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
        if let status = currentStatus {
            onSelectStatus(status, memoTextView.text ?? "")
        } else {
            let calendar = Calendar.current
            let isToday = calendar.isDateInToday(selectedDate)
            let isInPast = selectedDate < calendar.startOfDay(for: Date())
            let fallbackStatus: PillStatus = isToday ? .scheduled : (isInPast ? .missed : .scheduled)
            onSelectStatus(fallbackStatus, memoTextView.text ?? "")
        }
        hideBottomSheet()
    }
}
