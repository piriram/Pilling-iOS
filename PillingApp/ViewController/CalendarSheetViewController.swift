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
    private let onSelectStatus: (PillStatus) -> Void
    private let disposeBag = DisposeBag()
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    init(onSelectStatus: @escaping (PillStatus) -> Void) {
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
        addStatusButton(title: "지연 복용", status: .takenDelayed)
        addStatusButton(title: "2알 복용", status: .takenDouble)
        addStatusButton(title: "미복용", status: .missed)
        
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.snp.makeConstraints { $0.height.equalTo(1) }
        containerStack.addArrangedSubview(divider)
        
        addStatusButton(title: "예정으로 변경", status: .scheduled, isDestructive: false)
        
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
}
