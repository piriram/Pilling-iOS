//
//  SideEffectManagementViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/10/25.
//

import UIKit
import SnapKit

// MARK: - SideEffectTag Model

struct SideEffectTag: Codable, Equatable {
    let id: String
    var name: String
    var isVisible: Bool
    var order: Int
    let isDefault: Bool // 기본 제공 태그 여부
    
    init(id: String = UUID().uuidString, name: String, isVisible: Bool = true, order: Int, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.isVisible = isVisible
        self.order = order
        self.isDefault = isDefault
    }
}

// MARK: - SideEffectManagementViewController

final class SideEffectManagementViewController: UIViewController {
    
    // MARK: - Properties
    
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private var visibleTags: [SideEffectTag] = []
    private var hiddenTags: [SideEffectTag] = []
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = AppColor.bg
        table.delegate = self
        table.dataSource = self
        table.dragDelegate = self
        table.dropDelegate = self
        table.dragInteractionEnabled = true
        table.register(SideEffectCell.self, forCellReuseIdentifier: SideEffectCell.identifier)
        table.register(AddSideEffectCell.self, forCellReuseIdentifier: AddSideEffectCell.identifier)
        table.separatorStyle = .singleLine
        return table
    }()
    
    // MARK: - Lifecycle
    
    init(userDefaultsManager: UserDefaultsManagerProtocol) {
        self.userDefaultsManager = userDefaultsManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadSideEffectTags()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveSideEffectTags()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppColor.bg
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func setupNavigationBar() {
        title = "부작용 관리"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    // MARK: - Data Management
    
    private func loadSideEffectTags() {
        let allTags = userDefaultsManager.loadSideEffectTags()
        
        visibleTags = allTags.filter { $0.isVisible }.sorted { $0.order < $1.order }
        hiddenTags = allTags.filter { !$0.isVisible }.sorted { $0.order < $1.order }
        
        tableView.reloadData()
    }
    
    private func saveSideEffectTags() {
        // order 재정렬
        for (index, _) in visibleTags.enumerated() {
            visibleTags[index].order = index
        }
        for (index, _) in hiddenTags.enumerated() {
            hiddenTags[index].order = index
        }
        
        let allTags = visibleTags + hiddenTags
        userDefaultsManager.saveSideEffectTags(allTags)
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        let alert = UIAlertController(
            title: "부작용 추가",
            message: "새로운 부작용을 입력해주세요",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "부작용 이름"
            textField.autocapitalizationType = .none
        }
        
        let addAction = UIAlertAction(title: AppStrings.Common.confirmTitle, style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let textField = alert?.textFields?.first,
                  let name = textField.text?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else { return }
            
            // 중복 체크 (name 기준)
            let allTags = self.visibleTags + self.hiddenTags
            if allTags.contains(where: { $0.name == name }) {
                self.presentNotification(message: "이미 존재하는 부작용입니다")
                return
            }
            
            // 새 태그 추가
            let newTag = SideEffectTag(
                name: name,
                isVisible: true,
                order: self.visibleTags.count,
                isDefault: false
            )
            self.visibleTags.append(newTag)
            
            let indexPath = IndexPath(row: self.visibleTags.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
            // 변경사항 저장
            self.saveSideEffectTags()
        }
        
        let cancelAction = UIAlertAction(title: AppStrings.Common.cancelTitle, style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SideEffectManagementViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return visibleTags.count
        } else {
            return hiddenTags.count + 1 // +1 for "추가" cell
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // "추가" 버튼 셀
        if indexPath.section == 1 && indexPath.row == hiddenTags.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: AddSideEffectCell.identifier, for: indexPath) as! AddSideEffectCell
            cell.configure()
            return cell
        }
        
        // 일반 태그 셀
        let cell = tableView.dequeueReusableCell(withIdentifier: SideEffectCell.identifier, for: indexPath) as! SideEffectCell
        let tag = indexPath.section == 0 ? visibleTags[indexPath.row] : hiddenTags[indexPath.row]
        cell.configure(with: tag)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "표시 중인 부작용" : "숨김 처리된 부작용"
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // "추가" 버튼 셀은 편집 불가
        if indexPath.section == 1 && indexPath.row == hiddenTags.count {
            return false
        }
        
        // 사용자 추가 태그만 삭제 가능
        let tag = indexPath.section == 0 ? visibleTags[indexPath.row] : hiddenTags[indexPath.row]
        return !tag.isDefault
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        if indexPath.section == 0 {
            visibleTags.remove(at: indexPath.row)
        } else {
            hiddenTags.remove(at: indexPath.row)
        }
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
        
        // 변경사항 저장
        saveSideEffectTags()
    }
}

// MARK: - UITableViewDelegate

extension SideEffectManagementViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // "추가" 버튼 셀 클릭
        if indexPath.section == 1 && indexPath.row == hiddenTags.count {
            addButtonTapped()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

// MARK: - UITableViewDragDelegate

extension SideEffectManagementViewController: UITableViewDragDelegate {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // "추가" 버튼 셀은 드래그 불가
        if indexPath.section == 1 && indexPath.row == hiddenTags.count {
            return []
        }
        
        let tag = indexPath.section == 0 ? visibleTags[indexPath.row] : hiddenTags[indexPath.row]
        let itemProvider = NSItemProvider(object: tag.id as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = tag
        
        return [dragItem]
    }
}

// MARK: - UITableViewDropDelegate

extension SideEffectManagementViewController: UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard let indexPath = destinationIndexPath else {
            return UITableViewDropProposal(operation: .cancel)
        }
        
        // "추가" 버튼 셀에는 드롭 불가
        if indexPath.section == 1 && indexPath.row >= hiddenTags.count {
            return UITableViewDropProposal(operation: .cancel)
        }
        
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath,
              let tag = item.dragItem.localObject as? SideEffectTag else { return }
        
        tableView.performBatchUpdates {
            // 원래 위치에서 제거
            if sourceIndexPath.section == 0 {
                visibleTags.remove(at: sourceIndexPath.row)
            } else {
                hiddenTags.remove(at: sourceIndexPath.row)
            }
            
            // 새 위치에 삽입 (isVisible 상태 변경)
            var movedTag = tag
            movedTag.isVisible = (destinationIndexPath.section == 0)
            
            if destinationIndexPath.section == 0 {
                visibleTags.insert(movedTag, at: destinationIndexPath.row)
            } else {
                hiddenTags.insert(movedTag, at: destinationIndexPath.row)
            }
            
            tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
            tableView.insertRows(at: [destinationIndexPath], with: .automatic)
        }
        
        coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
        
        // 변경사항 저장
        saveSideEffectTags()
    }
}

// MARK: - SideEffectCell

final class SideEffectCell: UITableViewCell {
    
    static let identifier = "SideEffectCell"
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body1()
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private let dragIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "line.3.horizontal")
        imageView.tintColor = AppColor.gray400
        imageView.contentMode = .center
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = AppColor.bg
        selectionStyle = .none
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(dragIndicator)
        
        nameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        
        dragIndicator.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }
    }
    
    func configure(with tag: SideEffectTag) {
        nameLabel.text = tag.name
    }
}

// MARK: - AddSideEffectCell

final class AddSideEffectCell: UITableViewCell {
    
    static let identifier = "AddSideEffectCell"
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ 부작용 추가", for: .normal)
        button.setTitleColor(AppColor.pillGreen800, for: .normal)
        button.titleLabel?.font = Typography.body1(.medium)
        button.isUserInteractionEnabled = false // 셀 자체 탭 처리
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = AppColor.bg
        selectionStyle = .default
        
        contentView.addSubview(addButton)
        
        addButton.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }
    
    func configure() {
        // 필요시 설정
    }
}

// MARK: - SwiftUI Preview

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct SideEffectManagementViewController_Preview: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreviewWrapper {
            // Mock UserDefaultsManager for preview
            let mockManager = MockUserDefaultsManager()
            let vc = SideEffectManagementViewController(userDefaultsManager: mockManager)
            let nav = UINavigationController(rootViewController: vc)
            return nav
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// Mock Manager for Preview
class MockUserDefaultsManager: UserDefaultsManagerProtocol {
    func savePillInfo(_ pillInfo: PillInfo) {}
    func savePillStartDate(_ date: Date) {}
    func loadPillInfo() -> PillInfo? { nil }
    func loadPillStartDate() -> Date? { nil }
    func clearPillSettings() {}
    func saveCurrentCycleID(_ id: UUID) {}
    func loadCurrentCycleID() -> UUID? { nil }
    func saveSideEffectTags(_ tags: [SideEffectTag]) {}
    func loadSideEffectTags() -> [SideEffectTag] {
        let defaultTags = [
            "두통", "메스꺼움", "유방통", "기분변화",
            "체중증가", "불규칙출혈", "피로", "불면증",
            "여드름", "성욕감소", "복통", "어지러움"
        ]
        
        var tags = defaultTags.enumerated().map { index, name in
            SideEffectTag(name: name, isVisible: true, order: index, isDefault: true)
        }
        
        tags.append(SideEffectTag(name: "다리부종", isVisible: true, order: tags.count, isDefault: false))
        
        tags.append(SideEffectTag(name: "식욕증가", isVisible: false, order: 0, isDefault: true))
        tags.append(SideEffectTag(name: "집중력저하", isVisible: false, order: 1, isDefault: false))
        
        return tags
    }
}

@available(iOS 13.0, *)
struct UIViewControllerPreviewWrapper<T: UIViewController>: UIViewControllerRepresentable {
    let viewControllerBuilder: () -> T
    
    init(_ viewControllerBuilder: @escaping () -> T) {
        self.viewControllerBuilder = viewControllerBuilder
    }
    
    func makeUIViewController(context: Context) -> T {
        return viewControllerBuilder()
    }
    
    func updateUIViewController(_ uiViewController: T, context: Context) {
        // No update needed
    }
}
#endif
