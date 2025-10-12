//
//  DatePickerBottomSheetViewController.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - DatePickerBottomSheetViewController

final class DatePickerBottomSheetViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    private let tapDelegate = PassThroughTapGestureDelegate()
    private let disposeBag = DisposeBag()
    private let selectedDateSubject = PublishSubject<Date>()
    
    var selectedDate: Observable<Date> {
        return selectedDateSubject.asObservable()
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "복용 시작 날짜"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.locale = Locale(identifier: "ko_KR")
        picker.calendar = Calendar(identifier: .gregorian)
        
        // 현재 날짜 기준 ±28일 범위 설정
        let currentDate = Date()
        let calendar = Calendar.current
        picker.minimumDate = calendar.date(byAdding: .day, value: -28, to: currentDate)
        picker.maximumDate = calendar.date(byAdding: .day, value: 28, to: currentDate)
        picker.date = currentDate
        
        return picker
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "날짜를 선택하면 자동으로 저장됩니다"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupGestures()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatePresentation()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        
        view.addSubview(containerView)
        containerView.addSubview(handleBar)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(datePicker)
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(480)
        }
        
        handleBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(handleBar.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        datePicker.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        tapDelegate.containerView = containerView
        tapGesture.delegate = self
        
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] recognizer in
                let location = recognizer.location(in: self?.view)
                if let containerView = self?.containerView,
                   !containerView.frame.contains(location) {
                    self?.dismissBottomSheet()
                }
            })
            .disposed(by: disposeBag)
        
        let panGesture = UIPanGestureRecognizer()
        panGesture.delegate = self
        containerView.addGestureRecognizer(panGesture)
        
        panGesture.rx.event
            .subscribe(onNext: { [weak self] recognizer in
                self?.handlePanGesture(recognizer)
            })
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        // 날짜 선택 시 자동으로 시트 닫기
        datePicker.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.selectedDateSubject.onNext(self.datePicker.date)
                // 약간의 딜레이 후 시트 닫기 (사용자가 선택을 인지할 수 있도록)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.dismissBottomSheet()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Animation
    
    private func animatePresentation() {
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height)
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.containerView.transform = .identity
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        }
    }
    
    private func dismissBottomSheet() {
        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.containerView.transform = CGAffineTransform(
                    translationX: 0,
                    y: self.containerView.frame.height
                )
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            },
            completion: { _ in
                self.dismiss(animated: false)
            }
        )
    }
    
    // MARK: - Gesture Handling
    
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            if translation.y > 100 || velocity.y > 500 {
                dismissBottomSheet()
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }
}

// MARK: - Gesture Delegate

private final class PassThroughTapGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var containerView: UIView?
}

extension DatePickerBottomSheetViewController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // If the touch is inside the containerView, don't let the background tap recognizer receive it.
        if gestureRecognizer is UITapGestureRecognizer {
            if let superview = containerView.superview {
                let point = touch.location(in: superview)
                if containerView.frame.contains(point) { return false }
            }
        }
        // If the touch is inside the datePicker, don't let the pan recognizer start.
        if gestureRecognizer is UIPanGestureRecognizer {
            if let view = touch.view, view.isDescendant(of: datePicker) {
                return false
            }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow datePicker's internal gestures to work alongside others when appropriate.
        if (gestureRecognizer is UIPanGestureRecognizer || otherGestureRecognizer is UIPanGestureRecognizer) {
            if let v1 = gestureRecognizer.view, v1.isDescendant(of: datePicker) { return true }
            if let v2 = otherGestureRecognizer.view, v2.isDescendant(of: datePicker) { return true }
        }
        return false
    }
}

