import UIKit
import SnapKit

/// 섹션 푸터에 "추가" 버튼을 배치해 드롭 타깃과 충돌하지 않게 합니다.
final class FooterAddView: UICollectionReusableView {

    private let button: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "추가"
        config.image = UIImage(systemName: "plus")
        config.imagePadding = 6
        config.cornerStyle = .large
        let btn = UIButton(configuration: config)
        btn.tintColor = AppColor.green800
        return btn
    }()

    private var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
        }
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, onTap: @escaping () -> Void) {
        var config = button.configuration
        config?.title = title
        button.configuration = config
        self.onTap = onTap
    }

    @objc private func didTap() {
        onTap?()
    }
}
