import UIKit
import SnapKit

final class CycleDetailViewController: UIViewController {
    private let cycle: Cycle
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var records: [DayRecord] { cycle.records }
    
    init(cycle: Cycle) {
        self.cycle = cycle
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.bg
        title = "사이클 상세"
        setupTable()
        tableView.tableHeaderView = makeCycleHeader()
        layoutHeaderToFit()
    }
    
    private func setupTable() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        tableView.register(DayRecordCell.self, forCellReuseIdentifier: DayRecordCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
    }
    
    private func makeCycleHeader() -> UIView {
        let container = UIView()
        let titleLabel = UILabel()
        titleLabel.text = "Cycle Attributes"
        titleLabel.font = Typography.headline3(.bold)
        titleLabel.textColor = AppColor.textBlack
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        
        // 모든 속성을 Key-Value로 나열
        let rows: [(String, String)] = [
            ("id", cycle.id.uuidString),
            ("cycleNumber", "\(cycle.cycleNumber)"),
            ("startDate", cycle.startDate.formatted(style: .yearMonthDayPoint)),
            ("activeDays", "\(cycle.activeDays)"),
            ("breakDays", "\(cycle.breakDays)"),
            ("scheduledTime", cycle.scheduledTime),
            ("createdAt", cycle.createdAt.formatted(style: .yearMonthDayPoint)),
            ("totalDays", "\(cycle.totalDays)")
        ]
        rows.forEach { key, value in
            stack.addArrangedSubview(KeyValueRowView(key: key, value: value))
        }
        
        container.addSubview(titleLabel)
        container.addSubview(stack)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
        return container
    }
    
    private func layoutHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let height = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = header.frame
        if frame.height != height {
            frame.size.height = height
            header.frame = frame
            tableView.tableHeaderView = header
        }
    }
}

extension CycleDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DayRecordCell.reuseID, for: indexPath) as! DayRecordCell
        cell.configure(with: records[indexPath.row])
        return cell
    }
}
