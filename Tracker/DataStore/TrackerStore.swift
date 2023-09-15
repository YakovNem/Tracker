import UIKit
import CoreData

protocol TrackerStoreDelegate: AnyObject {
    func didUpdateData(in store: TrackerStore)
}

enum TrackerStoreError: Error {
    case decodingError
}

final class TrackerStore: NSObject {
    
    private let uIColorMarshalling = UIColorMarshalling()
    
     lazy var fetchedResultsController: NSFetchedResultsController<TrackerCoreData> = {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerCoreData.schedule,
                                                         ascending: true)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: "trackerCategory", cacheName: nil)
        controller.delegate = self
        
        do {
            try controller.performFetch()
        } catch let error {
            print("Failed to fetch Tracker: \(error)")
        }
        
        return controller
    }()
    
    private let context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    weak var delegate: TrackerStoreDelegate?

    var allTrackers: [TrackerCoreData] {
        return fetchedResultsController.fetchedObjects ?? []
    }

    func createTracker(tracker: Tracker, category: TrackerCategory) throws -> TrackerCoreData? {
        let newTracker = TrackerCoreData(context: context)
        newTracker.id = tracker.id
        newTracker.title = tracker.title
        newTracker.emoji = tracker.emoji
        newTracker.color = uIColorMarshalling.hexString(from: tracker.color)
        newTracker.schedule = tracker.schedule?.toString()

        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", category.title)

        let categories = try? context.fetch(fetchRequest)
        let trackerCategory: TrackerCategoryCoreData

        if let existingCategory = categories?.first {
            trackerCategory = existingCategory
        } else {
            trackerCategory = TrackerCategoryCoreData(context: context)
            trackerCategory.title = category.title
        }

        trackerCategory.addToTracker(newTracker)

        do {
            try context.save()
            print("Tracker saved successfully: \(newTracker)")
            return newTracker
        } catch let error {
            print("Failed to create Tracker: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchAllTrackers() -> [TrackerCoreData]? {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        
        do {
            let fetched = try context.fetch(request)
            return fetched
        } catch let error {
            print("Failed to fetch Trackers: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteTracker(tracker: TrackerCoreData) {
        context.delete(tracker)
        do {
            try context.save()
        } catch let error {
            print("Failed to delete Tracker: \(error.localizedDescription)")
        }
    }
    
    func tracker(from coreData: TrackerCoreData) -> Tracker? {
        guard
            let id = coreData.id,
            let title = coreData.title,
            let emoji = coreData.emoji,
            let colorString = coreData.color,
            let color = UIColorMarshalling().color(from: colorString),
            let scheduleString = coreData.schedule,
            let schedule = scheduleString.toWeekDays()
        else {
            return nil
        }
        
        return Tracker(id: id, title: title, color: color, emoji: emoji, schedule: schedule)
    }
    
    func updateFetchRequest(forDate date: Date) {
            guard let dayOfWeek = date.dayOfWeek() else { return }
            let predicate = NSPredicate(format: "schedule CONTAINS %@", "\(dayOfWeek)")
            fetchedResultsController.fetchRequest.predicate = predicate
            do {
                try fetchedResultsController.performFetch()
            } catch let error {
                print("Failed to update fetch request for date: \(error)")
            }
            delegate?.didUpdateData(in: self)
        }
    
    func updateSearchPredicate(with searchText: String?) {
        var predicates: [NSPredicate] = []

        if let searchText = searchText, !searchText.isEmpty {
            let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
            predicates.append(titlePredicate)
        }

        fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print("Failed to update fetch request for search: \(error)")
        }
        delegate?.didUpdateData(in: self)
    }

}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateData(in: self)
    }
}
