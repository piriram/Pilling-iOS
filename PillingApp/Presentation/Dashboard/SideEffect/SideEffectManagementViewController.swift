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
    
    private struct Item: Hashable {
        let tag: SideEffectTag
        func hash(into hasher: inout Hasher) { hasher.combine(tag.id) }
        static func == (lhs: Item, rhs: Item) -> Bool { lhs.tag.id == rhs.tag.id }
    }
    
    // MARK: - Properties
    
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
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
                toggle.tag = indexPath.row
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
        dataSource.reorderingHandlers.didReorder = { [weak self] _ in
            guard let self else { return }
            self.syncArrayFromSnapshot()
            self.persistTags()
        }
    }
    
    // MARK: - Data
    
    private func loadInitialData() {
        tags = userDefaultsManager.loadSideEffectTags()
        sortTagsByVisibility()
    }
    
    private func applySnapshot(animating: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(tags.map(Item.init), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: animating)
    }
    
    @objc private func didToggleVisibility(_ sender: UISwitch) {
        let index = sender.tag
        guard index < tags.count else { return }

        let changedTagId = tags[index].id
        let wasVisible = tags[index].isVisible
        let nowVisible = sender.isOn

        // 🔍 [디버깅] 토글 전 상태
        print("🔍 [SideEffectManagement] didToggleVisibility")
        print("   🏷️ 태그: '\(tags[index].name)' (id: \(changedTagId))")
        print("   📊 index: \(index)")
        print("   ⬅️ wasVisible: \(wasVisible) → nowVisible: \(nowVisible)")
        print("   📋 토글 전 tags 순서:")
        for (i, tag) in tags.enumerated() {
            print("      [\(i)] \(tag.name) (visible: \(tag.isVisible), order: \(tag.order))")
        }

        // 토글된 태그를 배열에서 제거
        var changedTag = tags.remove(at: index)
        changedTag.isVisible = nowVisible

        // visible/hidden 그룹으로 나누기
        let visibleTags = tags.filter { $0.isVisible }
        let hiddenTags = tags.filter { !$0.isVisible }

        // 변경된 태그를 적절한 그룹의 맨 뒤에 추가
        if nowVisible {
            // visible로 변경 -> visible 그룹의 맨 뒤에 추가
            tags = visibleTags + [changedTag] + hiddenTags
        } else {
            // hidden으로 변경 -> hidden 그룹의 맨 뒤에 추가
            tags = visibleTags + hiddenTags + [changedTag]
        }

        // order 값 재설정
        for i in tags.indices {
            tags[i].order = i
        }

        // 🔍 [디버깅] 토글 후 상태
        print("   📋 토글 후 tags 순서:")
        for (i, tag) in tags.enumerated() {
            print("      [\(i)] \(tag.name) (visible: \(tag.isVisible), order: \(tag.order))")
        }

        persistTags()

        var snapshot = Snapshot()
        snapshot.appendSections([0])
        let items = tags.map(Item.init)
        snapshot.appendItems(items, toSection: 0)

        if let changedItem = items.first(where: { $0.tag.id == changedTagId }) {
            snapshot.reconfigureItems([changedItem])
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func syncArrayFromSnapshot() {
        let snapshot = dataSource.snapshot()
        tags = snapshot.itemIdentifiers(inSection: 0).enumerated().map { idx, item in
            var tag = item.tag
            tag.order = idx
            return tag
        }
    }
    
    private func sortTagsByVisibility() {
        // 🔍 [디버깅] 정렬 전
        print("🔍 [SideEffectManagement] sortTagsByVisibility - 정렬 전")
        for (i, tag) in tags.enumerated() {
            print("   [\(i)] \(tag.name) (visible: \(tag.isVisible), order: \(tag.order))")
        }

        let visibleTags = tags.filter { $0.isVisible }.sorted { $0.order < $1.order }
        let hiddenTags = tags.filter { !$0.isVisible }.sorted { $0.order < $1.order }
        tags = visibleTags + hiddenTags

        for index in tags.indices {
            tags[index].order = index
        }

        // 🔍 [디버깅] 정렬 후
        print("🔍 [SideEffectManagement] sortTagsByVisibility - 정렬 후")
        for (i, tag) in tags.enumerated() {
            print("   [\(i)] \(tag.name) (visible: \(tag.isVisible), order: \(tag.order))")
        }
    }
    
    private func persistTags() {
        userDefaultsManager.saveSideEffectTags(tags)
    }
    
    // MARK: - Actions
    
    @objc private func didTapEditButton() {
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

            // 🔍 [디버깅] 새 태그 추가
            print("🔍 [SideEffectManagement] 새 태그 추가: '\(name)'")
            print("   📊 추가 전 tags.count: \(self.tags.count)")

            // visible 태그 개수 확인 (새 태그는 visible 그룹 맨 뒤에 들어가야 함)
            let visibleCount = self.tags.filter { $0.isVisible }.count

            let newTag = SideEffectTag(
                name: name,
                isVisible: true,
                order: visibleCount, // visible 그룹의 맨 뒤 order
                isDefault: false
            )

            // visible 태그들과 hidden 태그들로 분리
            let visibleTags = self.tags.filter { $0.isVisible }
            let hiddenTags = self.tags.filter { !$0.isVisible }

            // 새 태그를 visible 그룹 맨 뒤에 추가
            self.tags = visibleTags + [newTag] + hiddenTags

            // order 재설정
            for i in self.tags.indices {
                self.tags[i].order = i
            }

            print("   📊 추가 후 tags.count: \(self.tags.count)")
            print("   📋 추가 후 tags 순서:")
            for (i, tag) in self.tags.enumerated() {
                print("      [\(i)] \(tag.name) (visible: \(tag.isVisible), order: \(tag.order))")
            }

            self.persistTags()
            self.applySnapshot(animating: true)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}
