import UIKit

class ItemsCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var emoji: [String] = ["🙂", "😻", "🌺", "🐶", "❤️", "😱", "😇", "😡", "🥶", "🤔", "🙌", "🍔", "🥦", "🏓", "🥇", "🎸", "🏝", "😪"]
    
    var colors: [UIColor] = [ ColorsSelection.selectionOne,ColorsSelection.selectionTwo, ColorsSelection.selectionThree, ColorsSelection.selectionFour, ColorsSelection.selectionFive, ColorsSelection.selectionSix, ColorsSelection.selectionSeven, ColorsSelection.selectionEight, ColorsSelection.selectionNine, ColorsSelection.selectionTen, ColorsSelection.selectionEleven, ColorsSelection.selectionTwelve, ColorsSelection.selectionThirteen, ColorsSelection.selectionFourteen, ColorsSelection.selectionFifteen, ColorsSelection.selectionSixteen, ColorsSelection.selectionSeventeen, ColorsSelection.selectionEighteen]
    
     var selectedEmojiIndex: IndexPath?
     var selectedColorIndex: IndexPath?
    
    init() {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        
        self.dataSource = self
        self.delegate = self
        self.register(EmojiCell.self, forCellWithReuseIdentifier: "emojiCell")
        self.register(ColorsCell.self, forCellWithReuseIdentifier: "colorsCell")
        self.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        self.backgroundColor = .white
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isScrollEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return emoji.count
        } else {
            return colors.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let previousSelectedEmojiIndex = selectedEmojiIndex
            selectedEmojiIndex = indexPath
            if let previous = previousSelectedEmojiIndex {
                collectionView.reloadItems(at: [previous])
            }
        } else {
            let previousSelectedColorIndex = selectedColorIndex
            selectedColorIndex = indexPath
            if let previous = previousSelectedColorIndex {
                collectionView.reloadItems(at: [previous])
            }
        }
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojiCell", for: indexPath) as! EmojiCell
            cell.emojiLabel.text = emoji[indexPath.item]
            
            if let selectedIndex = selectedEmojiIndex, selectedIndex == indexPath {
                cell.backgroundColor = UIColor(cgColor: Colors.lightGray)
                cell.layer.cornerRadius = 16
            } else {
                cell.backgroundColor = .white
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorsCell", for: indexPath) as! ColorsCell
            cell.configure(with: colors[indexPath.item])
            
            if let selectedIndex = selectedColorIndex, selectedIndex == indexPath {
                cell.contentView.layer.borderWidth = 2.0
                cell.contentView.layer.cornerRadius = 10
                cell.contentView.layer.borderColor = colors[indexPath.item].cgColor
                cell.contentView.layer.borderColor = colors[indexPath.item].withAlphaComponent(0.5).cgColor
            } else {
                cell.layer.borderWidth = 0.0
            }
            return cell
        }
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: header.bounds.width - 20, height: header.bounds.height))
        label.font = UIFont.boldSystemFont(ofSize: 20)
        
        if indexPath.section == 0 {
            label.text = "Emoji"
        } else {
            label.text = "Цвет"
        }
        
        header.addSubview(label)
        return header
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
           5
       }

       func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
           9
       }
   }

