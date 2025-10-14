import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CoreData

// MARK: - Repository
protocol PillCycleHistoryRepository {
    func fetchAllCycles() throws -> [PillCycle]
}

final class CoreDataPillCycleHistoryRepository: PillCycleHistoryRepository {
    private let context: NSManagedObjectContext?
    init(context: NSManagedObjectContext?) { self.context = context }

    func fetchAllCycles() throws -> [PillCycle] {
        guard let ctx = context else { return [] }
        let request = NSFetchRequest<NSManagedObject>(entityName: "PillCycleEntity")
        let sortStart = NSSortDescriptor(key: "startDate", ascending: false)
        request.sortDescriptors = [sortStart]

        let objects = try ctx.fetch(request)
        var result: [PillCycle] = []
        result.reserveCapacity(objects.count)
        for obj in objects {
            let id = (obj.value(forKey: "id") as? UUID) ?? UUID()
            let cycleNumber = (obj.value(forKey: "cycleNumber") as? Int) ?? 0
            let startDate = (obj.value(forKey: "startDate") as? Date) ?? Date()
            let activeDays = (obj.value(forKey: "activeDays") as? Int) ?? 21
            let breakDays = (obj.value(forKey: "breakDays") as? Int) ?? 7
            let scheduledTime = (obj.value(forKey: "scheduledTime") as? String) ?? "09:00"
            let createdAt = startDate
            let records = (obj.value(forKey: "records") as? [PillRecord]) ?? []
            let cycle = PillCycle(
                id: id,
                cycleNumber: cycleNumber,
                startDate: startDate,
                activeDays: activeDays,
                breakDays: breakDays,
                scheduledTime: scheduledTime,
                records: records,
                createdAt: createdAt
            )
            result.append(cycle)
        }
        return result
    }
}

// MARK: - ViewModel
final class PillCycleHistoryViewModel {
    let items = BehaviorRelay<[PillCycle]>(value: [])
    private let repository: PillCycleHistoryRepository

    init(context: NSManagedObjectContext?) {
        self.repository = CoreDataPillCycleHistoryRepository(context: context)
    }

    func loadData() {
        do {
            var cycles = try repository.fetchAllCycles()
            cycles.sort { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.startDate > rhs.startDate
            }
            items.accept(cycles)
        } catch {
            // print("Fetch cycles failed: \(error)")
        }
    }
}

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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"

        let start = formatter.string(from: cycle.startDate)
        let totalDays = (Mirror(reflecting: cycle).children.first { $0.label == "totalDays" }?.value as? Int) ?? (cycle.activeDays + cycle.breakDays)
        let endDate = Calendar.current.date(byAdding: .day, value: max(totalDays - 1, 0), to: cycle.startDate) ?? cycle.startDate
        let end = formatter.string(from: endDate)

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

// MARK: - ViewController
final class PillCycleHistoryViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let disposeBag = DisposeBag()
    private let viewModel: PillCycleHistoryViewModel

    init(viewModel: PillCycleHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(context: NSManagedObjectContext?) {
        self.init(viewModel: PillCycleHistoryViewModel(context: context))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.bg
        title = "히스토리"
        setupTable()
        setupEmpty()
        setupConstraints()
        bind()
        viewModel.loadData()
    }

    private func setupTable() {
        tableView.register(PillCycleHistoryCell.self, forCellReuseIdentifier: PillCycleHistoryCell.reuseID)
        tableView.rowHeight = 72
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
    }

    private func setupEmpty() {
        emptyLabel.text = "기록이 없어요"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = AppColor.weekdayText
        emptyLabel.font = Typography.body2(.medium)
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        // Bind items to tableView with custom cell
        viewModel.items
            .bind(to: tableView.rx.items(cellIdentifier: PillCycleHistoryCell.reuseID, cellType: PillCycleHistoryCell.self)) { _, cycle, cell in
                cell.configure(with: cycle)
            }
            .disposed(by: disposeBag)

        // Empty state visibility
        viewModel.items
            .map { !$0.isEmpty }
            .bind(to: emptyLabel.rx.isHidden)
            .disposed(by: disposeBag)

        // Row selection (optional: push detail if needed)
        tableView.rx.modelSelected(PillCycle.self)
            .subscribe(onNext: { [weak self] cycle in
                self?.tableView.deselectRow(at: self?.tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0), animated: true)
                // TODO: Navigate to detail if needed
            })
            .disposed(by: disposeBag)
    }
}

