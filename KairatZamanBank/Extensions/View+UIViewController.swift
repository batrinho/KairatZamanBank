//
//  View+UIViewController.swift
//  PhyDocOA
//
//  Created by Batyr Tolkynbayev on 12.12.2024.
//

import UIKit
import SwiftUI

public extension View {
    var wrapped: UIHostingController<Self> {
        UIHostingController(rootView: self)
    }
}

//extension View {
//    func onTapHaptic(
//        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
//        perform action: @escaping () -> Void
//    ) -> some View {
//        onTapGesture {
//            UIImpactFeedbackGenerator(style: style).impactOccurred()
//            action()
//        }
//    }
//
//    func onTapNotify(
//        _ type: UINotificationFeedbackGenerator.FeedbackType,
//        perform action: @escaping () -> Void
//    ) -> some View {
//        onTapGesture {
//            UINotificationFeedbackGenerator().notificationOccurred(type)
//            action()
//        }
//    }
//}
