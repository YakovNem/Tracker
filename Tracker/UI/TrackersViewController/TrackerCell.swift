import UIKit

protocol TrackerCellDelegate: AnyObject {
    func trackerCell(_ cell: TrackerCell, didAdd tracker: Tracker)
    func trackerCell(_ cell: TrackerCell, didRemove tracker: Tracker)
    func isTrackerCompleted(_ tracker: Tracker) -> Bool
    func trackerCell(_ cell: TrackerCell, didRequestEdit tracker: Tracker)
    func trackerCell(_ cell: TrackerCell, didDelete tracker: Tracker)
    func trackerCell(_ cell: TrackerCell, didTogglePin tracker: Tracker)
}

class TrackerCell: UICollectionViewCell {
    
    //MARK: - Constants
    static let identifier = "TrackerCell"
    
    //MARK: - Properties
    weak var delegate: TrackerCellDelegate?
    
    private let trackerStore = TrackerStore()
    private let trackerRecordStore = TrackerRecordStore()
    
    private var tracker: Tracker?
    private var completedTrackerSet = Set<TrackerRecord>()
    private var count = 0
    private var currentDate: Date = Date()
    
    private var cardTrackerView: UIView = {
        let cardTrackerView = UIView()
        cardTrackerView.layer.cornerRadius = 10
        cardTrackerView.clipsToBounds = true
        cardTrackerView.translatesAutoresizingMaskIntoConstraints = false
        return cardTrackerView
    }()
    
    private var quantityManagement: UIView = {
        var quantityManagement = UIView()
        quantityManagement.translatesAutoresizingMaskIntoConstraints = false
        return quantityManagement
    }()
    
    private var titleLabel: UILabel = {
        var titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    
    private var emojiLabel: UILabel = {
        let emojiLabel = UILabel()
        emojiLabel.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        emojiLabel.layer.cornerRadius = 12
        emojiLabel.textAlignment = .center
        emojiLabel.clipsToBounds = true
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        return emojiLabel
    }()
    
    private var daysLabel: UILabel = {
        let daysLabel = UILabel()
        daysLabel.font = UIFont.systemFont(ofSize: 12)
        daysLabel.textColor = .label
        daysLabel.translatesAutoresizingMaskIntoConstraints = false
        return daysLabel
    }()
    
    private lazy var buttonPlus: UIButton = {
        let buttonPlus = UIButton()
        buttonPlus.setImage(UIImage(systemName: "plus"), for: .normal)
        buttonPlus.tintColor = .systemBackground
        buttonPlus.layer.cornerRadius = 17
        buttonPlus.translatesAutoresizingMaskIntoConstraints = false
        buttonPlus.addTarget(self, action: #selector(addCompleted), for: .touchUpInside)
        return buttonPlus
    }()
    
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        addContextMenuToCardTrackerView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Layout Configuration
    
    private func setupLayout() {
        
        //Add views
        contentView.addSubview(cardTrackerView)
        contentView.addSubview(quantityManagement)
        cardTrackerView.addSubview(titleLabel)
        cardTrackerView.addSubview(emojiLabel)
        quantityManagement.addSubview(daysLabel)
        quantityManagement.addSubview(buttonPlus)
        
        //Constraint
        NSLayoutConstraint.activate([
            cardTrackerView.heightAnchor.constraint(equalToConstant: 90),
            cardTrackerView.widthAnchor.constraint(equalToConstant: 167),
            cardTrackerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardTrackerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardTrackerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardTrackerView.bottomAnchor.constraint(equalTo: quantityManagement.topAnchor),
            
            titleLabel.widthAnchor.constraint(equalToConstant: 143),
            titleLabel.heightAnchor.constraint(equalToConstant: 34),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 44),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.leadingAnchor.constraint(equalTo: cardTrackerView.leadingAnchor, constant: 12),
            emojiLabel.topAnchor.constraint(equalTo: cardTrackerView.topAnchor, constant: 12),
            
            quantityManagement.widthAnchor.constraint(equalToConstant: 167),
            quantityManagement.heightAnchor.constraint(equalToConstant: 58),
            quantityManagement.topAnchor.constraint(equalTo: cardTrackerView.bottomAnchor),
            quantityManagement.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            quantityManagement.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            quantityManagement.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            daysLabel.widthAnchor.constraint(equalToConstant: 101),
            daysLabel.heightAnchor.constraint(equalToConstant: 18),
            daysLabel.leadingAnchor.constraint(equalTo: quantityManagement.leadingAnchor, constant: 12),
            daysLabel.topAnchor.constraint(equalTo: quantityManagement.topAnchor, constant: 8),
            daysLabel.bottomAnchor.constraint(equalTo: quantityManagement.bottomAnchor, constant: -16),
            
            buttonPlus.widthAnchor.constraint(equalToConstant: 34),
            buttonPlus.heightAnchor.constraint(equalToConstant: 34),
            buttonPlus.leadingAnchor.constraint(equalTo: daysLabel.trailingAnchor, constant: 8),
            buttonPlus.trailingAnchor.constraint(equalTo: quantityManagement.trailingAnchor, constant: -12),
            buttonPlus.topAnchor.constraint(equalTo: quantityManagement.topAnchor, constant: 8)
        ])
    }
    
    //MARK: - Actions
    
    @objc func addCompleted() {
        guard let tracker = tracker else { return }
        
        if delegate?.isTrackerCompleted(tracker) == true {
            delegate?.trackerCell(self, didRemove: tracker)
        } else {
            delegate?.trackerCell(self, didAdd: tracker)
        }
        
        updateButtonImage()
        count = completedTrackerSet.filter { $0.trackerId == tracker.id }.count
        daysLabel.text = "\(count) \(count.daysEnding())"
    }
    
    private func updateButtonImage() {
        guard let tracker = tracker else { return }
        
        let isCompletedToday = delegate?.isTrackerCompleted(tracker) ?? false
        buttonPlus.setImage(isCompletedToday ? UIImage(systemName: "checkmark") : UIImage(systemName: "plus"), for: .normal)
    }

    private func addContextMenuToCardTrackerView() {
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        cardTrackerView.addInteraction(contextMenuInteraction)
    }

    func configure(with tracker: Tracker, completedTrackers:[TrackerRecord], currentDate: Date) {
        self.currentDate = currentDate
          self.tracker = tracker
          if let coreDataTracker = trackerStore.coreDataFrom(tracker: tracker) {
              let completedTrackers = trackerRecordStore.fetchRecords(for: coreDataTracker)
              self.completedTrackerSet = Set(completedTrackers.map { TrackerRecord(trackerId: $0.tracker?.id ?? UUID(), date: $0.date ?? Date()) })
          }
        
        cardTrackerView.backgroundColor = tracker.color
        quantityManagement.backgroundColor = .systemBackground
        titleLabel.text = tracker.title
        emojiLabel.text = tracker.emoji
        buttonPlus.backgroundColor = tracker.color
        
        count = completedTrackerSet.filter { $0.trackerId == tracker.id }.count
        daysLabel.text = "\(count) \(count.daysEnding())"
        updateButtonImage()
    }
}

extension TrackerCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
            return UIMenu(title: "", children: [
                UIAction(title: "Закрепить", handler: { [self] _ in
                    self.delegate?.trackerCell(self, didTogglePin: tracker!)
                }),
                UIAction(title: "Редактировать", handler: { [self] _ in
                    self.delegate?.trackerCell(self, didRequestEdit: tracker!)
                }),
                UIAction(title: "Удалить", attributes: .destructive, handler: { [self] _ in
                    self.delegate?.trackerCell(self, didDelete: tracker!)
                })
            ])
        })
    }
}
