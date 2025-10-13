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

final class DatePickerBottomSheetViewController: UIViewController {
    
    // MARK: - Properties
    
    private let disposeBag = DisposeBag()
    private let selectedDateSubject = PublishSubject<Date>()
    
    var selectedDate: Observable<Date> {
        return selectedDateSubject.asObservable()
    }
    
    // MARK: - UI Components
    
    private let dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 10
        return view
    }()
    
    private let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "날짜를 선택하면 자동으로 저장됩니다"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.locale = Locale(identifier: "ko_KR")
        picker.calendar = Calendar(identifier: .gregorian)
        picker.tintColor = AppColor.pillGreen200
        
        // 현재 날짜 기준 ±28일 범위 설정
        let currentDate = Date()
        let calendar = Calendar.current
        picker.minimumDate = calendar.date(byAdding: .day, value: -28, to: currentDate)
        picker.maximumDate = calendar.date(byAdding: .day, value: 28, to: currentDate)
        picker.date = currentDate
        
        return picker
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
        view.backgroundColor = .clear
        
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        
        containerView.addSubview(handleBar)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(datePicker)
    }
    
    private func setupConstraints() {
        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(500)
        }
        
        handleBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(handleBar.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        datePicker.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }
    
    private func setupGestures() {
        // Dimmed view tap gesture
        let tapGesture = UITapGestureRecognizer()
        dimmedView.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.dismissBottomSheet()
            })
            .disposed(by: disposeBag)
        
        // Container pan gesture
        let panGesture = UIPanGestureRecognizer()
        containerView.addGestureRecognizer(panGesture)
        
        panGesture.rx.event
            .subscribe(onNext: { [weak self] recognizer in
                self?.handlePanGesture(recognizer)
            })
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        datePicker.rx.controlEvent(.valueChanged)
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.selectedDateSubject.onNext(self.datePicker.date)
                
                // 햅틱 피드백
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // 딜레이 후 시트 닫기
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
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.containerView.transform = .identity
            self.dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        }
    }
    
    private func dismissBottomSheet() {
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.containerView.transform = CGAffineTransform(
                    translationX: 0,
                    y: self.containerView.frame.height
                )
                self.dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0)
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
            if translation.y > 100 || velocity.y > 800 {
                dismissBottomSheet()
            } else {
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.5,
                    options: .curveEaseOut
                ) {
                    self.containerView.transform = .identity
                }
            }
            
        default:
            break
        }
    }
}

