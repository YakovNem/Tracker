import Foundation

class CategoryListViewModel {

    private var categoryStore: TrackerCategoryStore
    private var categories: [TrackerCategoryCoreData] = []

    var reloadData: (() -> Void)?

    init(store: TrackerCategoryStore) {
        self.categoryStore = store
        self.categoryStore.delegate = self
        fetchCategories()
    }

    func fetchCategories() {
        self.categories = categoryStore.fetchAllCategories() ?? []
        self.reloadData?()
    }

    
    func numberOfCategories() -> Int {
        return categories.count
    }

    func category(at index: Int) -> TrackerCategoryCoreData? {
        guard index >= 0 && index < categories.count else { return nil }
        return categories[index]
    }

    func deleteCategory(at index: Int) {
        guard let category = category(at: index) else { return }
        categoryStore.deleteCategory(category)
        fetchCategories()
    }

    func updateCategory(at index: Int, with title: String) {
        guard let category = category(at: index) else { return }
        categoryStore.updateCategory(category, title: title)
        fetchCategories()
    }
}

extension CategoryListViewModel: TrackerCategoryStoreDelegate {
    func didUpdateData(in store: TrackerCategoryStore) {
        fetchCategories()
    }
}

