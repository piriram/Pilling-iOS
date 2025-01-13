import UIKit
import SnapKit

final class DayRecordCell: UITableViewCell {
    static let reuseID = "DayRecordCell"
    
    private let titleLabel = UILabel()
    private let stack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }
    
    private func setupUI() {
        selectionStyle = .none
        titleLabel.font = Typography.headline5(.bold)
        titleLabel.textColor = AppColor.textBlack
        
        stack.axis = .vertical
        stack.spacing = 6
        
        let v = UIStackView(arrangedSubviews: [titleLabel, stack])
        v.axis = .vertical
        v.spacing = 8
        contentView.addSubview(v)
        v.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }
    
    func configure(with record: DayRecord) {
        titleLabel.text = "Record Day \(record.cycleDay) · \(record.status)"
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let scheduled = record.scheduledDateTime.formatted(style: .dateTimeShort)
        let taken = record.takenAt?.formatted(style: .dateTimeShort) ?? "-"
        let created = record.createdAt.formatted(style: .dateTimeShort)
        let updated = record.updatedAt.formatted(style: .dateTimeShort)
        
        let rows: [(String, String)] = [
            ("id", record.id.uuidString),
            ("cycleDay", "\(record.cycleDay)"),
            ("status", "\(record.status.rawValue) (\(record.status))"),
            ("scheduledDateTime", scheduled),
            ("takenAt", taken),
            ("memo", record.memo.isEmpty ? "-" : record.memo),
            ("createdAt", created),
            ("updatedAt", updated)
        ]
        rows.forEach { stack.addArrangedSubview(KeyValueRowView(key: $0.0, value: $0.1)) }
    }
}
