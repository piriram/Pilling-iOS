//
//  AppColor.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit

// MARK: - Presentation/Common/Constants/AppColor.swift
public enum AppColor {
    public static let bg = UIColor.systemBackground
    public static let card = UIColor.secondarySystemBackground
    public static let pillGreen800 = UIColor(hexString: "7EDD1C")
    public static let pillGreen200 = UIColor(hexString: "AFF466")
    public static let pillBrown = UIColor(hexString: "B8A07D")
    public static let notYetGray = UIColor(hexString: "3C3C43").withAlphaComponent(0.18)
    public static let pillWhite = UIColor.white
    public static let pillBorder = UIColor(hexString: "7EDD1C")
    public static let text = UIColor.label
    public static let subtext = UIColor.secondaryLabel
}




extension UIColor {
    /// Initialize UIColor from a hex string like "#RRGGBB" or "RRGGBB" or with alpha "#RRGGBBAA"/"RRGGBBAA".
    /// Returns nil if the string is not a valid hex color.
    public convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        // Supported lengths: 6 (RGB) or 8 (RGBA)
        guard hexString.count == 6 || hexString.count == 8, let hexValue = UInt64(hexString, radix: 16) else {
            return nil
        }
        let r, g, b, a: CGFloat
        if hexString.count == 6 {
            r = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexValue & 0x0000FF) / 255.0
            a = 1.0
        } else { // 8
            r = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
            g = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(hexValue & 0x000000FF) / 255.0
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Non-failable initializer. Falls back to black when the hex string is invalid.
    public convenience init(hexString s0: String) {
        var s = s0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        let isValidLength = (s.count == 6 || s.count == 8)
        if isValidLength, let value = UInt64(s, radix: 16) {
            let r, g, b, a: CGFloat
            if s.count == 6 {
                r = CGFloat((value & 0xFF0000) >> 16) / 255.0
                g = CGFloat((value & 0x00FF00) >> 8) / 255.0
                b = CGFloat(value & 0x0000FF) / 255.0
                a = 1.0
            } else {
                r = CGFloat((value & 0xFF000000) >> 24) / 255.0
                g = CGFloat((value & 0x00FF0000) >> 16) / 255.0
                b = CGFloat((value & 0x0000FF00) >> 8) / 255.0
                a = CGFloat(value & 0x000000FF) / 255.0
            }
            self.init(red: r, green: g, blue: b, alpha: a)
        } else {
            self.init(cgColor: UIColor.black.cgColor)
        }
    }
}

