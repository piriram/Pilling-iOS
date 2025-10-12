//
//  PillSettingViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - PillSettingViewController

final class PillSettingViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: PillSettingViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "PillSetting")
        return imageView
    }()
    
    private let mainTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "복용하고 계신 약을 알려주세요!"
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        label.textAlignment = .left
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "설정을 추후에 변경가능합니다."
        label.font = Typography.body2(.regular)
        label.textColor = .gray
        label.textAlignment = .left
        return label
    }()
    
    private let pillTypeButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: "약 종류", iconSystemName: "pills")
        return button
    }()
    
    private let currentDaysButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: "복용 시작 날짜", iconSystemName: "calendar")
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("다음으로", for: .normal)
        button.setTitleColor(AppColor.textBlack, for: .normal)
        button.titleLabel?.font = Typography.headline5(.bold)
        button.backgroundColor = AppColor.pillGreen600.withAlphaComponent(0.7)
        button.layer.cornerRadius = 16
        button.isEnabled = false
        button.alpha = 0.8
        return button
    }()
    
    // MARK: - Initialization
    
    init(viewModel: PillSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bind()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(iconImageView)
        view.addSubview(mainTitleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(pillTypeButton)
        view.addSubview(currentDaysButton)
        view.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(-20)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        mainTitleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(mainTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        pillTypeButton.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(60)
        }
        
        currentDaysButton.snp.makeConstraints {
            $0.top.equalTo(pillTypeButton.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(60)
        }
        
        nextButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(70)
        }
    }
    
    private func bind() {
        // Input
        pillTypeButton.rx.tap
            .bind(to: viewModel.input.pillTypeButtonTapped)
            .disposed(by: disposeBag)
        
        currentDaysButton.rx.tap
            .bind(to: viewModel.input.startDateButtonTapped)
            .disposed(by: disposeBag)
        
        nextButton.rx.tap
            .bind(to: viewModel.input.nextButtonTapped)
            .disposed(by: disposeBag)
        
        // Output
        viewModel.output.selectedPillTypeText
            .drive(onNext: { [weak self] text in
                self?.pillTypeButton.setValue(text)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.selectedStartDateText
            .drive(onNext: { [weak self] dateText in
                self?.currentDaysButton.setValue(dateText)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.isNextButtonEnabled
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.output.isNextButtonEnabled
            .drive(onNext: { [weak self] isEnabled in
                self?.nextButton.alpha = isEnabled ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)
        
        viewModel.output.isNextButtonEnabled
            .drive(onNext: { [weak self] isEnabled in
                let enabledColor = AppColor.pillGreen600
                let disabledColor = AppColor.pillGreen600.withAlphaComponent(0.5)
                self?.nextButton.backgroundColor = isEnabled ? enabledColor : disabledColor
            })
            .disposed(by: disposeBag)
        
        viewModel.output.presentDatePicker
            .emit(onNext: { [weak self] in
                self?.presentDatePickerBottomSheet()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.presentPillTypePicker
            .emit(onNext: { [weak self] in
                self?.presentPillTypeBottomSheet()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.proceed
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                let vm = DIContainer.shared.makeTimeSettingViewModel()
                let nextVC = TimeSettingViewController(viewModel: vm)
                if let nav = self.navigationController {
                    nav.pushViewController(nextVC, animated: true)
                } else {
                    self.present(nextVC, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private func presentDatePickerBottomSheet() {
        let datePickerVC = DatePickerBottomSheetViewController()
        
        datePickerVC.selectedDate
            .bind(to: viewModel.input.dateSelected)
            .disposed(by: disposeBag)
        
        present(datePickerVC, animated: false)
    }
    
    private func presentPillTypeBottomSheet() {
        let pillTypeVC = PillTypeBottomSheetViewController()
        
        pillTypeVC.pillInfoSelected
            .bind(to: viewModel.input.pillInfoSelected)
            .disposed(by: disposeBag)
        
        present(pillTypeVC, animated: false)
    }
}

// MARK: - SettingItemButton

final class SettingItemButton: UIButton {
    
    private let leadingIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppColor.cheveronGray
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()
    
    private let itemTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body2(.medium)
        label.textColor = AppColor.textGray
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body2(.regular)
        label.textColor = AppColor.textGray
        label.textAlignment = .right
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = AppColor.cheveronGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = AppColor.grayBackground
        layer.cornerRadius = 12
        
        addSubview(leadingIconImageView)
        addSubview(itemTitleLabel)
        addSubview(valueLabel)
        addSubview(arrowImageView)
    }
    
    private func setupConstraints() {
        leadingIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        itemTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(leadingIconImageView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        valueLabel.snp.makeConstraints {
            $0.trailing.equalTo(arrowImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(itemTitleLabel.snp.trailing).offset(16)
        }
    }
    
    func configure(title: String, iconSystemName: String? = nil) {
        itemTitleLabel.text = title
        if let name = iconSystemName {
            leadingIconImageView.image = UIImage(systemName: name)
            leadingIconImageView.isHidden = false
        } else {
            leadingIconImageView.image = nil
            leadingIconImageView.isHidden = true
        }
    }
    
    func setValue(_ value: String?) {
        valueLabel.text = value
    }
}

// MARK: - PillSettingViewModel

final class PillSettingViewModel {
    
    struct Input {
        let pillTypeButtonTapped: AnyObserver<Void>
        let startDateButtonTapped: AnyObserver<Void>
        let dateSelected: AnyObserver<Date>
        let pillInfoSelected: AnyObserver<PillInfo>
        let nextButtonTapped: AnyObserver<Void>
    }
    
    struct Output {
        let selectedPillTypeText: Driver<String?>
        let selectedStartDateText: Driver<String?>
        let isNextButtonEnabled: Driver<Bool>
        let presentDatePicker: Signal<Void>
        let presentPillTypePicker: Signal<Void>
        let proceed: Signal<Void>
    }
    
    // MARK: - Properties
    
    let input: Input
    let output: Output
    
    private let pillTypeButtonTappedSubject = PublishSubject<Void>()
    private let startDateButtonTappedSubject = PublishSubject<Void>()
    private let dateSelectedSubject = PublishSubject<Date>()
    private let pillInfoSelectedSubject = PublishSubject<PillInfo>()
    private let nextButtonTappedSubject = PublishSubject<Void>()
    
    private let selectedPillInfoRelay = BehaviorRelay<PillInfo?>(value: nil)
    private let selectedStartDateRelay = BehaviorRelay<Date?>(value: nil)
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM월 dd일"
        return formatter
    }()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init() {
        // Output에 필요한 Observable 먼저 생성
        let isNextButtonEnabled = Observable
            .combineLatest(
                selectedPillInfoRelay.asObservable(),
                selectedStartDateRelay.asObservable()
            )
            .map { pillInfo, startDate in
                pillInfo != nil && startDate != nil
            }
        
        let selectedPillTypeText = selectedPillInfoRelay
            .map { pillInfo -> String? in
                guard let info = pillInfo else { return nil }
                return "\(info.name) (복용 \(info.takingDays)일 / 휴약 \(info.breakDays)일)"
            }
        
        let selectedStartDateText = selectedStartDateRelay
            .map { date -> String? in
                guard let date = date else { return nil }
                let dateText = PillSettingViewModel.dateFormatter.string(from: date)
                let days = PillSettingViewModel.calculateDaysSinceStart(from: date)
                return "\(dateText) (\(days)일째)"
            }
        
        let proceed = nextButtonTappedSubject
            .withLatestFrom(isNextButtonEnabled)
            .filter { $0 }
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
        
        // Input 초기화
        self.input = Input(
            pillTypeButtonTapped: pillTypeButtonTappedSubject.asObserver(),
            startDateButtonTapped: startDateButtonTappedSubject.asObserver(),
            dateSelected: dateSelectedSubject.asObserver(),
            pillInfoSelected: pillInfoSelectedSubject.asObserver(),
            nextButtonTapped: nextButtonTappedSubject.asObserver()
        )
        
        // Output 초기화
        self.output = Output(
            selectedPillTypeText: selectedPillTypeText.asDriver(onErrorJustReturn: nil),
            selectedStartDateText: selectedStartDateText.asDriver(onErrorJustReturn: nil),
            isNextButtonEnabled: isNextButtonEnabled.asDriver(onErrorJustReturn: false),
            presentDatePicker: startDateButtonTappedSubject.asSignal(onErrorSignalWith: .empty()),
            presentPillTypePicker: pillTypeButtonTappedSubject.asSignal(onErrorSignalWith: .empty()),
            proceed: proceed
        )
        
        // 바인딩
        bindActions()
    }
    
    // MARK: - Bind
    
    private func bindActions() {
        pillInfoSelectedSubject
            .subscribe(onNext: { [weak self] pillInfo in
                self?.selectedPillInfoRelay.accept(pillInfo)
            })
            .disposed(by: disposeBag)
        
        dateSelectedSubject
            .subscribe(onNext: { [weak self] date in
                self?.selectedStartDateRelay.accept(date)
            })
            .disposed(by: disposeBag)
        
        // Removed nextButtonTappedSubject subscription with TODO comment
    }
    
    // MARK: - Private Methods
    
    private static func calculateDaysSinceStart(from startDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: Date())
        return (components.day ?? 0) + 1 // 1일차부터 시작
    }
}

