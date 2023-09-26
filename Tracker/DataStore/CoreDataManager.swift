import UIKit
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    var context: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    private init() {}
    
    func saveContext() {
        do {
            try context.save()
        } catch let error {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}
