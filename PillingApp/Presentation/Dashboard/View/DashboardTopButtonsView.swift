import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class DashboardTopButtonsView: UIView {
    
    // MARK: - UI Components
    
    private let historyButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let gearButton = UIButton(type: .system)
    
    // MARK: - Observables
    
    let historyButtonTapped: Observable<Void>
    let infoButtonTapped: Observable<Void>
    let gearButtonTapped: Observable<Void>
    
    // MARK: - Properties
    
    var isHistoryButtonHidden: Bool = false {
        didSet {
            historyButton.isHidden = isHistoryButtonHidden
            historyButton.isEnabled = !isHistoryButtonHidden
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        self.historyButtonTapped = historyButton.rx.tap.asObservable()
        self.infoButtonTapped = infoButton.rx.tap.asObservable()
        self.gearButtonTapped = gearButton.rx.tap.asObservable()
        
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .clear
        
        // Info button
        infoButton.setImage(DashboardUI.Icon.info, for: .normal)
        infoButton.tintColor = AppColor.secondary
        infoButton.isUserInteractionEnabled = true
        infoButton.addTarget(self, action: #selector(infoButtonDebugTap), for: .touchUpInside)
        
        // History button
        historyButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        historyButton.tintColor = AppColor.secondary
        historyButton.isUserInteractionEnabled = true
        historyButton.addTarget(self, action: #selector(historyButtonDebugTap), for: .touchUpInside)
        
        // Gear button
        gearButton.setImage(DashboardUI.Icon.gear, for: .normal)
        gearButton.tintColor = AppColor.secondary
        gearButton.isUserInteractionEnabled = true
        gearButton.addTarget(self, action: #selector(gearButtonDebugTap), for: .touchUpInside)
        
        addSubview(historyButton)
        addSubview(infoButton)
        addSubview(gearButton)
        
        isUserInteractionEnabled = true
    }
    
    // MARK: - Debug Methods
    
    @objc private func historyButtonDebugTap() {
    }
    
    @objc private func infoButtonDebugTap() {
    }
    
    @objc private func gearButtonDebugTap() {
    }
    
    private func setupConstraints() {
        gearButton.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        infoButton.snp.makeConstraints { make in
            make.centerY.equalTo(gearButton)
            make.trailing.equalTo(gearButton.snp.leading).offset(-8)
            make.width.height.equalTo(30)
        }
        
        historyButton.snp.makeConstraints { make in
            make.centerY.equalTo(gearButton)
            make.trailing.equalTo(infoButton.snp.leading).offset(-8)
            make.width.height.equalTo(30)
            make.leading.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Check if there's a view covering the buttons
        if let superview = superview {
            if let index = superview.subviews.firstIndex(of: self) {
                for i in (index + 1)..<superview.subviews.count {
                    let _ = superview.subviews[i]
                }
            }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        let historyPoint = convert(point, to: historyButton)
        let infoPoint = convert(point, to: infoButton)
        let gearPoint = convert(point, to: gearButton)
        
        return hitView
    }
}

