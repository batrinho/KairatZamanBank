//
//  MainRouter.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import UIKit
import SwiftUI

protocol MainRouterProtocol: AnyObject {
    func start()
}

final class MainRouter: NSObject, MainRouterProtocol {
    private var nvc = UINavigationController()
    private var window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
        super.init()
        window.makeKeyAndVisible()
    }
    
    func start() {
        let vc = MainPageView().wrapped
        vc.view.backgroundColor = UIColor(white: 0.96, alpha: 1)
        self.window.rootViewController = vc
    }
}
