import UIKit

protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingDidFinish()
}

class OnboardingViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    //MARK: - Properties
    
    weak var onboardingDelegate: OnboardingViewControllerDelegate?
    
    private lazy var pages: [UIViewController] = {
        
        let firstViewController = ContentViewController()
        firstViewController.backgroundImage = UIImage(named: "firstImage")
        firstViewController.mainText = "Отслеживайте только то, что хотите"
        firstViewController.contentDelegate = self
        
        let secondViewController = ContentViewController()
        secondViewController.backgroundImage = UIImage(named: "secondImage")
        secondViewController.mainText = "Даже если это не литры воды и йога"
        secondViewController.contentDelegate = self 
        
        return [firstViewController, secondViewController]
    }()
    
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = pages.count
        control.currentPageIndicatorTintColor = UIColor(cgColor: Colors.blackDay)
        control.pageIndicatorTintColor = Colors.backgroundDay
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        
        if let firstViewController = pages.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        
        setupControl()
    }
    
    //MARK: - Layout Configuration
    
    private func setupControl() {
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
               pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150)
           ])
    }
    
    //MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else { return nil }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else { return nil }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < pages.count else {
            return nil
        }
        
        return pages[nextIndex]
    }
    
    //MARK: - UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
}

//MARK: - Extensions

extension OnboardingViewController: ContentViewControllerDelegate {
    func didTapDoneButton() {
        onboardingDelegate?.onboardingDidFinish()
    }
}
