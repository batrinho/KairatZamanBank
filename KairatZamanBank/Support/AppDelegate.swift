//
//  AppDelegate.swift
//  KairatZamanBank
//
//  Created by Batyr Tolkynbayev on 18.10.2025.
//

import UIKit

enum AppSession {
    private static let tokenKey = "auth.token"
    private static let authKey  = "auth.isAuthorized"
    
    
    static var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set {
            if let v = newValue { UserDefaults.standard.set(v, forKey: tokenKey) }
            else { UserDefaults.standard.removeObject(forKey: tokenKey) }
        }
    }
    
    static var isAuthorized: Bool {
        get { UserDefaults.standard.bool(forKey: authKey) }
        set { UserDefaults.standard.set(newValue, forKey: authKey) }
    }
    
    static func reset() {
        token = nil
        isAuthorized = false
        NotificationCenter.default.post(name: .authDidChange, object: nil)
    }
}

extension Notification.Name {
    static let authDidChange = Notification.Name("authDidChange")
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var mainRouter: MainRouterProtocol?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        mainRouter = MainRouter(window: window!)
        mainRouter?.start()
        return true
    }
}

