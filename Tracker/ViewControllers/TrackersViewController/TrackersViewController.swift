import UIKit

private enum SearchType {
    case date, title, none
}

//MARK: - TrackersViewController

class TrackersViewController: KeyboardHandlingViewController {
    
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
    
    private var trackerStore = TrackerStore()
    private var trackerCategoryStore = TrackerCategoryStore()
    private var trackerRecordStore = TrackerRecordStore()
    
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
        
        searchBar.delegate = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        trackerStore.delegate = self
        
        setupLayout()
        
        currentSearchType = .date
        filterTrackerByDate()
        updateEmptyViewVisibility()
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
    
    @objc func datePickerChanged() {
        currentDate = datePicker.date
        currentSearchType = .date
        filterTrackerByDate()
        updateEmptyViewVisibility()
        collectionView.reloadData()
    }
    
    private func filterTrackerByDate() {
        trackerStore.updateFetchRequest(forDate: currentDate)
        collectionView.reloadData()
    }
    
    private func updateEmptyViewVisibility() {
        let isEmpty = trackerStore.fetchedResultsController.fetchedObjects?.isEmpty ?? true
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
}

//MARK: - Extension

extension TrackersViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sections = trackerStore.fetchedResultsController.sections?.count
        else {
            return 0
        }
        return sections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let trackers = trackerStore.fetchedResultsController.sections?[section].numberOfObjects
        else {
            return 0
        }
        return trackers
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.identifier, for: indexPath) as? TrackerCell
        
        let trackerCategoryCoreData = trackerCategoryStore.fetchedResultsController.object(at: IndexPath(row: indexPath.section, section: 0))
        
        guard
            let trackersArray = trackerCategoryCoreData.tracker?.allObjects as? [TrackerCoreData],
            indexPath.row < trackersArray.count
        else {
            return UICollectionViewCell()
        }
        
        let trackerCoreData = trackerStore.fetchedResultsController.object(at: indexPath)
        guard let tracker = trackerStore.tracker(from: trackerCoreData) else {
            return UICollectionViewCell()
        }
        
        cell?.delegate = self
        cell?.configure(with: tracker, completedTrackers: completedTrackers, currentDate: currentDate)
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
            headerView.subviews.forEach { $0.removeFromSuperview() }
            
            let title = UILabel()
            title.font = UIFont.boldSystemFont(ofSize: 20)
            title.textColor = .black
            guard let sectionInfo = trackerStore.fetchedResultsController.sections?[indexPath.section],
                  let category = sectionInfo.objects?.first as? TrackerCoreData,
                  let categoryName = category.trackerCategory?.title else {
                return headerView
            }
            title.text = categoryName
            
            title.frame = CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 50)
            headerView.addSubview(title)
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
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
        do {
            if let _ = try trackerStore.createTracker(tracker: tracker, category: category) {
            }
        } catch let error {
            print("Ошибка создания трекера \(error)")
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
        trackerStore.updateSearchPredicate(with: searchText)
        updateEmptyViewVisibility()
        collectionView.reloadData()
    }
    
}

extension TrackersViewController: TrackerStoreDelegate {
    func didUpdateData(in store: TrackerStore) {
        collectionView.reloadData()
    }
}
