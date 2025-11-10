//
//  SideEffectTagCell.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/10/25.
//

import UIKit
import SnapKit

final class SideEffectTagCell: UICollectionViewCell {
    
    static let identifier = "SideEffectTagCell"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.pillGreen200.withAlphaComponent(0.15)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.pillGreen600.cgColor
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body2(.medium)
        label.textColor = AppColor.pillGreen800
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.top.bottom.equalToSuperview().inset(8)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with title: String, isSelected: Bool = false) {
        titleLabel.text = title
        
        if isSelected {
            containerView.backgroundColor = AppColor.pillGreen800
            titleLabel.textColor = .white
        } else {
            containerView.backgroundColor = AppColor.pillGreen200.withAlphaComponent(0.15)
            titleLabel.textColor = AppColor.pillGreen800
        }
    }
}

// MARK: - Add Button Cell

final class SideEffectAddButtonCell: UICollectionViewCell {
    
    static let identifier = "SideEffectAddButtonCell"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.grayBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColor.borderGray.cgColor
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "plus")
        imageView.tintColor = AppColor.gray400
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "관리"
        label.font = Typography.body2(.medium)
        label.textColor = AppColor.gray400
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-8)
            $0.width.height.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(2)
            $0.centerX.equalToSuperview()
        }
    }
}
