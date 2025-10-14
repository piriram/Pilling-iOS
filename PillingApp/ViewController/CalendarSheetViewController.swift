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
    
    var subtitleText: String?
    
    private let memoTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "메모를 입력하세요"
        tf.borderStyle = .roundedRect
        tf.clearButtonMode = .whileEditing
        return tf
    }()
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    private let statusSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["미복용", "복용", "2알 복용"]) 
        control.selectedSegmentIndex = UISegmentedControl.noSegment
        return control
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
        bindSegmentedControl()
    }
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitleText ?? self.title
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        
        view.addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        containerStack.addArrangedSubview(subtitleLabel)
        
        containerStack.addArrangedSubview(statusSegmentedControl)
        statusSegmentedControl.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        
        containerStack.addArrangedSubview(memoTextField)
        memoTextField.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(12) }
        containerStack.addArrangedSubview(spacer)
    }
    
    private func bindSegmentedControl() {
        statusSegmentedControl.rx.selectedSegmentIndex
            .compactMap { [weak self] index -> PillStatus? in
                guard let self = self else { return nil }
                switch index {
                case 0:
                    // 미복용: 오늘이면 예정(.scheduled), 과거면 .missed, 미래면 .scheduled
                    let calendar = Calendar.current
                    let isToday = calendar.isDateInToday(self.selectedDate)
                    let isInPast = self.selectedDate < calendar.startOfDay(for: Date())
                    return isToday ? .scheduled : (isInPast ? .missed : .scheduled)
                case 1:
                    return .taken
                case 2:
                    return .takenDouble
                default:
                    return nil
                }
            }
            .bind { [weak self] status in
                guard let self = self else { return }
                self.dismiss(animated: true)
                self.onSelectStatus(status, self.memoTextField.text ?? "")
            }
            .disposed(by: disposeBag)
    }
    
    func setInitialSelection(for status: PillStatus) {
        switch status {
        // 미복용/예정/오늘 미복용/오늘 지연 등 미복용 계열은 0번
        case .missed, .scheduled, .todayNotTaken, .todayDelayed:
            statusSegmentedControl.selectedSegmentIndex = 0
        // 복용/지연 복용/오늘 복용/오늘 지연 복용 등은 1번
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed:
            statusSegmentedControl.selectedSegmentIndex = 1
        // 2알 복용은 2번
        case .takenDouble:
            statusSegmentedControl.selectedSegmentIndex = 2
        // 휴약은 선택 없음 유지
        case .rest:
            statusSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }
}
