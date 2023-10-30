import UIKit
import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func didUpdateData(in store: TrackerRecordStore)
}

final class TrackerRecordStore: NSObject {
    
    lazy var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let fetchRequest = TrackerRecordCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: true)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        
        controller.delegate = self
        
        do {
            try controller.performFetch()
        } catch {
            print("Failed to fetch TrackerRecords: \(error)")
        }
        
        return controller
    }()
    
    weak var delegate: TrackerRecordStoreDelegate?
    
    private let context = CoreDataManager.shared.context
    
    var allRecords: [TrackerRecordCoreData] {
        return fetchedResultsController.fetchedObjects ?? []
    }
    
    func createRecord(for tracker: TrackerCoreData, date: Date) -> TrackerRecordCoreData? {
        let newRecord = TrackerRecordCoreData(context: context)
        newRecord.date = date
        newRecord.tracker = tracker
        
        CoreDataManager.shared.saveContext()
        return newRecord
    }
    
    
    func fetchRecords(for tracker: TrackerCoreData) -> [TrackerRecordCoreData] {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker == %@", tracker)
        
        do {
            return try context.fetch(request)
        } catch let error {
            print("Failed to fetch TrackerRecords for tracker: \(error.localizedDescription)")
            return []
        }
    }
    
    func updateRecord(_ record: TrackerRecordCoreData, withDate date: Date) {
        record.date = date
        CoreDataManager.shared.saveContext()
    }
    
    func deleteRecord(_ record: TrackerRecordCoreData) {
        context.delete(record)
        CoreDataManager.shared.saveContext()
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateData(in: self)
    }
    
    func countOfAllCompletedTrackers() -> Int {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        do {
            return try context.count(for: request)
        } catch {
            print("Error fetching all completed trackers: \(error)")
            return 0
        }
    }
    
}

extension TrackerRecordStore {
    
    func countOfCompletedDays(for tracker: TrackerCoreData) -> Int {
        let records = fetchRecords(for: tracker)
        
        var uniqueDays = Set<String>()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        for record in records {
            if let date = record.date {
                let dayString = dateFormatter.string(from: date)
                uniqueDays.insert(dayString)
            }
        }
        
        return uniqueDays.count
    }
}
