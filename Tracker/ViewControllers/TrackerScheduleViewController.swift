import UIKit

protocol TrackerScheduleDelegate: AnyObject { func didSelectDays(_ days: [WeekDay]) }

final class TrackerScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Properties
    
    weak var delegate: TrackerScheduleDelegate?
    
    private var selectedDays: [WeekDay : Bool] = [:]
    private var days: [WeekDay] = WeekDay.allCases
    
    private var tableView: UITableView!
    private var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Готово", for: .normal)
        button.tintColor = UIColor(cgColor: Colors.whiteDay)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = UIColor(cgColor: Colors.blackDay)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Расписание"
        navigationItem.hidesBackButton = true
        view.backgroundColor = .white
        
        doneButton.addTarget(self, action: #selector(didTabDoneButton), for: .touchUpInside)
        
        tableView = createTableView()
        setupUI()
    }
    
    //MARK: - Layout Configuration
    
    private func setupUI() {
        
        //Add views
        view.addSubview(tableView)
        view.addSubview(doneButton)
        
        //Constraint
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.heightAnchor.constraint(equalToConstant: 525),
            
            doneButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
            
        ])
    }
    
    //MARK: - Actions
    
    @objc func didTabDoneButton() {
        let selectedDay = Array(selectedDays.keys.filter { selectedDays[$0] == true })
        delegate?.didSelectDays(selectedDay)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func switchChanged( _ sender: UISwitch) {
        let day = days[sender.tag]
        selectedDays[day] = sender.isOn
    }
    
    //MARK: -  UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        days.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell", for: indexPath)
        let day = days[indexPath.row]
        
        cell.textLabel?.text = day.fullName
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor(cgColor: Colors.blue)
        switchControl.isOn = selectedDays[day] ?? false
        switchControl.tag = indexPath.row
        switchControl.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        
        cell.accessoryView = switchControl
        cell.backgroundColor = .clear
        
        if indexPath.row != days.count - 1 {
            let cellHeight = self.tableView(tableView, heightForRowAt: indexPath)
            
            let separatorHeight: CGFloat = 0.5
            
            let separator = UIView(frame: CGRect(
                x: 20,
                y: cellHeight - separatorHeight,
                width: cell.frame.width - 40,
                height: separatorHeight))
            
            separator.backgroundColor = Colors.gray
            cell.addSubview(separator)
        }
        
        return cell
    }
    
    //MARK: - Helpers
    private func createTableView() -> UITableView? {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = Colors.backgroundDay
        tableView.layer.masksToBounds = true
        tableView.layer.cornerRadius = 16
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DayCell")
        return tableView
    }
}

