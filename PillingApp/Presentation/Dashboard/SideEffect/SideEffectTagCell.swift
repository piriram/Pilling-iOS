import UIKit
import SnapKit

/// 오늘의 컨디션 태그(칩) 셀
/// - DashboardSheetViewController 내 컬렉션에 사용
final class SideEffectTagCell: UICollectionViewCell {

    // MARK: - Reuse Identifier
    static let identifier = "SideEffectTagCell"

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.caption(.semibold) // 프로젝트 폰트 사용
        label.textColor = AppColor.textGray
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let padding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = AppColor.grayBackground
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = AppColor.borderGray.cgColor

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(padding)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        isSelected = false
        applyStyle(isSelected: false)
    }

    // MARK: - Configure

    /// 태그 텍스트 및 선택 상태를 적용
    func configure(with text: String, isSelected: Bool) {
        titleLabel.text = text
        applyStyle(isSelected: isSelected)
    }

    // MARK: - Style

    private func applyStyle(isSelected: Bool) {
        if isSelected {
            contentView.backgroundColor = AppColor.pillGreen800
            titleLabel.textColor = .white
            contentView.layer.borderColor = AppColor.pillGreen800.cgColor
        } else {
            contentView.backgroundColor = AppColor.grayBackground
            titleLabel.textColor = AppColor.textGray
            contentView.layer.borderColor = AppColor.borderGray.cgColor
        }
    }

    // 선택 변경 시 즉시 반영(선택 토글 UX용)
    override var isSelected: Bool {
        didSet { applyStyle(isSelected: isSelected) }
    }

    // 셀 자체가 오토사이징되도록 함(CompositionalLayout에서 estimated 폭 사용)
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let newAttributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        newAttributes.size = CGSize(width: ceil(size.width), height: ceil(size.height))
        return newAttributes
    }
}
