import UIKit
import SnapKit

// MARK: - SideEffectManagementViewController
final class SideEffectManagementViewController: UIViewController {
    
    // MARK: - Types
    
    private struct Item: Hashable {
        let tag: SideEffectTag
        func hash(into hasher: inout Hasher) { hasher.combine(tag.id) }
        static func == (lhs: Item, rhs: Item) -> Bool { lhs.tag.id == rhs.tag.id }
    }
    
    // MARK: - Properties
    
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let analytics: AnalyticsServiceProtocol
    
    private var tags: [SideEffectTag] = []
    private var isEditingOrder: Bool = false
    
    private lazy var collectionView: UICollectionView = {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = AppColor.bg
        cv.dragInteractionEnabled = true
        cv.allowsSelection = false
        return cv
    }()
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Int, Item>
    private typealias Snapshot  = NSDiffableDataSourceSnapshot<Int, Item>
    private var dataSource: DataSource!
    
    private lazy var editButton: UIBarButtonItem = {
        UIBarButtonItem(title: "편집", style: .plain, target: self, action: #selector(didTapEditButton))
    }()
    
    private lazy var addButton: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(didTapAddButton))
    }()
    
    // MARK: - Init
    
    init(
        userDefaultsManager: UserDefaultsManagerProtocol,
        analytics: AnalyticsServiceProtocol = DIContainer.shared.getAnalyticsService()
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.analytics = analytics
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        configureDataSource()
        configureReordering()
        loadInitialData()
        applySnapshot(animating: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppColor.bg
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupNavigationBar() {
        title = "부작용 관리"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationItem.rightBarButtonItems = [addButton, editButton]
    }
    
    private func updateNavigationBar() {
        if isEditingOrder {
            editButton.title = "완료"
            editButton.style = .done
            addButton.isEnabled = false
        } else {
            editButton.title = "편집"
            editButton.style = .plain
            addButton.isEnabled = true
        }
    }
    
    // MARK: - DataSource
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, indexPath, item in
            guard let self else { return }
            
            var content = UIListContentConfiguration.cell()
            content.text = item.tag.name
            content.textProperties.color = .label
            
            cell.contentConfiguration = content
            cell.contentView.alpha = item.tag.isVisible ? 1.0 : 0.6
            
            if self.isEditingOrder {
                cell.accessories = [.reorder(displayed: .always)]
            } else {
                let toggle = UISwitch()
                toggle.isOn = item.tag.isVisible
                toggle.accessibilityIdentifier = item.tag.id
                toggle.addTarget(self, action: #selector(self.didToggleVisibility(_:)), for: .valueChanged)
                
                let toggleAccessory = UICellAccessory.CustomViewConfiguration(
                    customView: toggle,
                    placement: .trailing(displayed: .always)
                )
                
                cell.accessories = [.customView(configuration: toggleAccessory)]
            }
        }
        
        dataSource = DataSource(collectionView: collectionView) { cv, indexPath, item in
            cv.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    // MARK: - Reordering
    
    private func configureReordering() {
        collectionView.reorderingCadence = .immediate
        dataSource.reorderingHandlers.canReorderItem = { [weak self] _ in
            self?.isEditingOrder ?? false
        }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self else { return }
            print("🔄 [SideEffectManagement] didReorder 호출됨")
            print("   transaction: \(transaction)")
            print("   재정렬 전 tags: \(self.tags.map { "\($0.name)[\($0.order)]" })")
            self.syncArrayFromSnapshot()
            print("   재정렬 후 tags: \(self.tags.map { "\($0.name)[\($0.order)]" })")
            self.persistTags()
        }
    }
    
    // MARK: - Data
    
    private func loadInitialData() {
        print("📥 [SideEffectManagement] loadInitialData")
        tags = userDefaultsManager.loadSideEffectTags()
        print("   로드한 태그: \(tags.map { "\($0.name)[\($0.order)]\($0.isVisible ? "👁" : "🙈")" })")
        sortTagsByVisibility()
    }
    
    private func applySnapshot(animating: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(tags.map(Item.init), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: animating)
    }
    
    @objc private func didToggleVisibility(_ sender: UISwitch) {
        guard
            let id = sender.accessibilityIdentifier,
            let index = tags.firstIndex(where: { $0.id == id })
        else { return }

        print("👁️ [SideEffectManagement] visibility 토글")
        print("   index: \(index), 태그: \(tags[index].name)")
        print("   변경: \(tags[index].isVisible) → \(sender.isOn)")

        tags[index].isVisible = sender.isOn
        analytics.logEvent(.sideEffectVisibilityToggled(tagName: tags[index].name, isVisible: sender.isOn))
        sortTagsByVisibility()
        persistTags()

        var snapshot = Snapshot()
        snapshot.appendSections([0])
        let items = tags.map(Item.init)
        snapshot.appendItems(items, toSection: 0)

        if let changedItem = items.first(where: { $0.tag.id == id }) {
            snapshot.reconfigureItems([changedItem])
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func syncArrayFromSnapshot() {
        print("📸 [SideEffectManagement] syncArrayFromSnapshot 시작")
        let snapshot = dataSource.snapshot()
        let items = snapshot.itemIdentifiers(inSection: 0)
        print("   스냅샷 아이템 순서: \(items.map { $0.tag.name })")

        tags = items.enumerated().map { idx, item in
            var tag = item.tag
            print("   [\(idx)] \(tag.name): order \(tag.order) → \(idx)")
            tag.order = idx
            return tag
        }
        print("   최종 tags: \(tags.map { "\($0.name)[\($0.order)]" })")
        analytics.logEvent(.sideEffectReordered)
    }
    
    private func sortTagsByVisibility() {
        print("👁️ [SideEffectManagement] sortTagsByVisibility 시작")
        print("   정렬 전: \(tags.map { "\($0.name)[\($0.order)]\($0.isVisible ? "👁" : "🙈")" })")

        let visibleTags = tags.filter { $0.isVisible }.sorted { $0.order < $1.order }
        let hiddenTags = tags.filter { !$0.isVisible }.sorted { $0.order < $1.order }

        print("   visible 태그: \(visibleTags.map { "\($0.name)[\($0.order)]" })")
        print("   hidden 태그: \(hiddenTags.map { "\($0.name)[\($0.order)]" })")

        tags = visibleTags + hiddenTags

        for index in tags.indices {
            tags[index].order = index
        }

        print("   정렬 후: \(tags.map { "\($0.name)[\($0.order)]\($0.isVisible ? "👁" : "🙈")" })")
    }
    
    private func persistTags() {
        print("💾 [SideEffectManagement] persistTags 호출")
        let savingSummary = tags
            .map { "\($0.name)[\($0.order)]\(String($0.id.prefix(8)))" }
            .joined(separator: ", ")
        print("   저장할 태그: \(savingSummary)")
        userDefaultsManager.saveSideEffectTags(tags)

        // 저장 후 검증
        let loaded = userDefaultsManager.loadSideEffectTags()
        let loadedSummary = loaded
            .map { "\($0.name)[\($0.order)]\(String($0.id.prefix(8)))" }
            .joined(separator: ", ")
        print("   저장 후 로드: \(loadedSummary)")
    }

    // MARK: - Actions

    @objc private func didTapEditButton() {
        print("✏️ [SideEffectManagement] 편집 버튼 탭")
        print("   편집 모드: \(isEditingOrder) → \(!isEditingOrder)") 
        isEditingOrder.toggle()
        updateNavigationBar()
        applySnapshot(animating: true)
    }
    
    @objc private func didTapAddButton() {
        showAddTagAlert()
    }
    
    private func showAddTagAlert() {
        let alert = UIAlertController(title: "새 태그 추가", message: "태그 이름을 입력하세요", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "태그 이름"
            textField.autocapitalizationType = .none
        }
        
        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self, weak alert] _ in
            guard let self,
                  let textField = alert?.textFields?.first,
                  let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            
            let newTag = SideEffectTag(
                name: name,
                isVisible: true,
                order: self.tags.count,
                isDefault: false
            )
            self.tags.append(newTag)
            self.analytics.logEvent(.sideEffectTagCreated(tagName: name))
            self.sortTagsByVisibility()
            self.persistTags()
            self.applySnapshot(animating: true)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}
