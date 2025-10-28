//
//  DashboardCalendarView.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/28/25.
//

import UIKit
import SnapKit

final class DashboardCalendarView: UIView {
    
    // MARK: - Properties
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, DayItem>!
    var onCellSelected: ((Int, DayItem) -> Void)?
    
    // MARK: - UI Components
    
    private let weekdayStackView = UIStackView()
    
    private lazy var collectionView: UICollectionView = {
        let layout = makeCompositionalLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.contentInset = .zero
        cv.isScrollEnabled = false
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        cv.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        cv.delegate = self
        return cv
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        configureDiffableDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        setupWeekdayStackView()
        
        addSubview(weekdayStackView)
        addSubview(collectionView)
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
    
    private func setupConstraints() {
        weekdayStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayStackView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Diffable DataSource
    
    private func configureDiffableDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, DayItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CalendarCell.identifier,
                for: indexPath
            ) as? CalendarCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(with: item)
            return cell
        }
    }
    
    // MARK: - Public Methods
    
    func applySnapshot(with items: [DayItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DayItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func updateWeekdayStart(from startDate: Date) {
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
    
    func updateLayout() {
        collectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
        layoutIfNeeded()
    }
    
    // MARK: - Layout
    
    private func calculateOptimalLayout() -> (cellSize: CGFloat, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        let availableWidth = bounds.width
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - UICollectionViewDelegate

extension DashboardCalendarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if case .scheduled = item.status { return }
        if case .rest = item.status { return }
        
        let calendar = Calendar.current
        let isToday = calendar.isDate(item.date, inSameDayAs: Date())
        
        if !isToday || item.status.isTaken {
            onCellSelected?(indexPath.item, item)
        }
    }
}
