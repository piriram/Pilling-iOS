//
//  DashboardBottomView.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/28/25.
//

import UIKit
import SnapKit

final class DashboardBottomView: UIView {
    
    // MARK: - UI Components
    
    let pageControl = UIPageControl()
    let takePillButton = UIButton(type: .system)
    
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
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = AppColor.pillGreen800
        pageControl.pageIndicatorTintColor = AppColor.notYetGray
        pageControl.isUserInteractionEnabled = false
        pageControl.hidesForSinglePage = true
        
        takePillButton.setTitle("잔디 심기", for: .normal)
        takePillButton.setTitleColor(.label, for: .normal)
        takePillButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        takePillButton.backgroundColor = AppColor.pillGreen200
        takePillButton.layer.cornerRadius = 12
        
        addSubview(pageControl)
        addSubview(takePillButton)
    }
    
    private func setupConstraints() {
        pageControl.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(12)
        }
        
        takePillButton.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(70)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    func updatePageControl(for itemCount: Int) {
        let columns = 7
        let rows = Int(ceil(Double(itemCount) / Double(columns)))
        let rowsPerPage = 4
        let numberOfPages = Int(ceil(Double(rows) / Double(rowsPerPage)))
        
        pageControl.numberOfPages = max(1, numberOfPages)
        pageControl.currentPage = 0
    }
    
    func updateButton(canTake: Bool, cycle: PillCycle?) {
        guard let cycle = cycle else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let todayRecord = cycle.records.first(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            return
        }
        
        if case .rest = todayRecord.status {
            takePillButton.setTitle("휴약 기간", for: .normal)
            takePillButton.backgroundColor = AppColor.pillWhite
            takePillButton.isEnabled = false
        } else if todayRecord.status.isTaken {
            takePillButton.setTitle("심기 완료!", for: .normal)
            takePillButton.backgroundColor = AppColor.notYetGray
            takePillButton.isEnabled = false
        } else if canTake {
            takePillButton.setTitle("잔디 심기", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen200
            takePillButton.isEnabled = true
        } else {
            takePillButton.setTitle("잔디 심기", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen200
            takePillButton.isEnabled = true
        }
    }
}
