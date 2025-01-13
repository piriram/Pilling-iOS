import UIKit

final class PrimaryActionButton: UIButton {
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    convenience init() {
        self.init(frame: .zero)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    // MARK: - Overrides
    
    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    // MARK: - Private methods
    
    private func configure() {
        titleLabel?.font = Typography.headline5(.bold)
        setTitleColor(AppColor.textBlack, for: .normal)
        layer.cornerRadius = 16
        layer.masksToBounds = true
        updateAppearance()
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func updateAppearance() {
        backgroundColor = AppColor.pillGreen600
        alpha = isEnabled ? 1.0 : 0.5
        isUserInteractionEnabled = isEnabled
    }
}
