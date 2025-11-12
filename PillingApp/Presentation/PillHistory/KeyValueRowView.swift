import UIKit
import SnapKit

final class KeyValueRowView: UIView {
    private let keyLabel = UILabel()
    private let valueLabel = UILabel()
    
    init(key: String, value: String) {
        super.init(frame: .zero)
        setupUI()
        keyLabel.text = key
        valueLabel.text = value
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }
    
    private func setupUI() {
        keyLabel.font = Typography.body2(.medium)
        keyLabel.textColor = AppColor.weekdayText
        
        valueLabel.font = Typography.body2(.regular)
        valueLabel.textColor = AppColor.textBlack
        valueLabel.numberOfLines = 0
        
        let h = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        h.axis = .horizontal
        h.alignment = .firstBaseline
        h.spacing = 8
        addSubview(h)
        h.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        keyLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
}
