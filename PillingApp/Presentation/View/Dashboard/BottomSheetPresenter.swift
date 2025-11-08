//
//  BottomSheetPresenter.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/7/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

/// 바텀시트 표시/숨김 애니메이션과 팬/딤드 제스처를 전담하는 헬퍼
/// - attach(...) 호출로 제약을 설치하고 제스처 연결
/// - show()/hide()로 애니메이션 제어
/// - requestDismiss 시그널로 VC에 닫기 요청 알림
final class BottomSheetPresenter {

    // MARK: Output

    /// 팬 제스처/딤드 탭에 의해 닫기 요청이 발생했을 때 방출
    var requestDismiss: Signal<Void> { requestDismissRelay.asSignal() }

    // MARK: Private

    private weak var rootView: UIView?
    private weak var sheetView: UIView?
    private weak var dimmedView: UIView?

    private var topConstraint: Constraint?
    private var sheetHeight: CGFloat = 0

    private let disposeBag = DisposeBag()
    private let requestDismissRelay = PublishRelay<Void>()

    // Dismiss 임계값
    private let dismissProgressThreshold: CGFloat = 1.0/3.0
    private let dismissVelocityThreshold: CGFloat = 1000

    // MARK: Attach

    /// rootView에 sheetView, dimmedView를 연결하고 제약/제스처를 구성한다.
    func attach(to rootView: UIView, sheetView: UIView, dimmedView: UIView, height: CGFloat) {
        self.rootView = rootView
        self.sheetView = sheetView
        self.dimmedView = dimmedView
        self.sheetHeight = height

        // 초기 위치: 화면 아래
        sheetView.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(rootView)
            make.height.equalTo(height)
            self.topConstraint = make.top.equalTo(rootView.snp.bottom).constraint
        }

        // Dimmed 탭 → 닫기 요청
        let dimmedTap = UITapGestureRecognizer()
        dimmedView.addGestureRecognizer(dimmedTap)
        dimmedTap.rx.event
            .map { _ in () }
            .bind(to: requestDismissRelay)
            .disposed(by: disposeBag)

        // 팬 제스처
        let pan = UIPanGestureRecognizer()
        sheetView.addGestureRecognizer(pan)

        pan.rx.event
            .bind(onNext: { [weak self] gesture in
                self?.handlePan(gesture)
            })
            .disposed(by: disposeBag)
    }

    // MARK: Show/Hide

    func show() {
        guard let rootView, let dimmedView else { return }
        topConstraint?.update(offset: -sheetHeight)
        UIView.animate(withDuration: 0.30, delay: 0, options: .curveEaseOut) {
            dimmedView.alpha = 1
            rootView.layoutIfNeeded()
        }
    }

    func hide(completion: (() -> Void)? = nil) {
        guard let rootView, let dimmedView else { return }
        topConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            dimmedView.alpha = 0
            rootView.layoutIfNeeded()
        } completion: { _ in
            completion?()
        }
    }

    // MARK: Pan Handling

    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sheetView, let rootView else { return }
        let translation = gesture.translation(in: rootView)
        let velocity = gesture.velocity(in: rootView)

        switch gesture.state {
        case .changed:
            // 아래로만 이동
            if translation.y > 0 {
                sheetView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled, .failed:
            let progress = max(0, min(1, translation.y / sheetHeight))
            let shouldDismiss = progress > dismissProgressThreshold || velocity.y > dismissVelocityThreshold

            if shouldDismiss {
                // VC가 실제 dismiss 로직(onSelectStatus 호출 포함)을 수행할 수 있도록 시그널만 보냄
                requestDismissRelay.accept(())
                // transform 복구는 VC가 hide() 호출 후 자연스럽게 처리
            } else {
                UIView.animate(withDuration: 0.3, delay: 0,
                               usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                    sheetView.transform = .identity
                }
            }
        default:
            break
        }
    }
}
