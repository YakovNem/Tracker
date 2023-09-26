import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func isFirstLaunch() -> Bool {
        let isFirstLaunchKey = "isFirstLaunch"
        let defaults = UserDefaults.standard
        
        if defaults.bool(forKey: isFirstLaunchKey) == false {
            defaults.set(true, forKey: isFirstLaunchKey)
            return true
        }
        
        return false
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
            if isFirstLaunch() {
                let onboardingVC = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
                onboardingVC.onboardingDelegate = self
                window.rootViewController = onboardingVC
            } else {
                window.rootViewController = TabBarViewController()
            }
            
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) { }
    
    func sceneDidBecomeActive(_ scene: UIScene) { }
    
    func sceneWillResignActive(_ scene: UIScene) { }
    
    func sceneWillEnterForeground(_ scene: UIScene) { }
    
    func sceneDidEnterBackground(_ scene: UIScene) { }
}

extension SceneDelegate: OnboardingViewControllerDelegate {
    func onboardingDidFinish() {
        let tabBarController = TabBarViewController()
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }
}
