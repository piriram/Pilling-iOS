//
//  PillCycleHistoryCell.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/16/25.
//

import UIKit
import SnapKit

// MARK: - Custom Cell
final class PillCycleHistoryCell: UITableViewCell {
    static let reuseID = "PillCycleHistoryCell"
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let adherenceLabel = UILabel()
    private let hStack = UIStackView()
    private let vStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    
    private func setup() {
        selectionStyle = .none
        
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = AppColor.pillGreen800
        iconView.image = UIImage(systemName: "pills")
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(28)
        }
        
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = AppColor.textBlack
        
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = AppColor.weekdayText
        subtitleLabel.numberOfLines = 1
        
        adherenceLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        adherenceLabel.textColor = AppColor.pillGreen800
        adherenceLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.alignment = .fill
        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(subtitleLabel)
        
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.addArrangedSubview(iconView)
        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(adherenceLabel)
        
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    func configure(with cycle: PillCycle) {
        
        let start = cycle.startDate.formatted(style: .yearMonthDayPoint)
        let totalDays = (Mirror(reflecting: cycle).children.first { $0.label == "totalDays" }?.value as? Int) ?? (cycle.activeDays + cycle.breakDays)
        let endDate = Calendar.current.date(byAdding: .day, value: max(totalDays - 1, 0), to: cycle.startDate) ?? cycle.startDate
        let end = endDate.formatted(style: .yearMonthDayPoint)
        
        titleLabel.text = "Cycle \(cycle.cycleNumber)"
        subtitleLabel.text = "\(start) ~ \(end) (총 \(totalDays)일)"
        
        // Compute adherence from records
        let takenCount = cycle.records.filter { $0.status.isTaken }.count
        let schedulableCount = cycle.records.filter { $0.status != .rest }.count
        let adherence: Int = schedulableCount > 0 ? Int(round(Double(takenCount) / Double(schedulableCount) * 100.0)) : 0
        adherenceLabel.text = "\(adherence)%"
        
        // Icon based on adherence
        if adherence >= 90 {
            iconView.image = UIImage(systemName: "leaf.fill")
            iconView.tintColor = AppColor.pillGreen800
        } else if adherence >= 70 {
            iconView.image = UIImage(systemName: "leaf")
            iconView.tintColor = AppColor.pillGreen800
        } else {
            iconView.image = UIImage(systemName: "exclamationmark.triangle")
            iconView.tintColor = .systemOrange
        }
    }
}
