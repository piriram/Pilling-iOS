//
//  ChartContainerView.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/6/25.
//

import UIKit
import SnapKit
import DGCharts

// MARK: - Chart Layout Constants
private enum ChartLayoutConstants {
    // 공통 상수
    static let holeRadius: CGFloat = 0.72
    static let transparentCircleRadius: CGFloat = 0.72
    static let verticalInset: CGFloat = 10
    
    // 중앙 콘텐츠
    static let centerIconSize: CGFloat = 60
    static let centerIconCornerRadius: CGFloat = 20
    static let centerStackSpacing: CGFloat = 4
    
    // DonutChartView 전용 상수
    enum Data {
        static let sliceSpace: CGFloat = 2
        static let selectionShift: CGFloat = 5
        static let centerTitleFontSize: CGFloat = 16
        static let centerPercentageFontSize: CGFloat = 32
        static let animationDuration: Double = 0.8
    }
    
    // Empty 상태 전용 상수
    enum Empty {
        static let closeIconSize: CGFloat = 24
        static let closeIconOffset: CGFloat = 8
    }
    
    // Arrow 버튼
    enum ArrowButton {
        static let horizontalInset: CGFloat = 40
        static let width: CGFloat = 18
        static let height: CGFloat = 30
    }
}

// MARK: - ChartContainerView
final class ChartContainerView: UIView {
    
    private let donutChartView = DonutChartView()
    
    let leftArrowButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = AppColor.secondary
        return button
    }()
    
    let rightArrowButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = AppColor.secondary
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(donutChartView)
        addSubview(leftArrowButton)
        addSubview(rightArrowButton)
        
        donutChartView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(ChartLayoutConstants.verticalInset)
        }
        
        leftArrowButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(ChartLayoutConstants.ArrowButton.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(ChartLayoutConstants.ArrowButton.width)
            make.height.equalTo(ChartLayoutConstants.ArrowButton.height)
        }
        
        rightArrowButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(ChartLayoutConstants.ArrowButton.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(ChartLayoutConstants.ArrowButton.width)
            make.height.equalTo(ChartLayoutConstants.ArrowButton.height)
        }
    }
    
    func configure(with data: PeriodRecordDTO) {
        donutChartView.configure(
            records: data.records,
            completionRate: data.completionRate,
            isEmpty: data.isEmpty
        )
    }
    
    func updateArrowButtons(isLeftEnabled: Bool, isRightEnabled: Bool) {
        leftArrowButton.isEnabled = isLeftEnabled
        leftArrowButton.tintColor = isLeftEnabled ? AppColor.secondary : AppColor.notYetGray
        
        rightArrowButton.isEnabled = isRightEnabled
        rightArrowButton.tintColor = isRightEnabled ? AppColor.secondary : AppColor.notYetGray
    }
}

// MARK: - DonutChartView
private final class DonutChartView: UIView {
    
    private let pieChartView: PieChartView = {
        let chartView = PieChartView()
        chartView.usePercentValuesEnabled = true
        chartView.drawSlicesUnderHoleEnabled = false
        chartView.holeRadiusPercent = ChartLayoutConstants.holeRadius
        chartView.transparentCircleRadiusPercent = ChartLayoutConstants.transparentCircleRadius
        chartView.chartDescription.enabled = false
        chartView.setExtraOffsets(left: 5, top: 10, right: 5, bottom: 5)
        chartView.drawCenterTextEnabled = true
        chartView.drawHoleEnabled = true
        chartView.rotationAngle = 0
        chartView.rotationEnabled = true
        chartView.highlightPerTapEnabled = true
        chartView.legend.enabled = false
        return chartView
    }()
    
    // Data 상태용 중앙 콘텐츠
    private let centerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = ChartLayoutConstants.centerStackSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()
    
    private let centerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "필링타임"
        label.font = .systemFont(
            ofSize: ChartLayoutConstants.Data.centerTitleFontSize,
            weight: .semibold
        )
        label.textColor = AppColor.gray800
        return label
    }()
    
    private let centerPercentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(
            ofSize: ChartLayoutConstants.Data.centerPercentageFontSize,
            weight: .bold
        )
        label.textColor = AppColor.green800
        return label
    }()
    
    // Empty 상태용 중앙 콘텐츠
    private let medicineIconView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = ChartLayoutConstants.centerIconCornerRadius
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let medicineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "medicine")
        imageView.tintColor = UIColor(white: 0.85, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private let closeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "xmark.circle")
        imageView.tintColor = AppColor.gray300
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(pieChartView)
        addSubview(centerStackView)
        addSubview(medicineIconView)
        medicineIconView.addSubview(medicineImageView)
        addSubview(closeImageView)
        
        centerStackView.addArrangedSubview(centerTitleLabel)
        centerStackView.addArrangedSubview(centerPercentageLabel)
        
        pieChartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        centerStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        medicineIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ChartLayoutConstants.centerIconSize)
        }
        
        medicineImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ChartLayoutConstants.centerIconSize)
        }
        
        closeImageView.snp.makeConstraints { make in
            make.trailing.equalTo(medicineIconView.snp.trailing)
                .offset(ChartLayoutConstants.Empty.closeIconOffset)
            make.bottom.equalTo(medicineIconView.snp.bottom)
                .offset(ChartLayoutConstants.Empty.closeIconOffset)
            make.width.height.equalTo(ChartLayoutConstants.Empty.closeIconSize)
        }
    }
    
    func configure(records: [RecordItemDTO], completionRate: Int, isEmpty: Bool) {
        if isEmpty {
            showEmptyState()
        } else {
            showDataState(records: records, completionRate: completionRate)
        }
    }
    
    private func showEmptyState() {
        centerStackView.isHidden = true
        medicineIconView.isHidden = false
        closeImageView.isHidden = false
        
        let entry = PieChartDataEntry(value: 1)
        let set = PieChartDataSet(entries: [entry], label: "")
        
        let ringColor: UIColor = AppColor.gray300
        set.colors = [ringColor]
        set.sliceSpace = 0
        set.selectionShift = 0
        set.drawValuesEnabled = false
        
        let data = PieChartData(dataSet: set)
        pieChartView.data = data
    }
    
    private func showDataState(records: [RecordItemDTO], completionRate: Int) {
        centerStackView.isHidden = false
        medicineIconView.isHidden = true
        closeImageView.isHidden = true
        
        centerPercentageLabel.text = "\(completionRate)%"
        updateChart(with: records)
    }
    
    private func updateChart(with records: [RecordItemDTO]) {
        var entries: [PieChartDataEntry] = []
        var colors: [UIColor] = []
        
        for item in records {
            let entry = PieChartDataEntry(value: Double(item.percentage))
            entries.append(entry)
            if let color = UIColor(hex: item.colorHex) {
                colors.append(color)
            }
        }
        
        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = colors
        dataSet.sliceSpace = ChartLayoutConstants.Data.sliceSpace
        dataSet.selectionShift = ChartLayoutConstants.Data.selectionShift
        dataSet.drawValuesEnabled = false
        
        let data = PieChartData(dataSet: dataSet)
        pieChartView.data = data
        
        pieChartView.animate(
            xAxisDuration: ChartLayoutConstants.Data.animationDuration,
            yAxisDuration: ChartLayoutConstants.Data.animationDuration,
            easingOption: .easeOutBack
        )
    }
}
