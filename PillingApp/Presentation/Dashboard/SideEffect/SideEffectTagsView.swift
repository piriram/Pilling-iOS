//
//  SideEffectTagsView.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - CenterAlignedCollectionViewFlowLayout

final class CenterAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var rows: [[UICollectionViewLayoutAttributes]] = []
        var currentRowY: CGFloat = -1

        for attribute in attributes {
            if currentRowY != attribute.frame.origin.y {
                currentRowY = attribute.frame.origin.y
                rows.append([])
            }
            rows[rows.count - 1].append(attribute)
        }

        for row in rows {
            guard let collectionView = collectionView else { continue }

            let totalWidth = row.reduce(0) { $0 + $1.frame.width }
            let totalSpacing = CGFloat(row.count - 1) * minimumInteritemSpacing
            let totalContentWidth = totalWidth + totalSpacing

            let inset = (collectionView.bounds.width - totalContentWidth) / 2
            var currentX = max(sectionInset.left, inset)

            for attribute in row {
                var frame = attribute.frame
                frame.origin.x = currentX
                attribute.frame = frame
                currentX += frame.width + minimumInteritemSpacing
            }
        }

        return attributes
    }
}

final class SideEffectTagsView: UIView {

    // MARK: - Properties

    private let userDefaultsManager: UserDefaultsManagerProtocol
    private var sideEffectTags: [SideEffectTag] = []
    private var selectedTagIds: Set<String> = []
    private var collectionViewHeightConstraint: Constraint?

    // MARK: - Observables

    let addButtonTapped = PublishRelay<Void>()
    
    // MARK: - UI Components
    
    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 컨디션"
        label.font = Typography.body1(.semibold)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createCollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SideEffectTagCell.self, forCellWithReuseIdentifier: SideEffectTagCell.identifier)
        collectionView.register(SideEffectAddButtonCell.self, forCellWithReuseIdentifier: SideEffectAddButtonCell.identifier)
        return collectionView
    }()
    
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    // MARK: - Initialization
    
    init(userDefaultsManager: UserDefaultsManagerProtocol) {
        self.userDefaultsManager = userDefaultsManager
        super.init(frame: .zero)
        setupViews()
        loadSideEffectTags()
        collectionView.reloadData()

        // 초기 높이 설정을 다음 runloop로 지연 (레이아웃 계산 완료 대기)
        DispatchQueue.main.async { [weak self] in
            self?.updateCollectionViewHeight()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        addSubview(containerStack)

        containerStack.addArrangedSubview(sectionLabel)
        containerStack.addArrangedSubview(collectionView)

        containerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // CollectionView 초기 높이 설정 (최소 높이)
        collectionView.snp.makeConstraints { make in
            collectionViewHeightConstraint = make.height.equalTo(44).constraint
        }
    }
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let layout = CenterAlignedCollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return layout
    }
    
    // MARK: - Public Methods

    func reloadTags() {
        print("🔍 [SideEffectTagsView] reloadTags() 호출")
        print("   📊 reload 전 sideEffectTags.count: \(sideEffectTags.count)")

        loadSideEffectTags()

        print("   📊 reload 후 sideEffectTags.count: \(sideEffectTags.count)")
        for (i, tag) in sideEffectTags.enumerated() {
            print("      [\(i)] \(tag.name) - visible: \(tag.isVisible), order: \(tag.order)")
        }

        collectionView.reloadData()
        updateCollectionViewHeight()
        print("   ✅ reloadTags 완료")
    }

    func getSelectedTagIds() -> [String] {
        return Array(selectedTagIds)
    }

    func setSelectedTagIds(_ ids: [String]) {
        selectedTagIds = Set(ids)
        collectionView.reloadData()
        updateCollectionViewHeight()
    }

    func clearSelection() {
        selectedTagIds.removeAll()
        collectionView.reloadData()
        updateCollectionViewHeight()
    }
    
    // MARK: - Private Methods
    
    private func loadSideEffectTags() {
        print("🔍 [SideEffectTagsView] loadSideEffectTags() 호출")

        let allTags = userDefaultsManager.loadSideEffectTags()
        print("   📦 userDefaultsManager에서 받은 태그: \(allTags.count)개")
        for (i, tag) in allTags.enumerated() {
            print("      [\(i)] \(tag.name) - visible: \(tag.isVisible), order: \(tag.order)")
        }

        sideEffectTags = allTags.filter { $0.isVisible }.sorted { $0.order < $1.order }
        print("   🔍 visible만 필터링: \(sideEffectTags.count)개")
        for (i, tag) in sideEffectTags.enumerated() {
            print("      [\(i)] \(tag.name) - visible: \(tag.isVisible), order: \(tag.order)")
        }
    }

    private func updateCollectionViewHeight() {
        // CollectionView의 layout을 강제로 업데이트하여 contentSize 계산
        collectionView.layoutIfNeeded()

        // contentSize를 기반으로 높이 계산
        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        let finalHeight = max(contentHeight, 44) // 최소 높이 44

        // Constraint 업데이트
        collectionViewHeightConstraint?.update(offset: finalHeight)

        // 부모 뷰에게 레이아웃 업데이트 알림
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - UICollectionViewDataSource

extension SideEffectTagsView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sideEffectTags.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == sideEffectTags.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SideEffectAddButtonCell.identifier, for: indexPath) as! SideEffectAddButtonCell
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SideEffectTagCell.identifier, for: indexPath) as! SideEffectTagCell
        let tag = sideEffectTags[indexPath.item]
        let isSelected = selectedTagIds.contains(tag.id)

        cell.configure(with: tag.name, isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SideEffectTagsView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == sideEffectTags.count {
            addButtonTapped.accept(())
            return
        }

        let tag = sideEffectTags[indexPath.item]
        if selectedTagIds.contains(tag.id) {
            selectedTagIds.remove(tag.id)
        } else {
            selectedTagIds.insert(tag.id)
        }

        collectionView.reloadItems(at: [indexPath])
        // 태그 선택 시 높이 변화는 없지만, 안정성을 위해 호출
        DispatchQueue.main.async { [weak self] in
            self?.updateCollectionViewHeight()
        }
    }
}
