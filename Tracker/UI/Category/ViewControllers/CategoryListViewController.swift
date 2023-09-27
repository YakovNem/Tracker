import UIKit

class CategoryListViewController: UIViewController {
    
    // MARK: - Properties
    
    private var tableView: UITableView!
    private var viewModel: CategoryListViewModel!
    private var tableViewHeightConstraint: NSLayoutConstraint!
    
    var categorySelected: ((TrackerCategoryCoreData?) -> Void)?
    var selectedCategory: TrackerCategoryCoreData?
    
    private var tableViewHeight: CGFloat {
        let height = CGFloat(viewModel.numberOfCategories()) * 75.0
        let maxHeight = createCategoryButton.frame.minY - tableView.frame.minY - 20
        return min(height, maxHeight)
    }
    
    private lazy var createCategoryButton: UIButton = {
        let button = UIButton()
        button.setTitle("Добавить категорию", for: .normal)
        button.backgroundColor = UIColor(cgColor: Colors.blackDay)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapCreateCategoryButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "star")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var emptyLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "Привычки и события можно объединить по смыслу"
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchCategories()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = CategoryListViewModel(store: TrackerCategoryStore())
        viewModel.reloadData = { [weak self] in
            self?.tableView.reloadData()
            self?.tableViewHeightConstraint.constant = self?.tableViewHeight ?? 0
            self?.view.layoutIfNeeded()
        }
        navigationItem.title = "Категория"
        navigationItem.hidesBackButton = true
        view.backgroundColor = .white
        
        tableView = createTableView()
        setupLayout()
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: tableViewHeight)
        tableViewHeightConstraint.isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableViewHeightConstraint.constant = tableViewHeight
    }
    
    // MARK: - Actions
    
    @objc func didTapCreateCategoryButton() {
        let newCategoryViewController = NewCategoryViewController()
        newCategoryViewController.completionHandler = { [weak self] in
            self?.viewModel.fetchCategories()
            self?.updateViews()
        }
        navigationController?.pushViewController(newCategoryViewController, animated: true)
    }
    
    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(createCategoryButton)
        view.addSubview(emptyLabel)
        view.addSubview(emptyImageView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            
            createCategoryButton.heightAnchor.constraint(equalToConstant: 60),
            createCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createCategoryButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            
            emptyImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func updateViews() {
        let hasCategories = viewModel.numberOfCategories() > 0
        tableView.isHidden = !hasCategories
        emptyLabel.isHidden = hasCategories
        emptyImageView.isHidden = hasCategories
    }
    
    // MARK: - Helpers
    
    private func createTableView() -> UITableView {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = Colors.backgroundDay
        table.layer.cornerRadius = 16
        table.separatorStyle = .none
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }
}

extension CategoryListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let category = viewModel.category(at: indexPath.row)
        cell.textLabel?.text = category?.title
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        cell.subviews.forEach { subview in
            if subview.tag == 12345 {
                subview.removeFromSuperview()
            }
        }
        
        let numberOfRows = tableView.numberOfRows(inSection: indexPath.section)
        
        if numberOfRows > 1 && indexPath.row < numberOfRows - 1 {
            let separator = UIView(frame: CGRect(x: 16, y: cell.frame.height - 1, width: cell.frame.width - 32, height: 1))
            separator.backgroundColor = UIColor.lightGray
            separator.tag = 12345
            cell.addSubview(separator)
        }
        
        cell.accessoryType = category == selectedCategory ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCategory = viewModel.category(at: indexPath.row)
        categorySelected?(selectedCategory)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.numberOfCategories()
        updateViews()
        return count
    }
}
