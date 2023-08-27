//
//  TrackerCreationViewController.swift
//  Tracker
//
//  Created by Yakov Nemychenkov on 09.07.2023.
//
import UIKit

protocol TrackerCreationDelegate: AnyObject { func didCreateTracker(_ tracker: Tracker, category: TrackerCategory) }

class TrackerCreationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TrackerScheduleDelegate {
    
    //MARK: - Properties
    
    weak var delegate: TrackerCreationDelegate?
    
    private let trackerScheduleViewController = TrackerScheduleViewController()
    private var selectedDays: [WeekDay] = []
    
    private var tableView: UITableView!
    
    private var textField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Введите название трекера", attributes: [NSAttributedString.Key.foregroundColor: Colors.gray])
        textField.textColor = UIColor(cgColor: Colors.blackDay)
        textField.backgroundColor = Colors.backgroundDay
        textField.layer.cornerRadius = 16
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.leftView = spacerView
        return textField
    }()
    
    private var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("Создать", for: .normal)
        button.tintColor = .white
        button.backgroundColor = Colors.gray
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.setTitleColor(UIColor(red: 0.96, green: 0.42, blue: 0.42, alpha: 1), for: .normal)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 16
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(red: 0.961, green: 0.42, blue: 0.424, alpha: 1).cgColor
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        return cancelButton
    }()
    
    private var buttonStack: UIStackView = {
        let buttonStack = UIStackView()
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8
        return buttonStack
    } ()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Новая привычка"
        navigationItem.hidesBackButton = true
        view.backgroundColor = .white
        trackerScheduleViewController.delegate = self
        
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        setupLayout()
    }
    
    //MARK: - Layout Configuration
    
    private func setupLayout() {
        
        tableView = createTabelView()
        
        view.addSubview(tableView)
        view.addSubview(textField)
        view.addSubview(buttonStack)
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(saveButton)
        
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 75),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34),
            buttonStack.heightAnchor.constraint(equalToConstant: 60),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            tableView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    //MARK: - Actions
    
    @objc func saveTapped() {
        guard let trackerName = textField.text, !trackerName.trimmingCharacters(in: .whitespaces).isEmpty else{ return }
        let schedule = selectedDays.map { $0.rawValue}
        
        let newTracker = Tracker(id: UUID(), title: trackerName, color: ColorsSelection.selectionFourteen , emoji: "🤔", schedule: schedule)
        
        let categoryTracker = TrackerCategory(title: "Важное", trackers: [newTracker])
        
        delegate?.didCreateTracker(newTracker, category: categoryTracker)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func didSelectDays(_ days: [WeekDay]) {
        selectedDays = days.map { $0.rawValue }
            .sortedDaysOfWeek()
            .map { WeekDay(rawValue: $0)! }
        tableView.reloadData()
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0: break
        case 1:
            navigationController?.pushViewController(trackerScheduleViewController, animated: true)
        default: break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        if indexPath.row == 0 {
            let cellHeight = self.tableView(tableView, heightForRowAt: indexPath)
            
            let separatorHeight: CGFloat = 1
            
            let separator = UIView(frame: CGRect(
                x: 20,
                y: cellHeight - separatorHeight,
                width: cell.frame.width,
                height: separatorHeight))
            
            separator.backgroundColor = Colors.gray
            cell.addSubview(separator)
        }
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Категория"
        case 1:
            cell.textLabel?.text = "Расписание"
            if selectedDays.count == WeekDay.allCases.count {
                cell.detailTextLabel?.text = "Каждый день"
                cell.detailTextLabel?.textColor = Colors.gray
            } else {
                let shortFroms = selectedDays.map { $0.shortName }
                cell.detailTextLabel?.text = shortFroms.joined(separator: ", ")
                cell.detailTextLabel?.textColor = Colors.gray
            }
        default:
            break
        }
        
        return cell
    }
    
    //MARK: - Helpers
    
    private func createTabelView() -> UITableView {
        let tabel = UITableView()
        tabel.delegate = self
        tabel.dataSource = self
        tabel.backgroundColor = Colors.backgroundDay
        tabel.layer.cornerRadius = 16
        tabel.separatorStyle = .none
        tabel.translatesAutoresizingMaskIntoConstraints = false
        tabel.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tabel
    }
}

extension Array where Element == Int {
    func sortedDaysOfWeek() -> [Int] {
        self.sorted { (day1, day2) -> Bool in
            switch (day1, day2) {
                case (1, 7):
                    return false
                case (7, 1):
                    return true
                default:
                    return day1 < day2
            }
        }
    }
}

