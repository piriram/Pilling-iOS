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
    private typealias str = AppStrings.Dashboard
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
        pageControl.hidesForSinglePage = false
        
        takePillButton.setTitle(str.takePillButton, for: .normal)
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
        print("🔍 [DashboardBottomView] updatePageControl 호출")
        print("   📊 itemCount: \(itemCount)")

        let columns = 7
        let rows = Int(ceil(Double(itemCount) / Double(columns)))
        let rowsPerPage = 4
        let numberOfPages = Int(ceil(Double(rows) / Double(rowsPerPage)))

        print("   📐 계산:")
        print("      - columns: \(columns) (한 줄에 7개)")
        print("      - rows: \(rows) (itemCount \(itemCount) ÷ \(columns) = \(Double(itemCount) / Double(columns)) → 올림)")
        print("      - rowsPerPage: \(rowsPerPage) (한 페이지에 4줄)")
        print("      - numberOfPages (계산): \(rows) ÷ \(rowsPerPage) = \(Double(rows) / Double(rowsPerPage)) → 올림 = \(numberOfPages)")
        print("      - numberOfPages (최종): max(1, \(numberOfPages)) = \(max(1, numberOfPages))")

        pageControl.numberOfPages = max(1, numberOfPages)
        pageControl.currentPage = 0

        print("   ✅ pageControl.numberOfPages 설정 완료: \(pageControl.numberOfPages)")
        print("   ✅ pageControl.currentPage 설정 완료: \(pageControl.currentPage)")
    }
    
    func updateButton(canTake: Bool, cycle: Cycle?, environment: DateEnvironment = .default) {
        guard let cycle = cycle else { return }
        
        let calendar = environment.calendar
        let now = environment.now
        
        //TODO: 에러처리
        guard let todayRecord = cycle.records.first(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            return
        }
        
        if case .rest = todayRecord.status {
            takePillButton.setTitle(str.restPeriod, for: .normal)
            takePillButton.backgroundColor = AppColor.pillWhite
            takePillButton.isEnabled = false
        } else if todayRecord.status.isTaken {
            takePillButton.setTitle(str.takePillCompleted, for: .normal)
            takePillButton.backgroundColor = AppColor.notYetGray
            takePillButton.isEnabled = false
        } else if canTake {
            takePillButton.setTitle(str.takePillButton, for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen200
            takePillButton.isEnabled = true
        } else {
            takePillButton.setTitle("???", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen200
            takePillButton.isEnabled = true
        }
    }
}

