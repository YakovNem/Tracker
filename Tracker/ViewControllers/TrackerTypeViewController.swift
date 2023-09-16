import UIKit

enum TrackerType {
    case habit
    case irregularEvent
}

final class TrackerTypeViewController: UIViewController {
    
    weak var delegate: TrackerCreationDelegate?
    private let trackerCreationVC = TrackerCreationViewController()

    //MARK: - Properties
    
    private var habitButton: UIButton = {
       let habitButton = UIButton()
        habitButton.setTitle("Привычка", for: .normal)
        habitButton.tintColor = .white
        habitButton.backgroundColor = .black
        habitButton.layer.cornerRadius = 16
        habitButton.translatesAutoresizingMaskIntoConstraints = false
       return habitButton
    }()
    
    private var irregularEventButton: UIButton = {
        let irregularEventButton = UIButton()
        irregularEventButton.setTitle("Нерегулярное событие", for: .normal)
        irregularEventButton.backgroundColor = .black
        irregularEventButton.tintColor = .white
        irregularEventButton.layer.cornerRadius = 16
        irregularEventButton.translatesAutoresizingMaskIntoConstraints = false
        return irregularEventButton
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Создание трекера"
        
        habitButton.addTarget(self, action: #selector(handleHabit), for: .touchUpInside)
        irregularEventButton.addTarget(self, action: #selector(handleIrregularEvent), for: .touchUpInside)
        
        setupLayout()
    }
    
    //MARK: - Layout Configuration
    
    private func setupLayout() {
        
        //Add views
        view.addSubview(habitButton)
        view.addSubview(irregularEventButton)
        
        //Constraint
        NSLayoutConstraint.activate([
            habitButton.widthAnchor.constraint(equalToConstant: 335),
            habitButton.heightAnchor.constraint(equalToConstant: 60),
            habitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            habitButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            habitButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            irregularEventButton.widthAnchor.constraint(equalToConstant: 335),
            irregularEventButton.heightAnchor.constraint(equalToConstant: 60),
            irregularEventButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            irregularEventButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            irregularEventButton.topAnchor.constraint(equalTo: habitButton.bottomAnchor, constant: 16)
        ])
    }
    
    //MARK: - Actions
    
    @objc func handleHabit() {
        trackerCreationVC.trackerType = .habit
        trackerCreationVC.delegate = self.delegate
        navigationController?.pushViewController(trackerCreationVC, animated: true)
    }
    
    @objc func handleIrregularEvent() {
        trackerCreationVC.trackerType = .irregularEvent
        trackerCreationVC.delegate = self.delegate
        navigationController?.pushViewController(trackerCreationVC, animated: true)
    }
}
