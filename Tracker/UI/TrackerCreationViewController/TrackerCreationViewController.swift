import UIKit

protocol TrackerCreationDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, category: TrackerCategory, type: TrackerType)
    func didUpdateTracker(_ originalTracker: Tracker, updatedTracker: Tracker, category: TrackerCategory)
}

enum TrackerViewControllerMode {
    case create
    case edit(tracker: Tracker)
}

class TrackerCreationViewController: KeyboardHandlingViewController, UITableViewDelegate, UITableViewDataSource, TrackerScheduleDelegate {
    
    //MARK: - Properties
    
    weak var delegate: TrackerCreationDelegate?
    
    var selectedCategory: TrackerCategoryCoreData?
    var selectedCategoryTitle: String?
    
    var mode: TrackerViewControllerMode = .create
    var activeTextFieldConstraints: [NSLayoutConstraint] = []
    
    private let trackerScheduleViewController = TrackerScheduleViewController()
    private let categoryListViewController = CategoryListViewController()
    
    private let trackerStore = TrackerStore()
    private let categoryStore = TrackerCategoryStore()
    private let trackerRecordStore = TrackerRecordStore()
    
    private var selectedDays: [WeekDay] = []
    
    private var tableView: UITableView!
    private var collectionView: ItemsCollectionView!
    
    var trackerType: TrackerType?
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Введите название трекера", attributes: [NSAttributedString.Key.foregroundColor: Colors.gray])
        textField.textColor = UIColor(cgColor: Colors.blackDay)
        textField.backgroundColor = Colors.backgroundDay
        textField.layer.cornerRadius = 16
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        let spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.leftView = spacerView
        return textField
    }()
    
    private var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .onDrag
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
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
        cancelButton.setTitleColor(UIColor(cgColor: Colors.red), for: .normal)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 16
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = Colors.red
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
    
    private var daysLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemBackground
        trackerScheduleViewController.delegate = self
        
        switch trackerType {
        case .habit:
            navigationItem.title = "Новая привычка"
        case .irregularEvent:
            navigationItem.title = "Новое нерегулярное событие"
        case .none:
            navigationItem.title = ""
        }
        if case .edit(let tracker) = mode {
            loadTrackerData(for: tracker)
        }
        configureUI()
        setupLayout()
        
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        categoryListViewController.categorySelected = { [weak self] selectedCategory in
            self?.selectedCategory = selectedCategory
            self?.selectedCategoryTitle = selectedCategory?.title
            self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
    
    //MARK: - Layout Configuration
    
    private func configureUI() {
        switch mode {
        case .create:
            navigationItem.title = trackerType == .habit ? "Новая привычка" : "Новое нерегулярное событие"
            saveButton.setTitle("Создать", for: .normal)
        case .edit(let tracker):
            textField.text = tracker.title
            navigationItem.title = trackerType == .habit ? "Редактирование привычки" : "Редактирование нерегулярного события"
            saveButton.setTitle("Сохранить", for: .normal)
        }
    }
    
    private func setupLayout() {
        switch mode {
            case .create:
                setupLayoutCreate()
                updateTextFieldConstraints(isEditMode: false)
            case .edit(let tracker):
                setupLayoutEdit(with: tracker)
                updateTextFieldConstraints(isEditMode: true)
        }
    }
    
    private func setupCommonUIComponents() {
        tableView = createTableView()
        collectionView = ItemsCollectionView()
        
        view.addSubview(scrollView)
        scrollView.addSubview(textField)
        scrollView.addSubview(tableView)
        scrollView.addSubview(collectionView)
        scrollView.addSubview(buttonStack)
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(saveButton)
    }

    private func setupConstraints(isEditMode: Bool) {
        var commonConstraints: [NSLayoutConstraint] = [
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            
            tableView.heightAnchor.constraint(equalToConstant: trackerType == .habit ? 150 : 75),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24),
            
            collectionView.heightAnchor.constraint(equalToConstant: 450),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -19),
            collectionView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 25),
            
            buttonStack.heightAnchor.constraint(equalToConstant: 60),
            buttonStack.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
        ]
        
        if isEditMode {
            scrollView.addSubview(daysLabel)
            let daysLabelConstraints: [NSLayoutConstraint] = [
                daysLabel.heightAnchor.constraint(equalToConstant: 38),
                daysLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 136),
                daysLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -136),
                daysLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            ]
            commonConstraints.append(contentsOf: daysLabelConstraints)
        }
        
        NSLayoutConstraint.activate(commonConstraints)
    }
    
    private func updateTextFieldConstraints(isEditMode: Bool) {
        NSLayoutConstraint.deactivate(activeTextFieldConstraints)

        if isEditMode {
            activeTextFieldConstraints = [
                textField.heightAnchor.constraint(equalToConstant: 75),
                textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                textField.topAnchor.constraint(equalTo: daysLabel.bottomAnchor, constant: 40)
            ]
        } else {
            activeTextFieldConstraints = [
                textField.heightAnchor.constraint(equalToConstant: 75),
                textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                textField.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24)
            ]
        }
        
        NSLayoutConstraint.activate(activeTextFieldConstraints)
    }

    private func setupLayoutCreate() {
        setupCommonUIComponents()
        setupConstraints(isEditMode: false)
    }

    private func setupLayoutEdit(with tracker: Tracker) {
        setupCommonUIComponents()
        setupConstraints(isEditMode: true)
    }

    //MARK: - Actions
    
    @objc func saveTapped() {
        guard
            let trackerName = textField.text, !trackerName.trimmingCharacters(in: .whitespaces).isEmpty,
            let selectedEmojiIndex = collectionView.selectedEmojiIndex,
            let selectedColorIndex = collectionView.selectedColorIndex,
            let trackerType = self.trackerType,
            let category = selectedCategory
        else { return }
        
        let trackerCategory = categoryStore.trackerCategory(from: category)
        let selectedEmoji = collectionView.emoji[selectedEmojiIndex.item]
        let selectedColor = collectionView.colors[selectedColorIndex.item]

        switch mode {
        case .create:
            let newTracker = Tracker(id: UUID(), title: trackerName, color: selectedColor, emoji: selectedEmoji, schedule: selectedDays, type: trackerType, isPinned: false)
            delegate?.didCreateTracker(newTracker, category: trackerCategory!, type: trackerType)
            dismiss(animated: true, completion: nil)
            
        case .edit(let tracker):
            let updatedTracker = Tracker(id: tracker.id, title: trackerName, color: selectedColor, emoji: selectedEmoji, schedule: selectedDays, type: trackerType, isPinned: tracker.isPinned)
            
            trackerStore.updateTracker(originalTracker: tracker, updatedTracker: updatedTracker)
            guard let trackerCategory = categoryStore.trackerCategory(from: selectedCategory!) else { return }
            delegate?.didUpdateTracker(tracker, updatedTracker: updatedTracker, category: trackerCategory)
            dismiss(animated: true, completion: nil)
        }
    }

    
    func loadTrackerData(for tracker: Tracker) {
        textField.text = tracker.title

        guard let coreDataTracker = trackerStore.coreDataFrom(tracker: tracker) else { return }
        let completedDaysCount = trackerRecordStore.countOfCompletedDays(for: coreDataTracker)
            daysLabel.text = "\(completedDaysCount) \(completedDaysCount.daysEnding())"
        
        if let category = trackerStore.category(for: tracker) {
                selectedCategoryTitle = category.title
            }
    }


    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateDoneButton()
    }
    
    private func updateDoneButton() {
        if textField.text?.isEmpty == true {
            saveButton.backgroundColor = Colors.gray
        } else {
            saveButton.backgroundColor = UIColor(cgColor: Colors.blackDay)
        }
    }
    
    func didSelectDays(_ days: [WeekDay]) {
        selectedDays = days.map { $0.rawValue }
            .sortedDaysOfWeek()
            .compactMap { WeekDay(rawValue: $0) }
        tableView.reloadData()
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            navigationController?.pushViewController(categoryListViewController, animated: true)
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
        return trackerType == .habit ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        if indexPath.row == 0  && trackerType == .habit {
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
            cell.detailTextLabel?.text = selectedCategoryTitle
            cell.detailTextLabel?.textColor = Colors.gray
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
    
    private func createTableView() -> UITableView {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = Colors.backgroundDay
        table.layer.cornerRadius = 16
        table.separatorStyle = .none
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }
}
