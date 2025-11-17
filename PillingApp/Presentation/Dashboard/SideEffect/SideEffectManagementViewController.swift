//
//  SideEffectManagementViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/10/25.
//

import UIKit
import SnapKit

// MARK: - SideEffectManagementViewController
final class SideEffectManagementViewController: UIViewController {
    
    // MARK: - Types
    
    private enum Section: Hashable {
        case visible
        case hidden
        
        var title: String {
            switch self {
            case .visible: return "표시 중"
            case .hidden:  return "숨김"
            }
        }
    }
    
    private struct Item: Hashable {
        let tag: SideEffectTag
        func hash(into hasher: inout Hasher) { hasher.combine(tag.id) }
        static func == (lhs: Item, rhs: Item) -> Bool { lhs.tag.id == rhs.tag.id }
    }
    
    // MARK: - Properties
    
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    private var visibleTags: [SideEffectTag] = []
    private var hiddenTags:  [SideEffectTag] = []
    
    private lazy var collectionView: UICollectionView = {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = AppColor.bg
        cv.dragInteractionEnabled = true
        return cv
    }()
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot  = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource!
    
    // MARK: - Init
    
    init(userDefaultsManager: UserDefaultsManagerProtocol) {
        self.userDefaultsManager = userDefaultsManager
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
        configureSupplementaries()
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
    
    // viewDidLoad() 내부
    private func setupNavigationBar() {
        title = "부작용 관리"
        navigationController?.navigationBar.prefersLargeTitles = false
        
    }
    
    // MARK: - DataSource
    
    private func configureDataSource() {
        // Cell registration
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
            var content = UIListContentConfiguration.valueCell()
            content.text = item.tag.name
            cell.contentConfiguration = content
            cell.accessories = [.reorder(displayed: .always)]
        }
        
        dataSource = DataSource(collectionView: collectionView) { cv, indexPath, item in
            cv.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        // Section header
        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard let self, kind == UICollectionView.elementKindSectionHeader else { return nil }
            let headerReg = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: kind) { header, _, indexPath in
                let section = self.sectionIdentifier(at: indexPath.section)
                var content = UIListContentConfiguration.groupedHeader()
                content.text = section.title
                header.contentConfiguration = content
            }
            return cv.dequeueConfiguredReusableSupplementary(using: headerReg, for: indexPath)
        }
    }
    
    private func sectionIdentifier(at index: Int) -> Section {
        Array(dataSource.snapshot().sectionIdentifiers)[index]
    }
    
    // MARK: - Supplementaries (Footer: 추가 버튼)
    
    private func configureSupplementaries() {
        let footerReg = UICollectionView.SupplementaryRegistration<FooterAddView>(elementKind: UICollectionView.elementKindSectionFooter) { [weak self] footer, _, indexPath in
            guard let self else { return }
            let section = self.sectionIdentifier(at: indexPath.section)
            footer.configure(title: section == .visible ? "표시 태그 추가" : "숨김 태그 추가") { [weak self] in
                self?.didTapAdd(in: section)
            }
        }
        
        // Keep original provider for header
        let originalProvider = dataSource.supplementaryViewProvider
        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            if kind == UICollectionView.elementKindSectionFooter {
                return cv.dequeueConfiguredReusableSupplementary(using: footerReg, for: indexPath)
            }
            return originalProvider?(cv, kind, indexPath)
        }
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout {
            layout.configuration.boundarySupplementaryItems = [
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)),
                      elementKind: UICollectionView.elementKindSectionHeader,
                      alignment: .top),
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(52)),
                      elementKind: UICollectionView.elementKindSectionFooter,
                      alignment: .bottom)
            ]
        }
    }
    
    // MARK: - Reordering
    
    private func configureReordering() {
        collectionView.reorderingCadence = .immediate
        dataSource.reorderingHandlers.canReorderItem = { _ in true }
        dataSource.reorderingHandlers.didReorder = { [weak self] _ in
            guard let self else { return }
            self.syncArraysFromSnapshot()
            self.persistOrderIfNeeded()
        }
    }
    
    // MARK: - Data
    
    private func loadInitialData() {
        // TODO: 저장소에서 불러오기
        // visibleTags = userDefaultsManager.loadVisibleSideEffectTags()
        // hiddenTags  = userDefaultsManager.loadHiddenSideEffectTags()
        
        // 임시(Mock)
        if visibleTags.isEmpty && hiddenTags.isEmpty {
            visibleTags = [
                SideEffectTag(id: "nausea",  name: "메스꺼움", order: 0),
                SideEffectTag(id: "headache", name: "두통",    order: 1)
            ]
            hiddenTags = [
                SideEffectTag(id: "acne",     name: "여드름",  order: 0),
                SideEffectTag(id: "bloating", name: "복부팽만", order: 1)
            ]
        }
    }
    
    private func applySnapshot(animating: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.visible, .hidden])
        snapshot.appendItems(visibleTags.map(Item.init), toSection: .visible)
        snapshot.appendItems(hiddenTags.map(Item.init),  toSection: .hidden)
        dataSource.apply(snapshot, animatingDifferences: animating)
    }
    
    private func syncArraysFromSnapshot() {
        let snapshot = dataSource.snapshot()
        visibleTags = snapshot.itemIdentifiers(inSection: .visible).enumerated().map { idx, item in
            var tag = item.tag
            tag.order = idx
            return tag
        }
        hiddenTags = snapshot.itemIdentifiers(inSection: .hidden).enumerated().map { idx, item in
            var tag = item.tag
            tag.order = idx
            return tag
        }
    }
    
    private func persistOrderIfNeeded() {
        // TODO: 정렬/노출 상태 저장
        // userDefaultsManager.saveVisibleSideEffectTags(visibleTags)
        // userDefaultsManager.saveHiddenSideEffectTags(hiddenTags)
    }
    
    // MARK: - Actions
    
    private func didTapAdd(in section: Section) {
        // 새 태그 생성
        switch section {
        case .visible:
            let newOrder = visibleTags.count
            let new = SideEffectTag(id: UUID().uuidString, name: "새 태그", order: newOrder)
            visibleTags.append(new)
        case .hidden:
            let newOrder = hiddenTags.count
            let new = SideEffectTag(id: UUID().uuidString, name: "새 태그", order: newOrder)
            hiddenTags.append(new)
        }
        applySnapshot(animating: true)
        persistOrderIfNeeded()
    }
}
