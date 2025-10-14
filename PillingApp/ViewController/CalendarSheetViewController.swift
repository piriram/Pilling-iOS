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
import IQKeyboardManagerSwift

// MARK: - Presentation/Dashboard/Views/CalendarSheetViewController.swift

final class CalendarSheetViewController: UIViewController {
    private let selectedDate: Date
    private let onSelectStatus: (PillStatus, String) -> Void
    private let disposeBag = DisposeBag()
    
    private var currentStatus: PillStatus?
    
    var titleText: String?
    
    private let memoTextView: UITextView = {
        let tv = UITextView()
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.font = .systemFont(ofSize: 15, weight: .regular)
        tv.textColor = AppColor.textBlack
        tv.backgroundColor = AppColor.grayBackground
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth = 1
        tv.layer.borderColor = AppColor.borderGray.cgColor
        tv.isScrollEnabled = true
        tv.textContainer.lineFragmentPadding = 0
        tv.keyboardDismissMode = .interactive
        return tv
    }()
    
    private let memoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "메모를 입력하세요"
        label.textColor = AppColor.textGray
        label.font = .systemFont(ofSize: 15, weight: .regular)
        return label
    }()
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()
    
    // MARK: - Custom Segmented Control
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
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.headline5(.semibold)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private let dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.borderGray
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    init(selectedDate: Date, onSelectStatus: @escaping (PillStatus, String) -> Void) {
        self.selectedDate = selectedDate
        self.onSelectStatus = onSelectStatus
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindStatusButtons()
        setupKeyboardDismissGesture()
        bindMemoTextView()
        self.presentationController?.delegate = self
    }
    
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
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(dragIndicator)
        dragIndicator.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(5)
        }
        
        subtitleLabel.text = titleText ?? self.title
        subtitleLabel.font = Typography.headline5(.semibold)
        
        view.addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.top.equalTo(dragIndicator.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        containerStack.addArrangedSubview(subtitleLabel)
        
        // Setup custom segmented control
        containerStack.addArrangedSubview(statusButtonsContainer)
        statusButtonsContainer.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        statusButtonsContainer.addSubview(statusButtonsStack)
        statusButtonsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        statusButtonsStack.addArrangedSubview(notTakenButton)
        statusButtonsStack.addArrangedSubview(takenButton)
        statusButtonsStack.addArrangedSubview(takenDoubleButton)
        
        containerStack.addArrangedSubview(memoTextView)
        memoTextView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
        
        memoTextView.addSubview(memoPlaceholderLabel)
        memoPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalTo(memoTextView).inset(12)
            make.leading.equalTo(memoTextView).inset(12)
        }
        
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(20) }
        containerStack.addArrangedSubview(spacer)
    }
    
    private func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func bindStatusButtons() {
        let buttons = [notTakenButton, takenButton, takenDoubleButton]
        
        buttons.forEach { button in
            button.rx.tap
                .bind { [weak self] in
                    guard let self = self else { return }
                    self.selectButton(tag: button.tag)
                    
                    let status: PillStatus?
                    switch button.tag {
                    case 0:
                        let calendar = Calendar.current
                        let isToday = calendar.isDateInToday(self.selectedDate)
                        let isInPast = self.selectedDate < calendar.startOfDay(for: Date())
                        status = isToday ? .scheduled : (isInPast ? .missed : .todayNotTaken)
                    case 1:
                        status = .taken
                    case 2:
                        status = .takenDouble
                    default:
                        status = nil
                    }
                    
                    if let status = status {
                        self.currentStatus = status
                        self.dismiss(animated: true)
                        self.onSelectStatus(status, self.memoTextView.text ?? "")
                    }
                }
                .disposed(by: disposeBag)
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
    
    func setInitialSelection(for status: PillStatus) {
        let tag: Int
        switch status {
        case .missed, .scheduled, .todayNotTaken, .todayDelayed:
            tag = 0
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed:
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
}

extension CalendarSheetViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if let status = currentStatus {
            onSelectStatus(status, memoTextView.text ?? "")
        } else {
            let calendar = Calendar.current
            let isToday = calendar.isDateInToday(self.selectedDate)
            let isInPast = self.selectedDate < calendar.startOfDay(for: Date())
            let fallbackStatus: PillStatus = isToday ? .scheduled : (isInPast ? .missed : .scheduled)
            onSelectStatus(fallbackStatus, memoTextView.text ?? "")
        }
    }
}
