import UIKit

struct StatisticItem {
    let title: String
    let value: String
}

class StatisticsViewController: UIViewController {
    
    private var statistics: [StatisticItem] = []
    private var trackerRecordStore = TrackerRecordStore()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(StatisticsCell.self, forCellWithReuseIdentifier: StatisticsCell.identifier)
        return collectionView
    }()
    
    private var smileyImageView: UIImageView = {
        let smileyImageView = UIImageView()
        smileyImageView.image = UIImage(named: "statisticsImage")
        smileyImageView.contentMode = .scaleAspectFit
        smileyImageView.translatesAutoresizingMaskIntoConstraints = false
        return smileyImageView
    }()
    
    private var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Анализировать пока нечего"
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return subtitleLabel
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let totalCountOfAllCompletedTrackers = trackerRecordStore.countOfAllCompletedTrackers()
        statistics = [
            StatisticItem(title: "Трекеров завершено", value: "\(totalCountOfAllCompletedTrackers)")
        ]

        collectionView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("statistics", comment: "Title for the trackers screen")
        navigationController?.navigationBar.prefersLargeTitles = true
        setupLayout()
    }

  private  func setupLayout() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(smileyImageView)
        view.addSubview(subtitleLabel)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            smileyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            smileyImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            smileyImageView.widthAnchor.constraint(equalToConstant: 80),
            smileyImageView.heightAnchor.constraint(equalToConstant: 80),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: smileyImageView.bottomAnchor, constant: 8),
            
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -126)
        ])
    }
}

extension StatisticsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = statistics.count
        smileyImageView.isHidden = count != 0
        subtitleLabel.isHidden = count != 0
        return count
    }


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatisticsCell.identifier, for: indexPath) as! StatisticsCell
        cell.configure(with: statistics[indexPath.row])
        return cell
    }

    
    //MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 90)
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 20
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return 20
        }
}


