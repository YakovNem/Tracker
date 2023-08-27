import UIKit

//MARK: - Model Structures

struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    let schedule: [Int]
}

struct TrackerCategory {
    let title: String
    var trackers: [Tracker]
}

struct TrackerRecord: Hashable {
    let trackerId: UUID
    let date: Date
}

//MARK: - TrackersViewController

class TrackersViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //MARK: - Properties
    
    private var categories: [TrackerCategory] = [] {
        didSet {
            visibleCategories = categories
        }
    }
    
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate: Date = Date()
    private var visibleCategories: [TrackerCategory] = []
    private var trackers: [Tracker] = []
    
    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .white
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Трекеры"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 34)
        titleLabel.textColor = .black
        titleLabel.backgroundColor = .clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    
    private var searchTextField: UITextField = {
        let searchTextField = UITextField()
        searchTextField.placeholder = "Поиск"
        searchTextField.borderStyle = .none
        searchTextField.layer.cornerRadius = 12
        searchTextField.layer.backgroundColor = Colors.backgroundDay.cgColor
        
        let searchIconView = UIImageView(frame: CGRect(x: 10, y: 5, width: 20, height: 20))
        searchIconView.image = UIImage(systemName: "magnifyingglass")
        searchIconView.contentMode = .scaleAspectFit
        searchIconView.tintColor = .lightGray
        
        let viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 30))
        viewContainer.addSubview(searchIconView)
        
        searchTextField.leftView = viewContainer
        searchTextField.leftViewMode = .always
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        return searchTextField
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = Date()
        datePicker.layer.cornerRadius = 8
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        return datePicker
    }()
    
    private lazy var emptyView: UIView = {
        let view = UIView()
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "star")
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            label.widthAnchor.constraint(equalToConstant: 343),
            label.heightAnchor.constraint(equalToConstant: 18),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8)
        ])
        view.isHidden = true
        return view
    }()
    
    //MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationController?.navigationBar.tintColor = .black
        
        let datePickerItem = UIBarButtonItem(customView: datePicker)
        self.navigationItem.rightBarButtonItem = datePickerItem
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tracker1 = Tracker(id: UUID(), title: "Поливать растения", color: ColorsSelection.selectionFive, emoji: "❤️", schedule: [1])
        let tracker2 = Tracker(id: UUID(), title: "Кошка заслонила камеру на созвоне", color: ColorsSelection.selectionTwo, emoji: "😻", schedule: [4, 5, 6])
        let tracker3 = Tracker(id: UUID(), title: "Бабушка прислала открытку в вотсапе", color: ColorsSelection.selectionOne, emoji: "🌺", schedule: [4, 5, 7])
        
        let trackerCategory = TrackerCategory(title: "Домашний уют", trackers: [tracker1])
        let trackerCategory2 = TrackerCategory(title: "Радостные мелочи", trackers: [tracker2, tracker3])
        
        categories = [trackerCategory, trackerCategory2]
        
        searchTextField.delegate = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setLayout()
        updateEmptyViewVisibility()
    }
    
    //MARK: - Layout Configuration
    
    private func setLayout() {
        view.backgroundColor = .white
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(searchTextField)
        view.addSubview(titleLabel)
        view.addSubview(datePicker)
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 254),
            titleLabel.heightAnchor.constraint(equalToConstant: 41),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: -105),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 88),
            
            searchTextField.widthAnchor.constraint(equalToConstant: 343),
            searchTextField.heightAnchor.constraint(equalToConstant: 36),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            
            datePicker.widthAnchor.constraint(equalToConstant: 100),
            datePicker.heightAnchor.constraint(equalToConstant: 34),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 234),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            datePicker.topAnchor.constraint(equalTo: view.topAnchor, constant: 49),
            
            collectionView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    //MARK: - Actions
    
    @objc func addButtonTapped() {
        let trackerTypeViewController = TrackerTypeViewController()
        trackerTypeViewController.delegate = self
        
        let navController = UINavigationController(rootViewController: trackerTypeViewController)
        navController.modalPresentationStyle = .formSheet
        navController.navigationBar.prefersLargeTitles = false
        self.present(navController, animated: true)
    }
    
    //Выбор даты и фильтрация
    
    @objc func datePickerChanged () {
        currentDate = datePicker.date
        filterTrackerByDate()
        updateEmptyViewVisibility()
        collectionView.reloadData()
    }
    
    private func filterTrackerByDate() {
        let dayOfWeek = currentDate.dayOfWeek()
        
        visibleCategories = categories.map { category in
            let filter = category.trackers.filter { $0.schedule.contains(dayOfWeek) }
            return TrackerCategory(title: category.title, trackers: filter)
        }.filter { !$0.trackers.isEmpty}
    }
    
    // Фильтрация по поиску
    
    private func updateEmptyViewVisibility() {
        let isEmpty = visibleCategories.allSatisfy { $0.trackers.isEmpty }
        emptyView.isHidden = !isEmpty
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        if newText.isEmpty {
            visibleCategories = categories
            collectionView.reloadData()
            updateEmptyViewVisibility()
            return true
        }
        
        visibleCategories = categories.map { category in
            let filteredTrackers = category.trackers.filter { $0.title.lowercased().contains(newText.lowercased()) }
            return TrackerCategory(title: category.title, trackers: filteredTrackers)
        }.filter { !$0.trackers.isEmpty }
        
        updateEmptyViewVisibility()
        collectionView.reloadData()
        
        return true
    }
    
    //MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.identifier, for: indexPath) as? TrackerCell
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        cell?.configure(with: tracker, completedTrackers:  completedTrackers, currentDate: currentDate)
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
            headerView.subviews.forEach { $0.removeFromSuperview() }
            
            let title = UILabel()
            title.font = UIFont.boldSystemFont(ofSize: 19)
            title.textColor = .black
            title.text = visibleCategories[indexPath.section].title
            title.frame = CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 50)
            headerView.addSubview(title)
            
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 167, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
}

extension TrackersViewController: TrackerCreationDelegate {
    func didCreateTracker(_ tracker: Tracker, category: TrackerCategory) {
        if let index = categories.firstIndex(where: { $0.title == category.title }) {
            categories[index].trackers.append(tracker)
        } else {
            categories.append(category)
        }
        collectionView.reloadData()
    }
}



