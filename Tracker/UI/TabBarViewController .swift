import UIKit

class TabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupTabBarShadow()
    }
        private func setupViewControllers() {
            let trackersViewController = UINavigationController(rootViewController: TrackersViewController())
            trackersViewController.title = "Трекеры"
            trackersViewController.tabBarItem = UITabBarItem(
                title: "Трекеры",
                image: UIImage(systemName: "smallcircle.filled.circle.fill"),
                tag: 0)
            
            let statisticsViewController = StatisticsViewController()
            statisticsViewController.title = "Статистика"
            statisticsViewController.tabBarItem = UITabBarItem(
                title: "Статистика",
                image: UIImage(systemName: "hare.fill"),
                tag: 1)
            
            self.viewControllers = [trackersViewController, statisticsViewController]
        }
    
    private func setupTabBarShadow() {
        let borderLayer = CALayer()
        borderLayer.backgroundColor = Colors.gray.cgColor
        borderLayer.frame = CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5)
        tabBar.layer.addSublayer(borderLayer)
        
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false
    }
}
