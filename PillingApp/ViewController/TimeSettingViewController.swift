//
//  TimeSettingViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class TimeSettingViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: TimeSettingViewModel
    private let disposeBag = DisposeBag()
    private let contentInset: CGFloat = 16
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let clockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "clock_image")
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "timeSetting")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "알람 받을 시간을 설정해주세요!"
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        label.textAlignment = .left
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "설정은 추후에 변경가능합니다."
        label.font = Typography.body2(.regular)
        label.textColor = .gray
        label.textAlignment = .left
        return label
    }()
    
    private let timeSettingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left
        
        let iconImageView = UIImageView(image: UIImage(systemName: "clock.fill"))
        iconImageView.tintColor = AppColor.textGray
        iconImageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "복용 시간"
        titleLabel.font = Typography.body2(.medium)
        titleLabel.textColor = AppColor.textGray
        
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.contentMode = .scaleAspectFit
        
        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        button.addSubview(chevronImageView)
        
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
        }
        
        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }
        
        return button
    }()
    
    private let alarmTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "소리 알람 여부"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let alarmToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColor.pillGreen200
        toggle.isOn = true
        return toggle
    }()
    
    private let healthTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Apple Health 연동"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let healthToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColor.pillGreen200
        toggle.isOn = true
        return toggle
    }()
    
    private let healthDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "설명텍스트입니다."
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        return label
    }()
    
    private let completeButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle("설정완료!", for: .normal)
        return button
    }()
    
    // MARK: - Initialization
    
    init(viewModel: TimeSettingViewModel) {
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
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .black
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "시간 설정"
        navigationItem.hidesBackButton = false
        navigationItem.backButtonDisplayMode = .default
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [clockImageView, titleLabel, subtitleLabel,
         timeSettingButton, alarmTitleLabel, alarmToggle,
         healthTitleLabel, healthToggle, healthDescriptionLabel,
         completeButton].forEach {
            contentView.addSubview($0)
        }
        
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        clockImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(contentInset)
            $0.height.equalTo(200)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(clockImageView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        timeSettingButton.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(60)
        }
        
        alarmTitleLabel.snp.makeConstraints {
            $0.top.equalTo(timeSettingButton.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(contentInset)
        }
        
        alarmToggle.snp.makeConstraints {
            $0.centerY.equalTo(alarmTitleLabel)
            $0.trailing.equalToSuperview().offset(-contentInset)
        }
        
        healthTitleLabel.snp.makeConstraints {
            $0.top.equalTo(alarmTitleLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(contentInset)
        }
        
        healthToggle.snp.makeConstraints {
            $0.centerY.equalTo(healthTitleLabel)
            $0.trailing.equalToSuperview().offset(-contentInset)
        }
        
        healthDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(healthTitleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(contentInset)
        }
        
        completeButton.snp.makeConstraints {
            $0.top.equalTo(healthDescriptionLabel.snp.bottom).offset(60)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(70)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        let input = TimeSettingViewModel.Input(
            backButtonTapped: Observable<Void>.empty(),
            timeSettingButtonTapped: timeSettingButton.rx.tap.asObservable(),
            alarmToggleChanged: alarmToggle.rx.isOn.changed.asObservable(),
            healthToggleChanged: healthToggle.rx.isOn.changed.asObservable(),
            completeButtonTapped: completeButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.showTimePicker
            .drive(onNext: { [weak self] in
                self?.showDatePicker()
            })
            .disposed(by: disposeBag)
        
        output.navigateToDashboard
            .drive(onNext: { [weak self] in
                self?.navigateToDashboard()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private func showDatePicker() {
        let alert = UIAlertController(title: "복용 시간 설정", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "ko_KR")
        
        alert.view.addSubview(datePicker)
        
        datePicker.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(50)
        }
        
        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.viewModel.updateTime(datePicker.date)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        if let pop = alert.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY - 10, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }
    
    private func navigateToDashboard() {
        let dashboardViewModel = DIContainer.shared.makeDashboardViewModel()
        let dashboardVC = DashboardViewController(viewModel: dashboardViewModel)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let navigationController = UINavigationController(rootViewController: dashboardVC)
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
    }
}

