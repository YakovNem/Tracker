import UIKit

protocol NewCategoryViewControllerDelegate: AnyObject {
    func didCreateNewCategory(_ category: TrackerCategoryCoreData)
}

class NewCategoryViewController: KeyboardHandlingViewController, UITextFieldDelegate {
    
    //MARK: - Properties
    
    var viewModel: NewCategoryViewModel!
    var completionHandler: (() -> Void)?
    
    weak var delegate: NewCategoryViewControllerDelegate?
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Введите название категории", attributes: [NSAttributedString.Key.foregroundColor: Colors.gray])
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
    
    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Готово", for: .normal)
        button.backgroundColor = .black
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapDoneButton), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Новая категория"
        navigationItem.hidesBackButton = true
        navigationController?.view.backgroundColor = .white
        
        textField.delegate = self
        
        viewModel = NewCategoryViewModel(store: TrackerCategoryStore())

        viewModel.didCreateNewCategory = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        viewModel.didFailCreatingNewCategory = { [weak self] error in
            let alertController = UIAlertController(title: "Ошибка", message: "Не удалось создать новую категорию.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alertController, animated: true)
        }
        setupLayout()
        updateDoneButton()
    }
    
    //MARK: - Actions
    
    @objc func didTapDoneButton() {
        if let title = textField.text, !title.isEmpty {
            if let newCategory = viewModel.createNewCategory(with: title) {
                delegate?.didCreateNewCategory(newCategory)
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateDoneButton()
    }
    
    private func updateDoneButton() {
        if textField.text?.isEmpty == true {
            doneButton.backgroundColor = Colors.gray
        } else {
            doneButton.backgroundColor = UIColor(cgColor: Colors.blackDay)
        }
    }
    
    private func setupLayout() {
        view.addSubview(textField)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 75),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            
            doneButton.heightAnchor.constraint(equalToConstant: 60),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
    }
}
