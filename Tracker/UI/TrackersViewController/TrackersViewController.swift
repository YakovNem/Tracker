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
    
    private var colors = Colors()
    
    private var currentSearchType: SearchType = .none
    private var completedTrackers: [TrackerRecord] = []
    private var trackers: [Tracker] = []
    private var currentDate: Date = Date()
    
    private var trackerStore = TrackerStore()
    private var trackerCategoryStore = TrackerCategoryStore()
    private var trackerRecordStore = TrackerRecordStore()
    
    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .systemBackground
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale.current
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
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = NSLocalizedString("search", comment: "Placeholder text for the search bar in trackers screen")
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
        navigationController?.navigationBar.tintColor = .label
        
        let datePickerItem = UIBarButtonItem(customView: datePicker)
        self.navigationItem.rightBarButtonItem = datePickerItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("trackers", comment: "Title for the trackers screen")
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
        view.backgroundColor = colors.viewBackgroundColor
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
        let isEmpty: Bool

        switch currentSearchType {
        case .date:
            isEmpty = trackerStore.fetchedResultsController.fetchedObjects?.isEmpty ?? true
        case .title:
            isEmpty = (trackerStore.fetchedResultsController.fetchedObjects?.isEmpty ?? true) && !(searchBar.text?.isEmpty ?? true)
        case .none:
            isEmpty = trackerStore.fetchedResultsController.fetchedObjects?.isEmpty ?? true
        }

        emptyView.isHidden = !isEmpty

        switch currentSearchType {
        case .date:
            emptyImageView.image = UIImage(named: "star")
            emptyLabel.text = NSLocalizedString("track_what_text", comment: "Prompt asking what to track")
        case .title:
            emptyImageView.image = UIImage(named: "emojiSearch")
            emptyLabel.text = NSLocalizedString("nothing_found_text", comment: "Text indicating that nothing was found")
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
            title.textColor = .label
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

//MARK: - Extensions

extension TrackersViewController: TrackerCreationDelegate {
    func didUpdateTracker(_ originalTracker: Tracker, updatedTracker: Tracker, category: TrackerCategory) {

           trackerStore.updateTracker(originalTracker: originalTracker, updatedTracker: updatedTracker)
           collectionView.reloadData()
           updateEmptyViewVisibility()
       }
    
    func didCreateTracker(_ tracker: Tracker, category: TrackerCategory, type trackerType: TrackerType) {
        do {
            switch trackerType {
            case .habit:
                try? trackerStore.createTracker(tracker: tracker, category: category, type: .habit)
            case .irregularEvent:
                try? trackerStore.createTracker(tracker: tracker, category: category, type: .irregularEvent)
            }
        } catch let error {
            print("Ошибка создания трекера \(error)")
        }
        collectionView.reloadData()
        updateEmptyViewVisibility()
    }
}

extension TrackersViewController: TrackerCellDelegate {
    func isTrackerCompleted(_ tracker: Tracker) -> Bool {
           if let coreDataTracker = trackerStore.coreDataFrom(tracker: tracker) {
               let records = trackerRecordStore.fetchRecords(for: coreDataTracker)
               return records.contains(where: { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: currentDate) })
           }
           return false
       }
       
       func trackerCell(_ cell: TrackerCell, didAdd tracker: Tracker) {
           if let coreDataTracker = trackerStore.coreDataFrom(tracker: tracker) {
               trackerRecordStore.createRecord(for: coreDataTracker, date: currentDate)
           }
           cell.configure(with: tracker, completedTrackers: [], currentDate: currentDate)
       }
       
       func trackerCell(_ cell: TrackerCell, didRemove tracker: Tracker) {
           if let coreDataTracker = trackerStore.coreDataFrom(tracker: tracker) {
               if let record = trackerRecordStore.fetchRecords(for: coreDataTracker).first(where: { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: currentDate) }) {
                   trackerRecordStore.deleteRecord(record)
               }
           }
           cell.configure(with: tracker, completedTrackers: [], currentDate: currentDate)
       }

    func trackerCell(_ cell: TrackerCell, didRequestEdit tracker: Tracker) {
        let trackerCreationVC = TrackerCreationViewController()
        trackerCreationVC.mode = .edit(tracker: tracker)
        trackerCreationVC.trackerType = tracker.type
        
        let navigationController = UINavigationController(rootViewController: trackerCreationVC)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true, completion: nil)
    }
    
    func trackerCell(_ cell: TrackerCell, didDelete tracker: Tracker) {
        let alert = UIAlertController(title: nil,
                                      message: "Уверены, что хотите удалить трекер?",
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { _ in
            if let trackerCoreData = self.trackerStore.coreDataFrom(tracker: tracker) {
                self.trackerStore.deleteTracker(tracker: trackerCoreData)
                self.collectionView.reloadData()
                self.updateEmptyViewVisibility()
            } else {
                print("Could not convert Tracker to TrackerCoreData")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Отменить", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func trackerCell(_ cell: TrackerCell, didTogglePin tracker: Tracker) {
        // Check if the tracker is already pinned
        if let coreDataTracker = trackerStore.coreDataFrom(tracker: tracker) {
            if coreDataTracker.isPinned {
                // Unpin the tracker if it's already pinned (optional: if you want to toggle pin/unpin)
                coreDataTracker.isPinned = false
            } else {
                // Pin the tracker if it's not already pinned
                trackerStore.pinTracker(tracker: tracker)
            }
            
            // Reload the cell to reflect the change
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.reloadItems(at: [indexPath])
            }
        } else {
            print("Could not convert Tracker to TrackerCoreData")
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
