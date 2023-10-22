import UIKit
import CoreData

protocol TrackerCategoryStoreDelegate: AnyObject {
    func didUpdateData(in store: TrackerCategoryStore)
}

final class TrackerCategoryStore: NSObject {
    
    lazy var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData> = {
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \TrackerCategoryCoreData.title, ascending: true)
        ]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        controller.delegate = self
        do {
            try controller.performFetch()
        } catch let error {
            print(error)
        }
        return controller
    }()
    
    private let context = CoreDataManager.shared.context
    
    weak var delegate: TrackerCategoryStoreDelegate?

    func fetchAllCategories() -> [TrackerCategoryCoreData]? {
        return fetchedResultsController.fetchedObjects
    }
    
    func updateCategory(_ category: TrackerCategoryCoreData, title: String) {
        category.title = title
        CoreDataManager.shared.saveContext()
    }
    
    func deleteCategory(_ category: TrackerCategoryCoreData) {
        context.delete(category)
        CoreDataManager.shared.saveContext()
    }
    
    func trackerCategory(from coreData: TrackerCategoryCoreData) -> TrackerCategory? {
        guard let title = coreData.title else {
            return nil
        }
        
        let trackerStore = TrackerStore()
        
        guard let allObjects = coreData.tracker?.allObjects as? [TrackerCoreData] else {
            return nil
        }
        
        let trackerObjects = allObjects.compactMap {
            trackerStore.tracker(from: $0)
        }
        
        return TrackerCategory(title: title, trackers: trackerObjects)
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateData(in: self)
    }
}

