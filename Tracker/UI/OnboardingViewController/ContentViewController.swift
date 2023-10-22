import UIKit

protocol ContentViewControllerDelegate: AnyObject {
    func didTapDoneButton()
}

class ContentViewController: UIViewController {
    
    //MARK: - Properties
    
    weak var contentDelegate: ContentViewControllerDelegate?
    
    var backgroundImage: UIImage?
    var mainText: String?
    var buttonText: String?
    
    private var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var buttonDone: UIButton = {
        let button = UIButton()
        button.setTitle("Вот это технологии!", for: .normal)
        button.layer.cornerRadius = 16
        button.backgroundColor = UIColor(cgColor: Colors.blackDay)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapButtonDone), for: .touchUpInside)
        return button
    }()
    
    private var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.tintColor = UIColor(cgColor: Colors.blackDay)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }
    
    //MARK: - Actions
    
    @objc func didTapButtonDone() {
        contentDelegate?.didTapDoneButton()
    }
    
    //MARK: - Layout Configuration
    
    private func setupLayout() {
        view.addSubview(backgroundImageView)
        view.addSubview(buttonDone)
        view.addSubview(label)
        
        backgroundImageView.image = backgroundImage
        label.text = mainText
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            buttonDone.heightAnchor.constraint(equalToConstant: 60),
            buttonDone.widthAnchor.constraint(equalToConstant: 335),
            buttonDone.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -84),
            buttonDone.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonDone.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonDone.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 160),
            
            label.heightAnchor.constraint(equalToConstant: 76),
            label.widthAnchor.constraint(equalToConstant: 343),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -304)
        ])
    }
}
