import UIKit
import SnapKit

final class PillCycleDetailViewController: UIViewController {
    
    private let cycle: PillCycle
    
    // MARK: - UI Components
    
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.alignment = .fill
        sv.distribution = .fill
        return sv
    }()
    
    // MARK: - Initializer
    
    init(cycle: PillCycle) {
        self.cycle = cycle
        super.init(nibName: nil, bundle: nil)
        self.title = "상세"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.bg
        
        setupViews()
        setupLayout()
        configureContents()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
    }
    
    private func setupLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        stackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(20)
        }
    }
    
    private func configureContents() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        stackView.addArrangedSubview(createSummaryView())
        
        let recordsTitleLabel = UILabel()
        recordsTitleLabel.text = "기록"
        recordsTitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        recordsTitleLabel.textColor = .label
        stackView.addArrangedSubview(recordsTitleLabel)
        
        cycle.records.forEach { record in
            let row = createRecordRow(record: record)
            stackView.addArrangedSubview(row)
        }
    }
    
    // MARK: - Components Creation
    
    private func createSummaryView() -> UIView {
        let container = UIView()
        
        // Cycle Number
        let cycleNumberLabel = UILabel()
        cycleNumberLabel.font = Typography.headline4(.bold)
        cycleNumberLabel.textColor = .label
        cycleNumberLabel.text = "사이클 \(cycle.cycleNumber)"
        
        // Date Range
        let dateRangeLabel = UILabel()
        dateRangeLabel.font = Typography.body2()
        dateRangeLabel.textColor = .secondaryLabel
        let endDate = Calendar.current.date(byAdding: .day, value: cycle.activeDays + cycle.breakDays - 1, to: cycle.startDate) ?? cycle.startDate
        dateRangeLabel.text = "\(formatDate(cycle.startDate)) ~ \(formatDate(endDate))"
        
        // Scheduled Time
        let scheduledTimeLabel = UILabel()
        scheduledTimeLabel.font = Typography.body2()
        scheduledTimeLabel.textColor = .secondaryLabel
        scheduledTimeLabel.text = "복용 시간: \(cycle.scheduledTime)"
        
        let createdAtLabel = UILabel()
        createdAtLabel.font = Typography.caption()
        createdAtLabel.textColor = .secondaryLabel
        createdAtLabel.text = "생성일: \(formatDateTime(cycle.createdAt))"
        
        let vStack = UIStackView(arrangedSubviews: [cycleNumberLabel, dateRangeLabel, scheduledTimeLabel, createdAtLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.alignment = .leading
        
        container.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return container
    }
    
    private func createRecordRow(record: PillRecord) -> UIView {
        let container = UIView()
        
        let dateLabel = UILabel()
        dateLabel.font = Typography.body2()
        dateLabel.textColor = .label
        dateLabel.text = formatDateTime(record.scheduledDateTime)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let statusLabel = UILabel()
        statusLabel.font = Typography.body2()
        statusLabel.textColor = .label
        
        let statusTextBase = getStatusText(record.status)
        let takenInfo: String = {
            if let takenAt = record.takenAt {
                return "(\(formatTime(takenAt)))"
            } else {
                return ""
            }
        }()
        statusLabel.text = [statusTextBase, takenInfo].joined(separator: takenInfo.isEmpty ? "" : " ")
        
        statusLabel.textAlignment = .center
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let memoLabel = UILabel()
        memoLabel.font = Typography.caption()
        memoLabel.textColor = .secondaryLabel
        memoLabel.numberOfLines = 0
        memoLabel.text = record.memo.isEmpty ? nil : record.memo
        
        let hStack = UIStackView(arrangedSubviews: [dateLabel, statusLabel])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        
        let vStack = UIStackView(arrangedSubviews: [hStack])
        vStack.axis = .vertical
        vStack.spacing = 4
        
        if let memo = memoLabel.text, !memo.isEmpty {
            vStack.addArrangedSubview(memoLabel)
        }
        
        container.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return container
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM.dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func getStatusText(_ status: PillStatus) -> String {
        switch status {
        case .taken, .todayTaken: return "복용"
        case .takenDelayed, .todayTakenDelayed: return "지연 복용"
        case .takenDouble: return "이중 복용"
        case .missed, .todayDelayed: return "미복용"
        case .scheduled, .todayNotTaken: return "예정"
        case .rest: return "휴약"
        }
    }
    
}
