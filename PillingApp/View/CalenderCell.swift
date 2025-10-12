//
//  CalenderCell.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit
import SnapKit
// MARK: - Presentation/Dashboard/Views/CalendarCell.swift

final class CalendarCell: UICollectionViewCell {
    static let identifier = "CalendarCell"
    
    private let backgroundShapeView = UIView()
    private let capsuleContainer = UIView()
    private let capsule1 = UIView()
    private let capsule2 = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius = min(bounds.width, bounds.height) * 0.25
        backgroundShapeView.layer.cornerRadius = cornerRadius
    }
    
    private func setupViews() {
        contentView.addSubview(backgroundShapeView)
        backgroundShapeView.addSubview(capsuleContainer)
        capsuleContainer.addSubview(capsule1)
        capsuleContainer.addSubview(capsule2)
        
        backgroundShapeView.layer.masksToBounds = true
        backgroundShapeView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        capsuleContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        capsule1.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(capsule1.snp.height).multipliedBy(0.4)
        }
        
        capsule2.snp.makeConstraints { make in
            make.leading.equalTo(capsule1.snp.trailing).offset(2)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(capsule1)
        }
        
        capsule1.layer.cornerRadius = 10
        capsule2.layer.cornerRadius = 10
        capsule1.backgroundColor = AppColor.pillGreen800
        capsule2.backgroundColor = AppColor.pillGreen800
        
        capsuleContainer.isHidden = true
        contentView.backgroundColor = .clear
    }
    
    func configure(with item: DayItem) {
        backgroundShapeView.layer.borderWidth = 0
        backgroundShapeView.layer.borderColor = UIColor.clear.cgColor
        capsuleContainer.isHidden = true
        
        backgroundShapeView.backgroundColor = item.status.backgroundColor
        
        if item.status.isToday {
            backgroundShapeView.layer.borderWidth = 2
            backgroundShapeView.layer.borderColor = AppColor.pillBorder.cgColor
        }
        
        if case .rest = item.status {
            backgroundShapeView.layer.borderWidth = 1
            backgroundShapeView.layer.borderColor = AppColor.notYetGray.cgColor
        }
        
        if case .takenDouble = item.status {
            capsuleContainer.isHidden = false
        }
    }
}
