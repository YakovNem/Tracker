import UIKit

class CategoryCell: UITableViewCell {
    
    //MARK: - Properties
    
    static let identifier = "CategoryCell"
    private var separator: UIView!
    
    //MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Actions
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        separator = UIView()
        separator.backgroundColor = UIColor.lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func configure(with category: TrackerCategoryCoreData?, isSelected: Bool, isLastCell: Bool) {
        textLabel?.text = category?.title
        accessoryType = isSelected ? .checkmark : .none
        separator.isHidden = isLastCell
    }
}
