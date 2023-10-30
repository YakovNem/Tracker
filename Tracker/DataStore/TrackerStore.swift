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
    private let context = CoreDataManager.shared.context
    
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
    
    weak var delegate: TrackerStoreDelegate?
    
    var allTrackers: [TrackerCoreData] {
        return fetchedResultsController.fetchedObjects ?? []
    }
    
    func createTracker(tracker: Tracker, category: TrackerCategory, type: TrackerType) throws -> TrackerCoreData? {
        let newTracker = TrackerCoreData(context: context)
        newTracker.id = tracker.id
        newTracker.title = tracker.title
        newTracker.emoji = tracker.emoji
        newTracker.color = uIColorMarshalling.hexString(from: tracker.color)
        newTracker.schedule = tracker.schedule?.toString()
        newTracker.type = type.rawValue
        
        
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
        CoreDataManager.shared.saveContext()
    }
    
    func tracker(from coreData: TrackerCoreData) -> Tracker? {
        guard
            let id = coreData.id,
            let title = coreData.title,
            let emoji = coreData.emoji,
            let colorString = coreData.color,
            let color = UIColorMarshalling().color(from: colorString),
            let scheduleString = coreData.schedule,
            let schedule = scheduleString.toWeekDays(),
            let typeString = coreData.type,
            let type = TrackerType(rawValue: typeString)
        else {
            return nil
        }

        return Tracker(id: id, title: title, color: color, emoji: emoji, schedule: schedule, type: type, isPinned: coreData.isPinned)
    }
    
    func coreDataFrom(tracker: Tracker) -> TrackerCoreData? {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            return fetchedResults.first
        } catch let error {
            print("Error fetching TrackerCoreData: \(error)")
            return nil
        }
    }
    
    func updateFetchRequest(forDate date: Date) {
        var predicates: [NSPredicate] = []
        
        if let dayOfWeek = date.dayOfWeek() {
            let habitPredicate = NSPredicate(format: "type == %@ AND schedule CONTAINS %@", TrackerType.habit.rawValue, "\(dayOfWeek)")
            let irregularPredicate = NSPredicate(format: "type == %@", TrackerType.irregularEvent.rawValue)
            predicates = [habitPredicate, irregularPredicate]
        } else {
            return
        }
        
        fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "isPinned", ascending: false)]
        
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
    
    func updateTracker(originalTracker: Tracker, updatedTracker: Tracker) {
        guard let coreDataTracker = coreDataFrom(tracker: originalTracker) else { return }
        
        coreDataTracker.title = updatedTracker.title
        coreDataTracker.emoji = updatedTracker.emoji
        coreDataTracker.color = uIColorMarshalling.hexString(from: updatedTracker.color)
        coreDataTracker.schedule = updatedTracker.schedule?.toString()
        coreDataTracker.type = updatedTracker.type.rawValue
        do {
            try context.save()
            print("Tracker updated successfully: \(coreDataTracker)")
        } catch let error {
            print("Failed to update Tracker: \(error.localizedDescription)")
        }
    }
    
    func pinTracker(tracker: Tracker) {
        // Проверяем, существует ли категория "Закрепленные"
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", "Закрепленные")

        let categories = try? context.fetch(fetchRequest)
        let pinnedCategory: TrackerCategoryCoreData

        if let existingCategory = categories?.first {
            pinnedCategory = existingCategory
        } else {
            pinnedCategory = TrackerCategoryCoreData(context: context)
            pinnedCategory.title = "Закрепленные"
        }

        guard let coreDataTracker = coreDataFrom(tracker: tracker) else { return }
        coreDataTracker.isPinned = true

        // Добавляем трекер в категорию "Закрепленные"
        pinnedCategory.addToTracker(coreDataTracker)

        // Сохраняем изменения
        CoreDataManager.shared.saveContext()
    }

}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateData(in: self)
    }
}
extension TrackerStore {
    
    func category(for tracker: Tracker) -> TrackerCategory? {
        guard let coreDataTracker = coreDataFrom(tracker: tracker) else { return nil }
        guard let trackerCategoryCoreData = coreDataTracker.trackerCategory else { return nil }
        
        return TrackerCategory(title: trackerCategoryCoreData.title ?? "", trackers: [])
    }
}
