//
//  DashboardInfoView.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/28/25.
//

import UIKit
import SnapKit

final class DashboardInfoView: UIView {
    
    // MARK: - UI Components
    
    let historyButton = UIButton(type: .system)
    let infoButton = UIButton(type: .system)
    let gearButton = UIButton(type: .system)
    let characterImageView = UIImageView()
    
    private let progressLabel = UILabel()
    private let totalLabel = UILabel()
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let dateIconImageView = UIImageView(image: DashboardUI.Icon.date)
    private let timeIconImageView = UIImageView(image: DashboardUI.Icon.time)
    
    private let messageCardView = UIView()
    private let messageIconImageView = UIImageView(image: UIImage(systemName: "leaf.fill"))
    private let messageLabel = UILabel()
    
    private let dateInfoStackView = UIStackView()
    private let progressRowStackView = UIStackView()
    private let headerInfoStackView = UIStackView()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        setupButtons()
        setupLabels()
        setupMessageCard()
        setupStackViews()
        
        addSubview(historyButton)
        addSubview(infoButton)
        addSubview(gearButton)
        addSubview(characterImageView)
        addSubview(headerInfoStackView)
        addSubview(messageCardView)
        
        messageCardView.addSubview(messageIconImageView)
        messageCardView.addSubview(messageLabel)
    }
    
    private func setupButtons() {
        infoButton.setImage(DashboardUI.Icon.info, for: .normal)
        infoButton.tintColor = AppColor.secondary
        
        if #available(iOS 13.0, *) {
            historyButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        } else {
            historyButton.setTitle("H", for: .normal)
        }
        historyButton.tintColor = AppColor.secondary
        
        gearButton.setImage(DashboardUI.Icon.gear, for: .normal)
        gearButton.tintColor = AppColor.secondary
        
        characterImageView.contentMode = .scaleAspectFill
    }
    
    private func setupLabels() {
        progressLabel.font = Typography.headline1()
        progressLabel.textColor = .black
        totalLabel.font = Typography.headline5()
        totalLabel.textColor = AppColor.secondary
        
        dateLabel.font = Typography.body1(.medium)
        dateLabel.textColor = AppColor.secondary
        timeLabel.font = Typography.body1(.medium)
        timeLabel.textColor = AppColor.secondary
        dateIconImageView.tintColor = AppColor.secondary
        timeIconImageView.tintColor = AppColor.secondary
    }
    
    private func setupMessageCard() {
        messageCardView.backgroundColor = AppColor.bg
        messageCardView.layer.cornerRadius = 20
        messageCardView.layer.borderWidth = 1
        messageCardView.layer.borderColor = AppColor.borderGray.cgColor
        
        messageIconImageView.tintColor = AppColor.pillGreen800
        messageIconImageView.contentMode = .scaleAspectFit
        
        messageLabel.font = Typography.body2(.medium)
        messageLabel.textColor = AppColor.textBlack
        messageLabel.numberOfLines = 1
    }
    
    private func setupStackViews() {
        dateInfoStackView.axis = .vertical
        dateInfoStackView.alignment = .leading
        dateInfoStackView.spacing = 6
        
        let dateLine = UIStackView(arrangedSubviews: [dateIconImageView, dateLabel])
        dateLine.axis = .horizontal
        dateLine.spacing = 8
        dateLine.alignment = .center
        
        let timeLine = UIStackView(arrangedSubviews: [timeIconImageView, timeLabel])
        timeLine.axis = .horizontal
        timeLine.spacing = 8
        timeLine.alignment = .center
        
        dateIconImageView.snp.makeConstraints { $0.width.height.equalTo(20) }
        timeIconImageView.snp.makeConstraints { $0.width.height.equalTo(20) }
        
        dateInfoStackView.addArrangedSubview(dateLine)
        dateInfoStackView.addArrangedSubview(timeLine)
        
        progressRowStackView.axis = .horizontal
        progressRowStackView.alignment = .firstBaseline
        progressRowStackView.spacing = 2
        progressRowStackView.addArrangedSubview(progressLabel)
        progressRowStackView.addArrangedSubview(totalLabel)
        
        headerInfoStackView.axis = .vertical
        headerInfoStackView.alignment = .leading
        headerInfoStackView.spacing = 6
        headerInfoStackView.addArrangedSubview(progressRowStackView)
        headerInfoStackView.addArrangedSubview(dateInfoStackView)
    }
    
    private func setupConstraints() {
        let contentInset: CGFloat = 16
        
        infoButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalTo(gearButton.snp.leading).offset(-8)
            make.width.height.lessThanOrEqualTo(30)
        }
        
        historyButton.snp.makeConstraints { make in
            make.centerY.equalTo(infoButton)
            make.trailing.equalTo(infoButton.snp.leading).offset(-8)
            make.width.height.lessThanOrEqualTo(30)
        }
        
        gearButton.snp.makeConstraints { make in
            make.centerY.equalTo(infoButton)
            make.trailing.equalToSuperview().inset(contentInset)
            make.width.height.lessThanOrEqualTo(30)
        }
        
        characterImageView.snp.makeConstraints { make in
            make.top.equalTo(infoButton.snp.bottom)
            make.leading.equalToSuperview().inset(contentInset)
            make.width.equalTo((UIScreen.main.bounds.width - contentInset) / 2)
            make.height.equalTo(150)
        }
        
        headerInfoStackView.snp.makeConstraints { make in
            make.centerY.equalTo(characterImageView.snp.centerY)
            make.leading.equalTo(characterImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
        }
        
        messageCardView.snp.makeConstraints { make in
            make.top.equalTo(characterImageView.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(contentInset)
            make.height.equalTo(52)
            make.bottom.equalToSuperview()
        }
        
        messageIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(messageIconImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    func configure(with cycle: PillCycle) {
        let calendar = Calendar.current
        let now = Date()
        
        let daysSinceStart = calendar.dateComponents([.day], from: cycle.startDate, to: now).day ?? 0
        let currentDay = daysSinceStart + 1
        
        progressLabel.text = "\(currentDay)일차"
        progressLabel.textColor = AppColor.textBlack
        totalLabel.text = "/\(cycle.totalDays)"
        timeLabel.text = cycle.scheduledTime
    }
    
    func configure(with pillInfo: PillInfo) {
        dateLabel.text = "\(pillInfo.takingDays)/\(pillInfo.breakDays)"
    }
    
    func configure(with message: DashboardMessage) {
        messageLabel.text = message.text
        
        if let image = UIImage(named: message.imageName.rawValue) {
            characterImageView.image = image
        } else {
            characterImageView.image = UIImage(systemName: "face.smiling")
        }
        
        if let iconImage = UIImage(named: message.icon.rawValue) {
            messageIconImageView.image = iconImage
        }
    }
}
