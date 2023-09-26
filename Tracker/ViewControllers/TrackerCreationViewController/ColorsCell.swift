import UIKit

final class ColorsCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let colorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        colorView.layer.cornerRadius = 10
        colorView.layer.masksToBounds = true
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(containerView)
        containerView.addSubview(colorView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            
            colorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 3),
            colorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -3),
            colorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 3),
            colorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -3),
        ])
    }

    func configure(with color: UIColor) {
        colorView.backgroundColor = color
    }
}

