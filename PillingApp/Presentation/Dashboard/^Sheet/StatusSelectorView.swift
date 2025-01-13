import UIKit
import SnapKit
import RxSwift
import RxCocoa

/// 세 가지 상태(미복용/복용/이중복용) 선택용 컴포넌트
/// - 버튼 생성/스타일/선택 애니메이션을 캡슐화
/// - VC에서는 tap 스트림만 받아서 ViewModel로 전달하고,
///   ViewModel의 selectedIndex를 Binder로 넘겨서 하이라이트만 동기화하면 됨.
final class StatusSelectorView: UIView {

    // MARK: Public API

    /// 미복용 버튼 탭 스트림
    var tapNotTaken: ControlEvent<Void> { notTakenButton.rx.tap }
    /// 복용 버튼 탭 스트림
    var tapTaken: ControlEvent<Void> { takenButton.rx.tap }
    /// 이중복용 버튼 탭 스트림
    var tapTakenDouble: ControlEvent<Void> { takenDoubleButton.rx.tap }

    /// ViewModel의 `selectedIndex (Driver<Int?>)`를 바인딩할 때 사용하는 Binder
    /// -1 또는 nil → 전부 해제, 0/1/2 → 해당 버튼 선택 애니메이션
    var selectedIndexBinder: Binder<Int?> {
        Binder(self) { view, index in
            view.applySelection(index: index)
        }
    }

    /// 외부에서 즉시 선택 상태를 세팅하고 싶을 때 사용
    func setSelected(index: Int?) {
        applySelection(index: index)
    }

    /// 높이 상수(오토레이아웃에서 활용)
    static let recommendedHeight: CGFloat = 48

    // MARK: UI

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColor.grayBackground
        v.layer.cornerRadius = 12
        return v
    }()

    private let hStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .fillEqually
        s.spacing = 0
        return s
    }()

    private let notTakenButton = StatusSelectorView.makeButton()
    private let takenButton = StatusSelectorView.makeButton()
    private let takenDoubleButton = StatusSelectorView.makeButton()

    private let disposeBag = DisposeBag()

    // MARK: Init

    /// - Parameters:
    ///   - titles: 버튼 타이틀(미복용/복용/이중복용 순)
    init(titles: (String, String, String)) {
        super.init(frame: .zero)
        setupUI()
        setTitles(titles)
    }

    override convenience init(frame: CGRect) {
        self.init(titles: ("", "", ""))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(hStack)

        [notTakenButton, takenButton, takenDoubleButton].forEach { hStack.addArrangedSubview($0) }

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(Self.recommendedHeight)
        }

        hStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }

    private func setTitles(_ titles: (String, String, String)) {
        notTakenButton.setTitle(titles.0, for: .normal)
        takenButton.setTitle(titles.1, for: .normal)
        takenDoubleButton.setTitle(titles.2, for: .normal)
    }

    // MARK: Selection Animation

    private func applySelection(index: Int?) {
        let buttons = [notTakenButton, takenButton, takenDoubleButton]
        for (i, btn) in buttons.enumerated() {
            let isSelected = (index == i)
            animate(button: btn, selected: isSelected)
        }
    }

    private func animate(button: UIButton, selected: Bool) {
        UIView.animate(
            withDuration: 0.30,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction]
        ) {
            button.isSelected = selected
            button.backgroundColor = selected ? AppColor.pillGreen800 : .clear
            button.titleLabel?.font = selected
            ? .systemFont(ofSize: 14, weight: .semibold)
            : .systemFont(ofSize: 14, weight: .medium)

            button.transform = selected ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            button.layer.shadowColor = AppColor.pillGreen800.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowOpacity = selected ? 0.3 : 0
            button.layer.shadowRadius = 4
        }
    }

    // MARK: Factory

    private static func makeButton() -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitleColor(AppColor.textGray, for: .normal)
        b.setTitleColor(.white, for: .selected)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        b.layer.cornerRadius = 10
        b.clipsToBounds = true
        return b
    }
}
