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
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "background"))
    private let infoButton = UIButton(type: .system)
    private let gearButton = UIButton(type: .system)
    private let characterImageView = UIImageView()
    private let progressLabel = UILabel()
    private let totalLabel = UILabel()
    private let dateInfoStackView = UIStackView()
    private let progressRowStackView = UIStackView()
    private let headerInfoStackView = UIStackView()
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
    
    private let pageControl = UIPageControl()
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
        setupBackgroundImage()
        setupHeaderViews()
        setupViews()
        setupConstraints()
        bindViewModel()
        updateBackgroundForToday()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCalendarHeight(for: viewModel.items.value.count)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .left, .right, .bottom]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - Setup
    
    private func setupBackgroundImage() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(220)
        }
    }
    
    private func setupViews() {
        view.backgroundColor = AppColor.bg
        
        setupHeaderViews()
        setupMessageCardView()
        setupWeekdayStackView()
        setupCalendarCollectionView()
        setupPageControl()
        setupTakePillButton()
        
        addSubviews()
    }
    
    private func setupHeaderViews() {
        infoButton.setImage(DashboardUI.Icon.info, for: .normal)
        infoButton.tintColor = AppColor.secondary
        gearButton.setImage(DashboardUI.Icon.gear, for: .normal)
        gearButton.tintColor = AppColor.secondary
        
        characterImageView.contentMode = .scaleAspectFit
        
        progressLabel.font = Typography.headline1()
        progressLabel.textColor = .black
        totalLabel.font = Typography.headline5()
        totalLabel.textColor = AppColor.secondary
        
        dateLabel.font = Typography.body1(.medium)
        dateLabel.textColor = AppColor.secondary
        timeLabel.font = Typography.body1(.medium)
        timeLabel.textColor = AppColor.secondary
        dateIconImageView.tintColor = AppColor.secondary
        timeIconImageView.tintColor = AppColor.secondary
        
        dateInfoStackView.axis = .vertical
        dateInfoStackView.alignment = .leading
        dateInfoStackView.spacing = 6
        
        let dateLine = UIStackView(arrangedSubviews: [dateIconImageView, dateLabel])
        dateLine.axis = .horizontal
        dateLine.spacing = 8
        dateLine.alignment = .center
        
        let timeLine = UIStackView(arrangedSubviews: [timeIconImageView, timeLabel])
        timeLine.axis = .horizontal
        timeLine.spacing = 8
        timeLine.alignment = .center
        
        dateIconImageView.snp.makeConstraints { $0.width.height.equalTo(20) }
        timeIconImageView.snp.makeConstraints { $0.width.height.equalTo(20) }
        
        dateInfoStackView.addArrangedSubview(dateLine)
        dateInfoStackView.addArrangedSubview(timeLine)
        
        progressRowStackView.axis = .horizontal
        progressRowStackView.alignment = .firstBaseline
        progressRowStackView.spacing = 2
        progressRowStackView.addArrangedSubview(progressLabel)
        progressRowStackView.addArrangedSubview(totalLabel)
        
        headerInfoStackView.axis = .vertical
        headerInfoStackView.alignment = .leading
        headerInfoStackView.spacing = 6
        headerInfoStackView.addArrangedSubview(progressRowStackView)
        headerInfoStackView.addArrangedSubview(dateInfoStackView)
    }
    
    private func setupMessageCardView() {
        messageCardView.backgroundColor = AppColor.bg
        messageCardView.layer.cornerRadius = 20
        messageCardView.layer.borderWidth = 1
        messageCardView.layer.borderColor = AppColor.borderGray.cgColor
        
        messageIconImageView.tintColor = AppColor.pillGreen800
        messageIconImageView.contentMode = .scaleAspectFit
        
        messageLabel.font = Typography.body2(.medium)
        messageLabel.textColor = AppColor.textBlack
        messageLabel.numberOfLines = 1
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
            label.textColor = AppColor.weekdayText
            label.font = Typography.caption(.medium)
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
        calendarCollectionView.showsVerticalScrollIndicator = false
        calendarCollectionView.showsHorizontalScrollIndicator = false
        calendarCollectionView.register(
            CalendarCell.self,
            forCellWithReuseIdentifier: CalendarCell.identifier
        )
        calendarCollectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
    }
    
    private func setupPageControl() {
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = AppColor.pillGreen800
        pageControl.pageIndicatorTintColor = AppColor.notYetGray
        pageControl.isUserInteractionEnabled = false
        pageControl.hidesForSinglePage = true
    }
    
    private func setupTakePillButton() {
        takePillButton.setTitle("잔디 심기", for: .normal)
        takePillButton.setTitleColor(.label, for: .normal)
        takePillButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        takePillButton.backgroundColor = AppColor.pillGreen200
        takePillButton.layer.cornerRadius = 12
    }
    
    private func addSubviews() {
        view.addSubview(infoButton)
        view.addSubview(gearButton)
        view.addSubview(characterImageView)
        view.addSubview(headerInfoStackView)
        
        view.addSubview(messageCardView)
        messageCardView.addSubview(messageIconImageView)
        messageCardView.addSubview(messageLabel)
        
        view.addSubview(weekdayStackView)
        view.addSubview(calendarCollectionView)
        view.addSubview(pageControl)
        view.addSubview(takePillButton)
    }
    
    private func setupConstraints() {
        let contentInset: CGFloat = 16
        
        infoButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            make.trailing.equalTo(gearButton.snp.leading).offset(-8)
            make.width.height.equalTo(30)
        }
        
        gearButton.snp.makeConstraints { make in
            make.centerY.equalTo(infoButton)
            make.trailing.equalToSuperview().inset(contentInset)
            make.width.height.equalTo(30)
        }
        
        characterImageView.snp.makeConstraints { make in
            make.top.equalTo(infoButton.snp.bottom)
            make.leading.equalToSuperview().inset(contentInset)
            make.width.lessThanOrEqualTo(180)
            make.height.equalTo(180)
        }
        
        headerInfoStackView.snp.makeConstraints { make in
            make.centerY.equalTo(characterImageView.snp.centerY)
            make.leading.equalTo(characterImageView.snp.trailing).offset(12)
            make.trailing.equalTo(view.safeAreaLayoutGuide)
        }
        
        messageCardView.snp.makeConstraints { make in
            make.top.lessThanOrEqualTo(characterImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(contentInset)
            make.height.equalTo(52)
        }
        
        messageIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(messageIconImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        weekdayStackView.snp.makeConstraints { make in
            make.top.lessThanOrEqualTo(messageCardView.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(contentInset)
            make.height.equalTo(20)
        }
        
        calendarCollectionView.snp.makeConstraints { make in
            make.top.lessThanOrEqualTo(weekdayStackView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(contentInset)
            make.height.equalTo(280)
        }
        
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(calendarCollectionView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(12)
        }
        
        takePillButton.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(contentInset)
            make.height.equalTo(70)
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
                self?.updatePageControl(for: items.count)
            })
            .disposed(by: disposeBag)
        
        viewModel.pillInfo
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: PillInfo(name: "", takingDays: 0, breakDays: 0))
            .drive(onNext: { [weak self] pillInfo in
                self?.dateLabel.text = "\(pillInfo.takingDays)/\(pillInfo.breakDays)"
            })
            .disposed(by: disposeBag)
        
        viewModel.currentCycle
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: PillCycle(
                id: UUID(),
                cycleNumber: 1,
                startDate: Date(),
                activeDays: 21,
                breakDays: 7,
                scheduledTime: "09:00",
                records: [],
                createdAt: Date()
            ))
            .drive(onNext: { [weak self] cycle in
                self?.updateCycleUI(cycle: cycle)
                self?.updateBackgroundForToday()
            })
            .disposed(by: disposeBag)
        
        viewModel.dashboardMessage
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: DashboardMessage(text: "", imageName: .rest))
            .drive(onNext: { [weak self] message in
                self?.updateMessageUI(message: message)
                self?.updateBackgroundForToday()
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
        
        gearButton.rx.tap
            .bind { [weak self] in
                let vm = DIContainer.shared.makeSettingViewModel()
                let vc = SettingViewController(viewModel: vm)
                self?.navigationController?.pushViewController(vc, animated: true)
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
        progressLabel.textColor = AppColor.textBlack
        totalLabel.text = "/\(cycle.totalDays)"
        
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
    
    private func updateBackgroundForToday() {
        guard let cycle = viewModel.currentCycle.value else { return }
        let calendar = Calendar.current
        let now = Date()
        guard let todayRecord = cycle.records.first(where: { calendar.isDate($0.scheduledDateTime, inSameDayAs: now) }) else {
            backgroundImageView.image = UIImage(named: "background")
            return
        }
        switch todayRecord.status {
        case .rest:
            backgroundImageView.image = UIImage(named: "restBackground")
        default:
            backgroundImageView.image = UIImage(named: "background")
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
            takePillButton.backgroundColor = AppColor.notYetGray
            takePillButton.isEnabled = false
        } else if canTake {
            takePillButton.setTitle("잔디 심기", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen200
            takePillButton.isEnabled = true
        } else {
            takePillButton.setTitle("잔디 심기", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen200
            takePillButton.isEnabled = true
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
        let width = view.bounds.width - 40
        guard width > 0 else { return }
        
        let columns: CGFloat = 7
        let spacing: CGFloat = 6
        let rows = ceil(CGFloat(itemCount) / columns)
        let totalSpacing = spacing * (columns - 1)
        let itemSide = (width - totalSpacing) / columns
        let height = rows * itemSide + (rows - 1) * spacing
        
        calendarCollectionView.snp.updateConstraints { $0.height.equalTo(height) }
        calendarCollectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
        view.layoutIfNeeded()
    }
    
    private func updatePageControl(for itemCount: Int) {
        let columns = 7
        let rows = Int(ceil(Double(itemCount) / Double(columns)))
        
        // 4주(4줄) 기준으로 페이지 계산
        let rowsPerPage = 4
        let numberOfPages = Int(ceil(Double(rows) / Double(rowsPerPage)))
        
        pageControl.numberOfPages = max(1, numberOfPages)
        pageControl.currentPage = 0
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
        let infoView = InfoFloatingView()
        infoView.onConfirm = { [weak infoView] in
            infoView?.dismiss()
        }
        infoView.show(in: self.view)
    }
    
    private func makeGuideItemWithCalendarCell(status: PillStatus, text: String) -> UIView {
        let containerView = UIView()
        
        let calendarCell = CalendarCell()
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 16, weight: .regular)
        textLabel.textColor = AppColor.textBlack
        
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
    
    // MARK: - CollectionView Layout
    
    private func calculateOptimalLayout() -> (cellSize: CGFloat, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        let availableWidth = view.bounds.width - 40
        let columns: CGFloat = 7
        let minCellSize: CGFloat = 40
        let minHorizontalSpacing: CGFloat = 2
        let maxHorizontalSpacing: CGFloat = 16
        let minVerticalSpacing: CGFloat = 12
        let maxVerticalSpacing: CGFloat = 24
        
        var bestCellSize: CGFloat = minCellSize
        var bestHorizontalSpacing: CGFloat = minHorizontalSpacing
        
        for horizontalSpacing in stride(from: minHorizontalSpacing, through: maxHorizontalSpacing, by: 1) {
            let totalHorizontalSpacing = horizontalSpacing * (columns - 1)
            let cellSize = (availableWidth - totalHorizontalSpacing) / columns
            
            if cellSize >= minCellSize {
                bestCellSize = cellSize
                bestHorizontalSpacing = horizontalSpacing
            }
        }
        
        let verticalSpacing: CGFloat = {
            if bestCellSize < 45 {
                return minVerticalSpacing
            } else if bestCellSize < 50 {
                return 18
            } else if bestCellSize < 55 {
                return 20
            } else if bestCellSize < 60 {
                return 22
            } else {
                return maxVerticalSpacing
            }
        }()
        
        return (bestCellSize, bestHorizontalSpacing, verticalSpacing)
    }
    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let layout = calculateOptimalLayout()
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(layout.cellSize),
            heightDimension: .absolute(layout.cellSize)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(layout.cellSize)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(layout.horizontalSpacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = layout.verticalSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0
        )
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
