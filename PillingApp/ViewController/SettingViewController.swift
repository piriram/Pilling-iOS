//
//  SettingViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class SettingViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: SettingViewModel
    private let disposeBag = DisposeBag()
    private let contentInset: CGFloat = 16
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let alarmSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "알림 설정"
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
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
        
        let timeLabel = UILabel()
        timeLabel.tag = 100
        timeLabel.text = "오전 9:00"
        timeLabel.font = Typography.body2(.regular)
        timeLabel.textColor = AppColor.textBlack
        
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.contentMode = .scaleAspectFit
        
        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        button.addSubview(timeLabel)
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
        
        timeLabel.snp.makeConstraints {
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
        
        return button
    }()
    
    private let messageSettingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left
        
        let iconImageView = UIImageView(image: UIImage(systemName: "text.bubble.fill"))
        iconImageView.tintColor = AppColor.textGray
        iconImageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "알림 메시지"
        titleLabel.font = Typography.body2(.medium)
        titleLabel.textColor = AppColor.textGray
        
        let messageLabel = UILabel()
        messageLabel.tag = 101
        messageLabel.text = "건강한 하루를 위해..."
        messageLabel.font = Typography.body2(.regular)
        messageLabel.textColor = AppColor.textBlack
        messageLabel.textAlignment = .right
        messageLabel.lineBreakMode = .byTruncatingTail
        
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.contentMode = .scaleAspectFit
        
        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        button.addSubview(messageLabel)
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
        
        messageLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(8)
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
        
        return button
    }()
    
    private let alarmToggleContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let alarmTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "소리 알람 여부"
        label.font = Typography.body2(.medium)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private let alarmToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColor.pillGreen200
        return toggle
    }()
    
    private let otherSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "기타 설정"
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private let healthToggleContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let healthTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Apple Health 연동"
        label.font = Typography.body2(.medium)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private let healthToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColor.pillGreen200
        return toggle
    }()
    
    private let healthDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "복용 기록을 Apple Health에 동기화합니다"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Initialization
    
    init(viewModel: SettingViewModel) {
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
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "설정"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [alarmSectionLabel, timeSettingButton, messageSettingButton, alarmToggleContainer,
         otherSectionLabel, healthToggleContainer, healthDescriptionLabel].forEach {
            contentView.addSubview($0)
        }
        
        [alarmTitleLabel, alarmToggle].forEach {
            alarmToggleContainer.addSubview($0)
        }
        
        [healthTitleLabel, healthToggle].forEach {
            healthToggleContainer.addSubview($0)
        }
        
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        alarmSectionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        timeSettingButton.snp.makeConstraints {
            $0.top.equalTo(alarmSectionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(60)
        }
        
        messageSettingButton.snp.makeConstraints {
            $0.top.equalTo(timeSettingButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(60)
        }
        
        alarmToggleContainer.snp.makeConstraints {
            $0.top.equalTo(messageSettingButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(60)
        }
        
        alarmTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        
        alarmToggle.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
        
        otherSectionLabel.snp.makeConstraints {
            $0.top.equalTo(alarmToggleContainer.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        healthToggleContainer.snp.makeConstraints {
            $0.top.equalTo(otherSectionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(60)
        }
        
        healthTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        
        healthToggle.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
        
        healthDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(healthToggleContainer.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(contentInset + 4)
            $0.bottom.equalToSuperview().offset(-40)
        }
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        let viewWillAppear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .map { _ in }
            .asObservable()
        
        let input = SettingViewModel.Input(
            viewWillAppear: viewWillAppear,
            timeSettingTapped: timeSettingButton.rx.tap.asObservable(),
            messageSettingTapped: messageSettingButton.rx.tap.asObservable(),
            alarmToggleChanged: alarmToggle.rx.isOn.changed.asObservable(),
            healthToggleChanged: healthToggle.rx.isOn.changed.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        // 현재 설정 반영
        output.currentSettings
            .drive(onNext: { [weak self] settings in
                self?.updateUI(with: settings)
            })
            .disposed(by: disposeBag)
        
        // 시간 설정 바텀시트 표시
        output.showTimePicker
            .drive(onNext: { [weak self] in
                self?.showTimePicker()
            })
            .disposed(by: disposeBag)
        
        // 메시지 설정 Alert 표시
        output.showMessageEditor
            .drive(onNext: { [weak self] currentMessage in
                self?.showMessageEditor(currentMessage: currentMessage)
            })
            .disposed(by: disposeBag)
        
        // 에러 표시
        output.showError
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: "오류", message: message, isError: true)
            })
            .disposed(by: disposeBag)
        
        // 성공 메시지 표시
        output.showSuccess
            .filter { !$0.isEmpty }
            .drive(onNext: { [weak self] message in
                self?.showToast(message: message)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private func updateUI(with settings: UserSettings) {
        // 시간 표시 업데이트
        let timeLabel = timeSettingButton.viewWithTag(100) as? UILabel
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        timeLabel?.text = formatter.string(from: settings.scheduledTime)
        
        // 메시지 표시 업데이트
        let messageLabel = messageSettingButton.viewWithTag(101) as? UILabel
        messageLabel?.text = settings.notificationMessage
        
        // 토글 상태 업데이트
        alarmToggle.isOn = settings.notificationEnabled
        healthToggle.isOn = false
    }
    
    private func showTimePicker() {
        let bottomSheet = TimePickerBottomSheet()
        
        bottomSheet.selectedTime
            .take(1)
            .flatMap { [weak self] date -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.viewModel.updateTime(date)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.showToast(message: "복용 시간이 변경되었습니다")
                },
                onError: { [weak self] error in
                    self?.showAlert(title: "오류", message: "시간 변경에 실패했습니다", isError: true)
                }
            )
            .disposed(by: disposeBag)
        
        present(bottomSheet, animated: true)
    }
    
    private func showMessageEditor(currentMessage: String) {
        let alert = UIAlertController(
            title: "알림 메시지 수정",
            message: "받고 싶은 알림 메시지를 입력해주세요",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = currentMessage
            textField.placeholder = "알림 메시지 입력"
            textField.clearButtonMode = .whileEditing
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let textField = alert?.textFields?.first,
                  let newMessage = textField.text,
                  !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            
            self.viewModel.updateMessage(newMessage)
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] in
                        self?.showToast(message: "알림 메시지가 변경되었습니다")
                    },
                    onError: { [weak self] error in
                        self?.showAlert(title: "오류", message: "메시지 변경에 실패했습니다", isError: true)
                    }
                )
                .disposed(by: self.disposeBag)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String, isError: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if isError && message.contains("권한") {
            let settingsAction = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            alert.addAction(settingsAction)
        }
        
        let confirmAction = UIAlertAction(title: "확인", style: .default)
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.font = Typography.body2(.medium)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        view.addSubview(toastLabel)
        
        toastLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.height.equalTo(44)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
