//
//  UIViewController+.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/7/25.
//

import UIKit
import SnapKit

extension UIViewController {
    func presentNotification(message: String) {
        let alert = UIAlertController(title: AppStrings.Common.alertTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.Common.okBtnTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    func presentError(
        title: String = AppStrings.Common.errorTitle,
        message: String,
        includeSettingsOption: Bool = false,
        settingsHandler: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        if includeSettingsOption, let handler = settingsHandler {
            let settingsAction = UIAlertAction(
                title: "설정으로 이동",
                style: .default
            ) { _ in
                handler()
            }
            alert.addAction(settingsAction)
        }
        
        alert.addAction(UIAlertAction(
            title: AppStrings.Common.okBtnTitle,
            style: .default
        ))
        present(alert, animated: true)
    }
    
    func showToast(message: String, duration: TimeInterval = 1.5) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 16)/*Typography.body2(.medium)*/
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        view.addSubview(toastLabel)
        
        toastLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.height.equalTo(44)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(
                withDuration: 0.3,
                delay: duration,
                options: .curveEaseOut,
                animations: {
                    toastLabel.alpha = 0
                }
            ) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
