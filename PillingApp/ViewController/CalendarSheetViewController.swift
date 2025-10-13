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
    private let onSelectStatus: (PillStatus) -> Void
    private let disposeBag = DisposeBag()
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    init(selectedDate: Date, onSelectStatus: @escaping (PillStatus) -> Void) {
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
    }
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "상태 선택"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        view.addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        containerStack.addArrangedSubview(titleLabel)
        
        addStatusButton(title: "복용", status: .taken)
        addStatusButton(title: "2알 복용", status: .takenDouble)
        addMissedButton()
        
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(12) }
        containerStack.addArrangedSubview(spacer)
    }
    
    private func addStatusButton(title: String, status: PillStatus, isDestructive: Bool = false) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(isDestructive ? .systemRed : .label, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = .init(top: 12, left: 14, bottom: 12, right: 14)
        containerStack.addArrangedSubview(button)
        
        button.rx.tap
            .bind { [weak self] in
                self?.dismiss(animated: true)
                self?.onSelectStatus(status)
            }
            .disposed(by: disposeBag)
    }
    
    private func addMissedButton() {
        let button = UIButton(type: .system)
        button.setTitle("미복용", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = .init(top: 12, left: 14, bottom: 12, right: 14)
        containerStack.addArrangedSubview(button)
        
        button.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true)
                
                let calendar = Calendar.current
                let isToday = calendar.isDateInToday(self.selectedDate)
                let isInPast = self.selectedDate < calendar.startOfDay(for: Date())
                let status: PillStatus = isToday ? .scheduled : (isInPast ? .missed : .scheduled)
                self.onSelectStatus(status)
            }
            .disposed(by: disposeBag)
    }
}
