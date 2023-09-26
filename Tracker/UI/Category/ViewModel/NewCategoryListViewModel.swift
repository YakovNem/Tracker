import Foundation

class NewCategoryViewModel {

    private let categoryStore: TrackerCategoryStore

    var didCreateNewCategory: (() -> Void)?
    var didFailCreatingNewCategory: ((Error) -> Void)?

    init(store: TrackerCategoryStore) {
        self.categoryStore = store
    }

    func createNewCategory(with title: String) -> TrackerCategoryCoreData? {
        let context = CoreDataManager.shared.context
        let newCategory = TrackerCategoryCoreData(context: context)
        newCategory.title = title
        do {
            try context.save()
            didCreateNewCategory?()
            return newCategory
        } catch {
            didFailCreatingNewCategory?(error)
            return nil
        }
    }
}
