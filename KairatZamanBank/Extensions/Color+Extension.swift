//
//  Color+Extension.swift
//  PhyDocOA
//
//  Created by Batyr Tolkynbayev on 12.12.2024.
//

import SwiftUI

extension Color {
    static let zamanDarkGreen = Color(red: 45/255,  green: 154/255, blue: 134/255)
    static let zamanGreen = Color(red: 238/255, green: 254/255, blue: 109/255)
    static let thirdColor = Color.secondary
    
    static let zamanBackground = Color.gray.opacity(0.1)
    
    // Card palette
    static let cardGradTop    = Color(red: 1.00, green: 1.00, blue: 0.82)
    static let cardGradBottom = Color(red: 0.92, green: 0.99, blue: 0.62)

    // Text
    static let textPrimary    = Color.primary
    static let textEmphasis   = Color.primary.opacity(0.90)
    static let textSecondary  = Color.primary.opacity(0.55)

    // UI bits
    static let chipTop        = Color.gray.opacity(0.30)
    static let chipBottom     = Color.gray.opacity(0.60)
    static let shadow12       = Color.primary.opacity(0.12)
}



