//
//  DashboardViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
// MARK: - Presentation/Dashboard/Views/DashboardViewController.swift

final class DashboardViewController: UIViewController {
    
    private let viewModel: DashboardViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private let infoButton = UIButton(type: .system)
    private let gearButton = UIButton(type: .system)
    private let characterImageView = UIImageView()
    private let progressLabel = UILabel()
    private let totalLabel = UILabel()
    private let dateInfoStackView = UIStackView()
    private let dateIconImageView = UIImageView(image: DashboardUI.Icon.date)
    private let dateLabel = UILabel()
    private let timeIconImageView = UIImageView(image: DashboardUI.Icon.time)
    private let timeLabel = UILabel()
    
    private let messageCardView = UIView()
    private let messageIconImageView = UIImageView(image: DashboardUI.Icon.leaf)
    private let messageLabel = UILabel()
    
    private let weekdayStackView = UIStackView()
    
    private lazy var calendarCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeCompositionalLayout()
    )
    
    private let takePillButton = UIButton(type: .system)
    
    // MARK: - Initialization
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCalendarHeight(for: viewModel.items.value.count)
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = AppColor.bg
        
        setupHeaderViews()
        setupMessageCardView()
        setupWeekdayStackView()
        setupCalendarCollectionView()
        setupTakePillButton()
        
        addSubviews()
    }
    
    private func setupHeaderViews() {
        infoButton.setImage(DashboardUI.Icon.info, for: .normal)
        gearButton.setImage(DashboardUI.Icon.gear, for: .normal)
        
        characterImageView.contentMode = .scaleAspectFit
        
        progressLabel.font = .systemFont(ofSize: 28, weight: .bold)
        totalLabel.font = .systemFont(ofSize: 20, weight: .regular)
        totalLabel.textColor = AppColor.subtext
        
        dateLabel.textColor = AppColor.subtext
        timeLabel.textColor = AppColor.subtext
        dateIconImageView.tintColor = AppColor.subtext
        timeIconImageView.tintColor = AppColor.subtext
        
        dateInfoStackView.axis = .vertical
        dateInfoStackView.alignment = .leading
        dateInfoStackView.spacing = 4
        
        let dateLine = UIStackView(arrangedSubviews: [dateIconImageView, dateLabel])
        dateLine.axis = .horizontal
        dateLine.spacing = 6
        
        let timeLine = UIStackView(arrangedSubviews: [timeIconImageView, timeLabel])
        timeLine.axis = .horizontal
        timeLine.spacing = 6
        
        dateInfoStackView.addArrangedSubview(dateLine)
        dateInfoStackView.addArrangedSubview(timeLine)
    }
    
    private func setupMessageCardView() {
        messageCardView.backgroundColor = AppColor.card
        messageCardView.layer.cornerRadius = DashboardUI.Metric.cornerRadius
        messageIconImageView.tintColor = AppColor.pillGreen
        messageLabel.textColor = AppColor.subtext
    }
    
    private func setupWeekdayStackView() {
        weekdayStackView.axis = .horizontal
        weekdayStackView.alignment = .fill
        weekdayStackView.distribution = .fillEqually
        weekdayStackView.spacing = 0
        
        ["월", "화", "수", "목", "금", "토", "일"].forEach { weekdayText in
            let containerView = UIView()
            let label = UILabel()
            label.text = weekdayText
            label.textAlignment = .center
            label.textColor = AppColor.subtext
            label.font = .systemFont(ofSize: 13, weight: .medium)
            containerView.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.trailing.equalToSuperview()
            }
            weekdayStackView.addArrangedSubview(containerView)
        }
    }
    
    private func setupCalendarCollectionView() {
        calendarCollectionView.backgroundColor = .clear
        calendarCollectionView.contentInset = .zero
        calendarCollectionView.isScrollEnabled = false
        calendarCollectionView.register(
            CalendarCell.self,
            forCellWithReuseIdentifier: CalendarCell.identifier
        )
        calendarCollectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
    }
    
    private func setupTakePillButton() {
        takePillButton.setTitle("잔디 심기", for: .normal)
        takePillButton.setTitleColor(.label, for: .normal)
        takePillButton.backgroundColor = AppColor.pillGreen.withAlphaComponent(0.4)
        takePillButton.layer.cornerRadius = DashboardUI.Metric.cornerRadius
    }
    
    private func addSubviews() {
        view.addSubview(infoButton)
        view.addSubview(gearButton)
        view.addSubview(characterImageView)
        view.addSubview(progressLabel)
        view.addSubview(totalLabel)
        view.addSubview(dateInfoStackView)
        
        view.addSubview(messageCardView)
        messageCardView.addSubview(messageIconImageView)
        messageCardView.addSubview(messageLabel)
        
        view.addSubview(weekdayStackView)
        view.addSubview(calendarCollectionView)
        view.addSubview(takePillButton)
    }
    
    private func setupConstraints() {
        infoButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset + 44)
            make.width.height.equalTo(28)
        }
        
        gearButton.snp.makeConstraints { make in
            make.centerY.equalTo(infoButton)
            make.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.width.height.equalTo(28)
        }
        
        characterImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.width.height.equalTo(DashboardUI.Metric.headerImageSide)
        }
        
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(characterImageView.snp.top).offset(8)
            make.leading.equalTo(characterImageView.snp.trailing).offset(16)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.leading.equalTo(progressLabel.snp.trailing).offset(4)
            make.lastBaseline.equalTo(progressLabel)
        }
        
        dateInfoStackView.snp.makeConstraints { make in
            make.leading.equalTo(progressLabel)
            make.top.equalTo(progressLabel.snp.bottom).offset(8)
            make.trailing.lessThanOrEqualTo(gearButton.snp.leading).offset(-8)
        }
        
        messageCardView.snp.makeConstraints { make in
            make.top.equalTo(characterImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.height.equalTo(52)
        }
        
        messageIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(messageIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        
        weekdayStackView.snp.makeConstraints { make in
            make.top.equalTo(messageCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.height.equalTo(18)
        }
        
        calendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayStackView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.height.equalTo(200)
        }
        
        takePillButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(calendarCollectionView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(DashboardUI.Metric.contentInset)
            make.height.equalTo(DashboardUI.Metric.actionHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        viewModel.items
            .bind(to: calendarCollectionView.rx.items(
                cellIdentifier: CalendarCell.identifier,
                cellType: CalendarCell.self
            )) { _, element, cell in
                cell.configure(with: element)
            }
            .disposed(by: disposeBag)
        
        viewModel.items
            .asDriver()
            .drive(onNext: { [weak self] items in
                self?.updateCalendarHeight(for: items.count)
            })
            .disposed(by: disposeBag)
        
        viewModel.currentCycle
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: viewModel.currentCycle.value!)
            .drive(onNext: { [weak self] cycle in
                self?.updateCycleUI(cycle: cycle)
            })
            .disposed(by: disposeBag)
        
        viewModel.dashboardMessage
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: DashboardMessage(text: "", imageName: .calm))
            .drive(onNext: { [weak self] message in
                self?.updateMessageUI(message: message)
            })
            .disposed(by: disposeBag)
        
        viewModel.canTakePill
            .asDriver()
            .drive(onNext: { [weak self] canTake in
                self?.updateTakePillButton(canTake: canTake)
            })
            .disposed(by: disposeBag)
        
        infoButton.rx.tap
            .bind { [weak self] in
                self?.presentInfoFloatingView()
            }
            .disposed(by: disposeBag)
        
        takePillButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.takePill()
            }
            .disposed(by: disposeBag)
        
        Observable.zip(
            calendarCollectionView.rx.itemSelected,
            calendarCollectionView.rx.modelSelected(DayItem.self)
        )
        .bind { [weak self] indexPath, item in
            self?.handleCellSelection(at: indexPath.item, item: item)
        }
        .disposed(by: disposeBag)
    }
    
    // MARK: - UI Updates
    
    private func updateCycleUI(cycle: PillCycle) {
        let calendar = Calendar.current
        let now = Date()
        
        let daysSinceStart = calendar.dateComponents([.day], from: cycle.startDate, to: now).day ?? 0
        let currentDay = daysSinceStart + 1
        
        progressLabel.text = "\(currentDay)일차"
        totalLabel.text = "/\(cycle.totalDays)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let startDateString = dateFormatter.string(from: cycle.startDate)
        dateLabel.text = "시작일 \(startDateString) · \(cycle.activeDays)/\(cycle.breakDays)"
        
        timeLabel.text = cycle.scheduledTime
        
        updateWeekdayStart(from: cycle.startDate)
    }
    
    private func updateMessageUI(message: DashboardMessage) {
        messageLabel.text = message.text
        
        if let image = UIImage(named: message.imageName.rawValue) {
            characterImageView.image = image
        } else {
            characterImageView.image = UIImage(systemName: "face.smiling")
        }
    }
    
    private func updateTakePillButton(canTake: Bool) {
        guard let cycle = viewModel.currentCycle.value else { return }
        
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
            takePillButton.backgroundColor = AppColor.pillGray
            takePillButton.isEnabled = false
        } else if canTake {
            takePillButton.setTitle("잔디 심기", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen.withAlphaComponent(0.4)
            takePillButton.isEnabled = true
        } else {
            takePillButton.setTitle("잔디 심기", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGray
            takePillButton.isEnabled = false
        }
    }
    
    private func updateWeekdayStart(from startDate: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: startDate)
        
        let baseWeekdays = ["월", "화", "수", "목", "금", "토", "일"]
        
        let startIndex: Int = {
            switch weekday {
            case 2: return 0
            case 3: return 1
            case 4: return 2
            case 5: return 3
            case 6: return 4
            case 7: return 5
            case 1: fallthrough
            default: return 6
            }
        }()
        
        let rotatedWeekdays = Array(baseWeekdays[startIndex...]) + Array(baseWeekdays[..<startIndex])
        
        guard weekdayStackView.arrangedSubviews.count == 7 else { return }
        
        for (index, view) in weekdayStackView.arrangedSubviews.enumerated() {
            if let label = view.subviews.first(where: { $0 is UILabel }) as? UILabel {
                label.text = rotatedWeekdays[index]
            }
        }
    }
    
    private func updateCalendarHeight(for itemCount: Int) {
        let width = view.bounds.width - (DashboardUI.Metric.contentInset * 2)
        guard width > 0 else { return }
        
        let columns = Int(DashboardUI.Metric.columns)
        let rows = ceil(CGFloat(itemCount) / DashboardUI.Metric.columns)
        let insets = DashboardUI.Metric.gridInsets
        let spacing = DashboardUI.Metric.calculateGridSpacing(for: width)
        let totalSpacing = spacing * (DashboardUI.Metric.columns - 1)
        let itemSide = (width - totalSpacing) / DashboardUI.Metric.columns
        let height = insets.top + insets.bottom + rows * itemSide + (rows - 1) * spacing
        
        calendarCollectionView.snp.updateConstraints { $0.height.equalTo(height) }
        calendarCollectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
        view.layoutIfNeeded()
    }
    
    // MARK: - User Interactions
    
    private func handleCellSelection(at index: Int, item: DayItem) {
        if case .scheduled = item.status {
            return
        }
        if case .rest = item.status {
            return
        }
        
        let calendar = Calendar.current
        let isToday = calendar.isDate(item.date, inSameDayAs: Date())
        
        if !isToday || item.status.isTaken {
            presentCalendarSheet(for: index, item: item)
        }
    }
    
    private func presentCalendarSheet(for index: Int, item: DayItem) {
        if #available(iOS 15.0, *) {
            let viewController = CalendarSheetViewController { [weak self] chosenStatus in
                self?.viewModel.updateState(at: index, to: chosenStatus)
            }
            viewController.modalPresentationStyle = .pageSheet
            
            if let sheet = viewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.preferredCornerRadius = 24
                sheet.prefersGrabberVisible = true
            }
            
            present(viewController, animated: true)
            return
        }
        
        let alertController = UIAlertController(title: "상태 선택", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "복용", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .taken)
        })
        
        alertController.addAction(UIAlertAction(title: "지연 복용", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .takenDelayed)
        })
        
        alertController.addAction(UIAlertAction(title: "2알 복용", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .takenDouble)
        })
        
        alertController.addAction(UIAlertAction(title: "미복용", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .missed)
        })
        
        alertController.addAction(UIAlertAction(title: "예정으로 변경", style: .default) { [weak self] _ in
            self?.viewModel.updateState(at: index, to: .scheduled)
        })
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func presentInfoFloatingView() {
        let dimmedBackgroundView = UIView()
        dimmedBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedBackgroundView.alpha = 0
        
        let floatingCardView = UIView()
        floatingCardView.backgroundColor = .systemBackground
        floatingCardView.layer.cornerRadius = 30
        floatingCardView.layer.masksToBounds = true
        
        let titleLabel = UILabel()
        titleLabel.text = "필링 가이드"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppColor.text
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "피임약 복용 상태를 잔디로 알려드려요!"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = AppColor.subtext
        
        let guideStackView = UIStackView()
        guideStackView.axis = .vertical
        guideStackView.spacing = 16
        guideStackView.alignment = .leading
        
        let guideItem1 = makeGuideItem(
            iconColor: AppColor.pillGreen,
            iconType: .solid,
            text: "피임약 복용"
        )
        
        let guideItem2 = makeGuideItem(
            iconColor: AppColor.pillWhite,
            iconType: .doubleCapsule,
            text: "피임약 2알 복용"
        )
        
        let guideItem3 = makeGuideItem(
            iconColor: AppColor.pillBrown,
            iconType: .solid,
            text: "미복용"
        )
        
        let guideItem4 = makeGuideItem(
            iconColor: AppColor.pillWhite,
            iconType: .border,
            text: "휴약"
        )
        
        guideStackView.addArrangedSubview(guideItem1)
        guideStackView.addArrangedSubview(guideItem2)
        guideStackView.addArrangedSubview(guideItem3)
        guideStackView.addArrangedSubview(guideItem4)
        
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("확인", for: .normal)
        confirmButton.setTitleColor(.label, for: .normal)
        confirmButton.backgroundColor = AppColor.pillGray
        confirmButton.layer.cornerRadius = 12
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        
        view.addSubview(dimmedBackgroundView)
        view.addSubview(floatingCardView)
        floatingCardView.addSubview(titleLabel)
        floatingCardView.addSubview(subtitleLabel)
        floatingCardView.addSubview(guideStackView)
        floatingCardView.addSubview(confirmButton)
        
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
        
        UIView.animate(withDuration: 0.3) {
            dimmedBackgroundView.alpha = 1
        }
        
        let dismissAction = { [weak self] in
            UIView.animate(withDuration: 0.3, animations: {
                dimmedBackgroundView.alpha = 0
            }) { _ in
                dimmedBackgroundView.removeFromSuperview()
                floatingCardView.removeFromSuperview()
            }
        }
        
        confirmButton.rx.tap
            .bind { dismissAction() }
            .disposed(by: disposeBag)
        
        let tapGesture = UITapGestureRecognizer()
        dimmedBackgroundView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .bind { _ in dismissAction() }
            .disposed(by: disposeBag)
    }
    
    private enum GuideIconType {
        case solid
        case doubleCapsule
        case border
    }
    
    private func makeGuideItem(iconColor: UIColor, iconType: GuideIconType, text: String) -> UIView {
        let containerView = UIView()
        
        let iconView = UIView()
        iconView.backgroundColor = iconColor
        iconView.layer.cornerRadius = 8
        
        switch iconType {
        case .solid:
            break
        case .doubleCapsule:
            let capsule1 = UIView()
            let capsule2 = UIView()
            capsule1.backgroundColor = AppColor.pillGreen
            capsule2.backgroundColor = AppColor.pillGreen
            capsule1.layer.cornerRadius = 4
            capsule2.layer.cornerRadius = 4
            
            iconView.addSubview(capsule1)
            iconView.addSubview(capsule2)
            
            capsule1.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(6)
                make.centerY.equalToSuperview()
                make.width.equalTo(10)
                make.height.equalTo(24)
            }
            capsule2.snp.makeConstraints { make in
                make.leading.equalTo(capsule1.snp.trailing).offset(2)
                make.centerY.equalToSuperview()
                make.width.equalTo(10)
                make.height.equalTo(24)
            }
        case .border:
            iconView.layer.borderWidth = 1
            iconView.layer.borderColor = AppColor.pillGray.cgColor
        }
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 16, weight: .regular)
        textLabel.textColor = AppColor.text
        
        containerView.addSubview(iconView)
        containerView.addSubview(textLabel)
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        
        return containerView
    }
    
    // MARK: - CollectionView Layout
    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let width = view.bounds.width - (DashboardUI.Metric.contentInset * 2)
        let columns = Int(DashboardUI.Metric.columns)
        let spacing = DashboardUI.Metric.calculateGridSpacing(for: width)
        let insets = DashboardUI.Metric.gridInsets
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
            heightDimension: .fractionalWidth(1.0 / CGFloat(columns))
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: spacing / 2,
            leading: spacing / 2,
            bottom: spacing / 2,
            trailing: spacing / 2
        )
        
        let groupHeight = NSCollectionLayoutDimension.fractionalWidth(1.0 / CGFloat(columns))
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: groupHeight
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: columns
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: insets.top,
            leading: 0,
            bottom: insets.bottom,
            trailing: 0
        )
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
