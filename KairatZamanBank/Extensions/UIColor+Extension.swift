//
//  UIColor+Extension.swift
//  PhyDocOA
//
//  Created by Batyr Tolkynbayev on 12.12.2024.
//

import UIKit

extension UIColor {
    static func fromHex(_ hex: UInt) -> UIColor {
        UIColor(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
