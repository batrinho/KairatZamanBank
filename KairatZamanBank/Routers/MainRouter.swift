// MainRouter.swift
import SwiftUI
import UIKit

protocol MainRouterProtocol: AnyObject { func start() }

@MainActor
final class MainRouter: NSObject, MainRouterProtocol {
    private let window: UIWindow
    private let net = NetworkingService()
    private var authNVC: UINavigationController?

    init(window: UIWindow) {
        self.window = window
        super.init()
        window.makeKeyAndVisible()

        // React to login/logout
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthChange),
            name: .authDidChange,
            object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    func start() {
        AppSession.isAuthorized ? startMainFlow() : startAuthFlow()
    }

    @objc private func handleAuthChange() { start() }

    // MARK: Auth
    private func startAuthFlow() {
        let login = LoginView(
            onSignIn: { [weak self] in self?.startMainFlow() },
            onShowSignUp: { [weak self] in self?.pushSignUp() }
        ).environmentObject(net)
        let hc = UIHostingController(rootView: login)
        hc.view.backgroundColor = UIColor(white: 0.96, alpha: 1)

        let nav = UINavigationController(rootViewController: hc)
        nav.navigationBar.prefersLargeTitles = false
        authNVC = nav
        setRoot(nav)
    }

    private func pushSignUp() {
        guard let nav = authNVC else { return }
        let su = SignUpView(onComplete: { [weak self] in self?.startMainFlow() })
            .environmentObject(net)
        nav.pushViewController(UIHostingController(rootView: su), animated: true)
    }

    // MARK: Main
    private func startMainFlow() {
        authNVC = nil
        let main = MainPageView().environmentObject(net)
        let hc = UIHostingController(rootView: main)
        hc.view.backgroundColor = UIColor(white: 0.96, alpha: 1)
        setRoot(hc)
    }

    private func setRoot(_ vc: UIViewController) {
        if window.rootViewController == nil { window.rootViewController = vc; return }
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            self.window.rootViewController = vc
        }
    }
}
