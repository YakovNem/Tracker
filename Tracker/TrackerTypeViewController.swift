//
//  TrackerTypeViewController.swift
//  Tracker
//
//  Created by Yakov Nemychenkov on 08.07.2023.
//
import UIKit

class TrackerTypeViewController: UIViewController {
    
    weak var delegate: TrackerCreationDelegate?
    private let trackerCreationVC = TrackerCreationViewController()

    //MARK: - Properties
    
    private var habbitButton: UIButton = {
       let habbitButton = UIButton()
        habbitButton.setTitle("Привычка", for: .normal)
        habbitButton.tintColor = .white
        habbitButton.backgroundColor = .black
        habbitButton.layer.cornerRadius = 16
        habbitButton.translatesAutoresizingMaskIntoConstraints = false
       return habbitButton
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
        
        habbitButton.addTarget(self, action: #selector(handleHabit), for: .touchUpInside)
        irregularEventButton.addTarget(self, action: #selector(handleIrregularEvent), for: .touchUpInside)
        
        setupLayout()
    }
    
    //MARK: - Layout Configuration
    
    private func setupLayout() {
        
        //Add views
        view.addSubview(habbitButton)
        view.addSubview(irregularEventButton)
        
        //Constraint
        NSLayoutConstraint.activate([
            habbitButton.widthAnchor.constraint(equalToConstant: 335),
            habbitButton.heightAnchor.constraint(equalToConstant: 60),
            habbitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            habbitButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            habbitButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            irregularEventButton.widthAnchor.constraint(equalToConstant: 335),
            irregularEventButton.heightAnchor.constraint(equalToConstant: 60),
            irregularEventButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            irregularEventButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            irregularEventButton.topAnchor.constraint(equalTo: habbitButton.bottomAnchor, constant: 16)
        ])
    }
    
    //MARK: - Actions
    
    @objc func handleHabit() {
        trackerCreationVC.delegate = self.delegate
        navigationController?.pushViewController(trackerCreationVC, animated: true)
    }
    
    @objc func handleIrregularEvent() {
        navigationController?.pushViewController(trackerCreationVC, animated: true)
    }
}
