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

    private let context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    
    var allRecords: [TrackerRecordCoreData] {
        return fetchedResultsController.fetchedObjects ?? []
    }
    
    func createRecord(for tracker: TrackerCoreData, date: Date) -> TrackerRecordCoreData? {
        let newRecord = TrackerRecordCoreData(context: context)
        newRecord.date = date
        newRecord.tracker = tracker
        
        saveContext()
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
        saveContext()
    }
    
    func deleteRecord(_ record: TrackerRecordCoreData) {
        context.delete(record)
        saveContext()
    }

    func saveContext() {
        do {
            try context.save()
        } catch let error {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateData(in: self)
    }
}


