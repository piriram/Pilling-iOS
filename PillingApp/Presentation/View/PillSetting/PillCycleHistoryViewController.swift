import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CoreData

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
        
        // Row selection (navigate to detail)
        tableView.rx.modelSelected(PillCycle.self)
            .subscribe(onNext: { [weak self] cycle in
                guard let self = self else { return }
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
                let detailVC = PillCycleDetailViewController(cycle: cycle)
                self.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
}

