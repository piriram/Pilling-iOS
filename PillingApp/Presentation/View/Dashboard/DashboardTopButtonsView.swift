//
//  DashboardTopButtonsView.swift
//  PillingApp
//
//  Created by Claude on 11/11/25.
//

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
        print("🔵 DashboardTopButtonsView init START")
        
        self.historyButtonTapped = historyButton.rx.tap.asObservable()
        self.infoButtonTapped = infoButton.rx.tap.asObservable()
        self.gearButtonTapped = gearButton.rx.tap.asObservable()
        
        print("🔵 Observables created")
        
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        
        print("🔵 DashboardTopButtonsView init END")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .clear
        
        print("🔵 setupViews START")
        
        // Info button
        infoButton.setImage(DashboardUI.Icon.info, for: .normal)
        infoButton.tintColor = AppColor.secondary
        infoButton.isUserInteractionEnabled = true
        infoButton.addTarget(self, action: #selector(infoButtonDebugTap), for: .touchUpInside)
        print("🔵 Info button setup - isUserInteractionEnabled: \(infoButton.isUserInteractionEnabled)")
        
        // History button
        historyButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        historyButton.tintColor = AppColor.secondary
        historyButton.isUserInteractionEnabled = true
        historyButton.addTarget(self, action: #selector(historyButtonDebugTap), for: .touchUpInside)
        print("🔵 History button setup - isUserInteractionEnabled: \(historyButton.isUserInteractionEnabled)")
        
        // Gear button
        gearButton.setImage(DashboardUI.Icon.gear, for: .normal)
        gearButton.tintColor = AppColor.secondary
        gearButton.isUserInteractionEnabled = true
        gearButton.addTarget(self, action: #selector(gearButtonDebugTap), for: .touchUpInside)
        print("🔵 Gear button setup - isUserInteractionEnabled: \(gearButton.isUserInteractionEnabled)")
        
        addSubview(historyButton)
        addSubview(infoButton)
        addSubview(gearButton)
        
        isUserInteractionEnabled = true
        print("🔵 Container view isUserInteractionEnabled: \(isUserInteractionEnabled)")
        print("🔵 setupViews END")
    }
    
    // MARK: - Debug Methods
    
    @objc private func historyButtonDebugTap() {
        print("🟢 HISTORY BUTTON TAPPED (Target-Action)")
    }
    
    @objc private func infoButtonDebugTap() {
        print("🟢 INFO BUTTON TAPPED (Target-Action)")
    }
    
    @objc private func gearButtonDebugTap() {
        print("🟢 GEAR BUTTON TAPPED (Target-Action)")
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
        
        print("🔵 Constraints setup complete")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("🔵 layoutSubviews - topButtonsView frame: \(frame)")
        print("🔵   historyButton frame: \(historyButton.frame), isHidden: \(historyButton.isHidden)")
        print("🔵   infoButton frame: \(infoButton.frame), isHidden: \(infoButton.isHidden)")
        print("🔵   gearButton frame: \(gearButton.frame), isHidden: \(gearButton.isHidden)")
        print("🔵   topButtonsView alpha: \(alpha), isHidden: \(isHidden)")
        
        // Check if there's a view covering the buttons
        if let superview = superview {
            print("🔵   Superview: \(type(of: superview))")
            print("🔵   Superview subviews count: \(superview.subviews.count)")
            if let index = superview.subviews.firstIndex(of: self) {
                print("🔵   This view is at index: \(index) of \(superview.subviews.count)")
                print("🔵   Views above this (blocking touches):")
                for i in (index + 1)..<superview.subviews.count {
                    let view = superview.subviews[i]
                    print("🔵     [\(i)] \(type(of: view)) - frame: \(view.frame), isHidden: \(view.isHidden), alpha: \(view.alpha)")
                }
            }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        print("🔵 hitTest called at point: \(point)")
        print("🔵   Returned view: \(hitView != nil ? String(describing: type(of: hitView!)) : "nil")")
        
        // Check each button individually
        let historyPoint = convert(point, to: historyButton)
        let infoPoint = convert(point, to: infoButton)
        let gearPoint = convert(point, to: gearButton)
        
        print("🔵   historyButton contains point: \(historyButton.bounds.contains(historyPoint))")
        print("🔵   infoButton contains point: \(infoButton.bounds.contains(infoPoint))")
        print("🔵   gearButton contains point: \(gearButton.bounds.contains(gearPoint))")
        
        return hitView
    }
}
