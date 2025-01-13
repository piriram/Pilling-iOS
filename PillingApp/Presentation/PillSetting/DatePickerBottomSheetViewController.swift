import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class DatePickerBottomSheetViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: DatePickerBottomSheetViewModel
    private let configuration: DatePickerConfiguration.DateRange
    private let disposeBag = DisposeBag()
    
    var selectedDate: Signal<Date> {
        return viewModel.output.selectedDate
    }
    
    var selectedDateObserver: AnyObserver<Date> {
        return viewModel.input.dateChanged
    }
    
    // MARK: - UI Components
    
    private let dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = DatePickerConfiguration.Colors.containerBackground
        view.layer.cornerRadius = DatePickerConfiguration.Metrics.cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = DatePickerConfiguration.Metrics.shadowOpacity
        view.layer.shadowOffset = DatePickerConfiguration.Metrics.shadowOffset
        view.layer.shadowRadius = DatePickerConfiguration.Metrics.shadowRadius
        return view
    }()
    
    private let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = DatePickerConfiguration.Colors.handleBar
        view.layer.cornerRadius = DatePickerConfiguration.Metrics.handleBarHeight / 2
        return view
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.locale = Locale.current
        picker.calendar = Calendar.current
        picker.timeZone = TimeZone.current
        picker.tintColor = DatePickerConfiguration.Colors.pickerTint
        picker.minimumDate = configuration.minimumDate
        picker.maximumDate = configuration.maximumDate
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        picker.date = today
        
        return picker
    }()
    
    // MARK: - Initialization
    
    init(
        configuration: DatePickerConfiguration.DateRange = .defaultRange,
        viewModel: DatePickerBottomSheetViewModel? = nil
    ) {
        self.configuration = configuration
        self.viewModel = viewModel ?? DatePickerBottomSheetViewModel(
            initialDate: Date(),
            dateRange: configuration
        )
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
        containerView.addSubview(datePicker)
    }
    
    private func setupConstraints() {
        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(DatePickerConfiguration.Metrics.containerHeight)
        }
        
        handleBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(DatePickerConfiguration.Metrics.handleBarTopOffset)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(DatePickerConfiguration.Metrics.handleBarWidth)
            $0.height.equalTo(DatePickerConfiguration.Metrics.handleBarHeight)
        }
        
        datePicker.snp.makeConstraints {
            $0.top.equalTo(handleBar.snp.bottom).offset(DatePickerConfiguration.Metrics.pickerTopOffset)
            $0.leading.trailing.equalToSuperview().inset(DatePickerConfiguration.Metrics.horizontalInset)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-DatePickerConfiguration.Metrics.bottomInset)
        }
    }
    
    private func setupGestures() {
        let dimmedTapGesture = UITapGestureRecognizer()
        dimmedView.addGestureRecognizer(dimmedTapGesture)
        
        dimmedTapGesture.rx.event
            .map { _ in () }
            .bind(to: viewModel.input.dismissRequested)
            .disposed(by: disposeBag)
        
        let panGesture = UIPanGestureRecognizer()
        containerView.addGestureRecognizer(panGesture)
        
        panGesture.rx.event
            .subscribe(onNext: { [weak self] recognizer in
                self?.handlePanGesture(recognizer)
            })
            .disposed(by: disposeBag)
        
        let datePickerTapGesture = UITapGestureRecognizer()
        datePickerTapGesture.cancelsTouchesInView = false
        datePicker.addGestureRecognizer(datePickerTapGesture)
        
        datePickerTapGesture.rx.event
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] gesture in
                self?.handleDatePickerTap(gesture)
            })
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        datePicker.rx.controlEvent(.valueChanged)
            .debounce(
                .milliseconds(DatePickerConfiguration.Animation.debounceMilliseconds),
                scheduler: MainScheduler.instance
            )
            .map { [weak self] in self?.datePicker.date ?? Date() }
            .bind(to: viewModel.input.dateChanged)
            .disposed(by: disposeBag)
        
        viewModel.output.selectedDate
            .emit(onNext: { [weak self] _ in
                self?.triggerHapticFeedback()
                self?.scheduleDismiss()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.shouldDismiss
            .emit(onNext: { [weak self] in
                self?.dismissBottomSheet()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func scheduleDismiss() {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + DatePickerConfiguration.Animation.dismissDelay
        ) { [weak self] in
            self?.dismissBottomSheet()
        }
    }
    
    // MARK: - Animation
    
    private func animatePresentation() {
        containerView.transform = CGAffineTransform(
            translationX: 0,
            y: containerView.frame.height
        )
        
        UIView.animate(
            withDuration: DatePickerConfiguration.Animation.presentationDuration,
            delay: 0,
            usingSpringWithDamping: DatePickerConfiguration.Animation.springDamping,
            initialSpringVelocity: DatePickerConfiguration.Animation.springVelocity,
            options: .curveEaseOut
        ) {
            self.containerView.transform = .identity
            self.dimmedView.backgroundColor = DatePickerConfiguration.Colors.dimmedBackground
        }
    }
    
    private func dismissBottomSheet() {
        UIView.animate(
            withDuration: DatePickerConfiguration.Animation.dismissalDuration,
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

    private func isDateCellButton(_ view: UIView) -> Bool {
        let viewClassName = String(describing: type(of: view))
        return viewClassName.contains("Button") &&
               !viewClassName.contains("Month") &&
               !viewClassName.contains("Year")
    }
    
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            handlePanChanged(translation: translation)
            
        case .ended:
            handlePanEnded(translation: translation, velocity: velocity)
            
        default:
            break
        }
    }
    
    private func handlePanChanged(translation: CGPoint) {
        if translation.y > 0 {
            containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        }
    }
    
    private func handlePanEnded(translation: CGPoint, velocity: CGPoint) {
        if translation.y > DatePickerConfiguration.Gesture.dismissThreshold ||
           velocity.y > DatePickerConfiguration.Gesture.dismissVelocity {
            dismissBottomSheet()
        } else {
            UIView.animate(
                withDuration: DatePickerConfiguration.Gesture.panSpringDuration,
                delay: 0,
                usingSpringWithDamping: DatePickerConfiguration.Gesture.panSpringDamping,
                initialSpringVelocity: DatePickerConfiguration.Gesture.panSpringVelocity,
                options: .curveEaseOut
            ) {
                self.containerView.transform = .identity
            }
        }
    }
    
    private func handleDatePickerTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: datePicker)
        
        // datePicker 내부의 뷰 계층을 탐색하여 날짜 셀이 탭되었는지 확인
        guard let tappedView = datePicker.hitTest(location, with: nil) else { return }
        
        // 월 변경 버튼(UIButton) 제외 - 날짜 셀만 선택으로 처리
        let viewDescription = String(describing: type(of: tappedView))
        if viewDescription.contains("Button") {
            return
        }
        
        // 날짜가 선택되었을 때만 dismiss
        viewModel.input.dateChanged.onNext(datePicker.date)
    }
}
