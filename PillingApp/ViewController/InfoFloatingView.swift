import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class InfoFloatingView: UIView {
    // Public
    var onConfirm: (() -> Void)?

    // MARK: - UI
    private let dimmedBackgroundView = UIView()
    private let floatingCardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let guideStackView = UIStackView()
    private let confirmButton = UIButton(type: .system)

    // MARK: - Rx
    private let disposeBag = DisposeBag()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API
    func show(in container: UIView) {
        // occupy full screen of container
        container.addSubview(self)
        self.snp.makeConstraints { $0.edges.equalToSuperview() }
        layoutIfNeeded()

        // animate dim
        dimmedBackgroundView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.dimmedBackgroundView.alpha = 1
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimmedBackgroundView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear

        dimmedBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        floatingCardView.backgroundColor = .systemBackground
        floatingCardView.layer.cornerRadius = 30
        floatingCardView.layer.masksToBounds = true

        titleLabel.text = "필링 가이드"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppColor.text

        subtitleLabel.text = "피임약 복용 상태를 잔디로 알려드려요!"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = AppColor.subtext

        guideStackView.axis = .vertical
        guideStackView.spacing = 16
        guideStackView.alignment = .leading

        // Guide items
        let guideItem1 = makeGuideItemWithCalendarCell(status: .taken, text: "피임약 복용")
        let guideItem2 = makeGuideItemWithCalendarCell(status: .takenDouble, text: "피임약 2알 복용")
        let guideItem3 = makeGuideItemWithCalendarCell(status: .missed, text: "미복용")
        let guideItem4 = makeGuideItemWithCalendarCell(status: .rest, text: "휴약")

        [guideItem1, guideItem2, guideItem3, guideItem4].forEach { guideStackView.addArrangedSubview($0) }

        confirmButton.setTitle("확인", for: .normal)
        confirmButton.setTitleColor(.label, for: .normal)
        confirmButton.backgroundColor = AppColor.notYetGray
        confirmButton.layer.cornerRadius = 12
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)

        addSubview(dimmedBackgroundView)
        addSubview(floatingCardView)
        floatingCardView.addSubview(titleLabel)
        floatingCardView.addSubview(subtitleLabel)
        floatingCardView.addSubview(guideStackView)
        floatingCardView.addSubview(confirmButton)
    }

    private func setupConstraints() {
        dimmedBackgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }
        floatingCardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(316)
            make.height.equalTo(390)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.equalToSuperview().offset(32)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(32)
        }
        guideStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
            make.height.equalTo(52)
        }
    }

    private func setupActions() {
        // Confirm button
        confirmButton.rx.tap
            .bind { [weak self] in
                self?.onConfirm?()
            }
            .disposed(by: disposeBag)

        // Tap to dismiss on dimmed area
        let tapGesture = UITapGestureRecognizer()
        dimmedBackgroundView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .bind { [weak self] _ in
                self?.onConfirm?()
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers
    private func makeGuideItemWithCalendarCell(status: PillStatus, text: String) -> UIView {
        let containerView = UIView()

        let calendarCell = CalendarCell()

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 16, weight: .regular)
        textLabel.textColor = AppColor.text

        containerView.addSubview(calendarCell)
        containerView.addSubview(textLabel)

        calendarCell.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(calendarCell.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        containerView.layoutIfNeeded()

        let dummyItem = DayItem(cycleDay: 1, date: Date(), status: status)
        calendarCell.configure(with: dummyItem)

        return containerView
    }
}
