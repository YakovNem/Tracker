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
    let trackers: [Tracker]
}

struct TrackerRecord: Hashable {
    let trackerId: UUID
    let date: Date
}

private enum SearchType {
    case date, title, none
}

//MARK: - TrackersViewController

class TrackersViewController: KeyboardHandlingViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //MARK: - Properties
    
    private var categories: [TrackerCategory] = [] {
        didSet {
            visibleCategories = categories
        }
    }
    
    private var visibleCategories: [TrackerCategory] = [] {
        didSet {
            updateEmptyViewVisibility()
        }
    }
    
    private var currentSearchType: SearchType = .none
    private var completedTrackers: [TrackerRecord] = []
    private var trackers: [Tracker] = []
    private var currentDate: Date = Date()
    
    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .white
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
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
    
    private lazy var emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var emptyLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Поиск"
        return searchBar
    }()
    
    private lazy var emptyView: UIView = {
        let view = UIView()
        view.addSubview(emptyImageView)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyLabel.widthAnchor.constraint(equalToConstant: 343),
            emptyLabel.heightAnchor.constraint(equalToConstant: 18),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8)
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
        title = "Трекеры"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let tracker1 = Tracker(id: UUID(), title: "Поливать растения", color: ColorsSelection.selectionFive, emoji: "❤️", schedule: [1])
        let tracker2 = Tracker(id: UUID(), title: "Кошка заслонила камеру на созвоне", color: ColorsSelection.selectionTwo, emoji: "😻", schedule: [4, 5, 6])
        let tracker3 = Tracker(id: UUID(), title: "Бабушка прислала открытку в вотсапе", color: ColorsSelection.selectionOne, emoji: "🌺", schedule: [4, 5, 7])
        
        let trackerCategory = TrackerCategory(title: "Домашний уют", trackers: [tracker1])
        let trackerCategory2 = TrackerCategory(title: "Радостные мелочи", trackers: [tracker2, tracker3])
        
        categories = [trackerCategory, trackerCategory2]
        
        searchBar.delegate = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupLayout()
        
        currentSearchType = .date
        filterTrackerByDate()
    }
    
    //MARK: - Layout Configuration
    
    private func setupLayout() {
        view.backgroundColor = .white
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            
            datePicker.widthAnchor.constraint(equalToConstant: 105),
            datePicker.heightAnchor.constraint(equalToConstant: 34),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
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
        currentSearchType = .date
        collectionView.reloadData()
    }
    
    private func filterTrackerByDate() {
        let dayOfWeek = currentDate.dayOfWeek()
        visibleCategories = categories.map { category in
            let filter = category.trackers.filter { $0.schedule.contains(dayOfWeek) }
            return TrackerCategory(title: category.title, trackers: filter)
        }.filter { !$0.trackers.isEmpty}
    }
    
    private func updateEmptyViewVisibility() {
        let isEmpty = visibleCategories.allSatisfy { $0.trackers.isEmpty }
        emptyView.isHidden = !isEmpty
        
        switch currentSearchType {
        case .date:
            emptyImageView.image = UIImage(named: "star")
            emptyLabel.text = "Что будем отслеживать?"
        case .title:
            emptyImageView.image = UIImage(named: "emojiSearch")
            emptyLabel.text = "Ничего не найдено"
        case .none:
            break
        }
    }
    
    //MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.identifier, for: indexPath) as? TrackerCell
        cell?.prepareForReuse()
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        cell?.delegate = self
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

    //MARK: - Extension

extension TrackersViewController: TrackerCreationDelegate {
    func didCreateTracker(_ tracker: Tracker, category: TrackerCategory) {
        if let index = categories.firstIndex(where: { $0.title == category.title }) {
            let updatedTrackers = categories[index].trackers + [tracker]
            let updatedCategory = TrackerCategory(title: category.title, trackers: updatedTrackers)
            categories[index] = updatedCategory
        } else {
            categories.append(category)
        }

        switch currentSearchType {
        case .date:
            filterTrackerByDate()
        case .title:
            if let searchText = searchBar.text, !searchText.isEmpty {
                visibleCategories = categories.map { category in
                    let filteredTrackers = category.trackers.filter { $0.title.lowercased().contains(searchText.lowercased()) }
                    return TrackerCategory(title: category.title, trackers: filteredTrackers)
                }.filter { !$0.trackers.isEmpty }
            } else {
                visibleCategories = categories
            }
        case .none:
            visibleCategories = categories
        }
        
        collectionView.reloadData()
    }
}

extension TrackersViewController: TrackerCellDelegate {
    
    func isTrackerCompleted(_ tracker: Tracker) -> Bool {
        return completedTrackers.contains(where: { $0.trackerId == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: currentDate) })
    }
    
    func trackerCell(_ cell: TrackerCell, didAdd tracker: Tracker) {
        let record = TrackerRecord(trackerId: tracker.id, date: currentDate)
        
        if !completedTrackers.contains(where: { $0.trackerId == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: currentDate) }) {
            completedTrackers.append(record)
            cell.configure(with: tracker, completedTrackers: completedTrackers, currentDate: currentDate)
        }
    }
    
    func trackerCell(_ cell: TrackerCell, didRemove tracker: Tracker) {
        if let index = completedTrackers.firstIndex(where: { $0.trackerId == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: currentDate) }) {
            completedTrackers.remove(at: index)
            cell.configure(with: tracker, completedTrackers: completedTrackers, currentDate: currentDate)
        }
    }
}

extension TrackersViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentSearchType = .title
        
        if searchText.isEmpty {
            visibleCategories = categories
        } else {
            visibleCategories = categories.map { category in
                let filteredTrackers = category.trackers.filter { $0.title.lowercased().contains(searchText.lowercased()) }
                return TrackerCategory(title: category.title, trackers: filteredTrackers)
            }.filter { !$0.trackers.isEmpty }
        }
        collectionView.reloadData()
    }
}
