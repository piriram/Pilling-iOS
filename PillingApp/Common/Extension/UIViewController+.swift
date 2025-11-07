//
//  UIViewController+.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/7/25.
//

import UIKit

extension UIViewController {
    func presentNotification(message: String) {
        let alert = UIAlertController(title: AppStrings.Common.alertTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.Common.okBtnTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }
    
}

