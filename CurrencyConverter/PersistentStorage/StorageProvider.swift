import Foundation
import CoreData

enum StoreType {
  case inMemory, persisted
}

class StorageProvider {
    
    static var shared = StorageProvider()
    private let coreDateModelFileName = "CurrencyConverterModel"
    let persistentContainer: NSPersistentContainer
    
    init(storeType: StoreType = .persisted) {

        persistentContainer = NSPersistentContainer(name: coreDateModelFileName)
        
        if storeType == .inMemory {
            let description = NSPersistentStoreDescription()
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load with \(error)")
            }
        }
    }
}


// MARK: - Persist Supported Currencies

extension StorageProvider {
    
    func saveSupportedCurrency(currencies: [String]) {
        
        guard !currencies.isEmpty else { return }
        var currencies = currencies
        
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        persistentContainer.performBackgroundTask { context in
            let batchInsert = NSBatchInsertRequest.init(entity: SupportedCurrency.entity()) { (dictionary: NSMutableDictionary) in
                let currency = currencies.removeFirst()
                dictionary["currencyName"] = currency
                return currencies.isEmpty
            }
            
            do {
                try context.execute(batchInsert)
                try self.persistentContainer.viewContext.save()
                print("Successfull  batch insert")
            } catch (let error) {
                print("Failed to batch insert \(error.localizedDescription)")
            }
        }
    }
    
    func getSupportedCurrencyList() -> [SupportedCurrency] {
        let fetchRequest: NSFetchRequest<SupportedCurrency> = SupportedCurrency.fetchRequest()
        
        do {
          return try persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
          print("Failed to fetch movies: \(error)")
          return []
        }
    }
    
    func deleteSuppportedCurrencyList() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SupportedCurrency")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try persistentContainer.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey : objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [persistentContainer.viewContext])
        } catch {
            fatalError("Failed to execute delete request: \(error)")
        }
    }
}


// MARK: - Persist Live Exchange Rates

extension StorageProvider {
    
    func saveExchangeRates(quotes: [String: Double]) {
        
        guard !quotes.isEmpty else { return }
        
        var quotes = quotes
        
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        persistentContainer.performBackgroundTask { context in
            let batchInsert = NSBatchInsertRequest.init(entity: Quote.entity()) { (dictionary: NSMutableDictionary) in
                
                let quote = quotes.popFirst()
                guard let quote = quote else { return true }
                dictionary["currency"] = quote.key
                dictionary["value"] = quote.value

                return quotes.isEmpty
            }
            
            do {
                try context.execute(batchInsert)
                try self.persistentContainer.viewContext.save()
                print("Successfull  batch insert")
            } catch (let error) {
                print("Failed to batch insert \(error.localizedDescription)")
            }
        }
    }
    
    func getStoredExchangeRates() -> [Quote] {
        
        let fetchRequest: NSFetchRequest<Quote> = Quote.fetchRequest()
        
        do {
          return try persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
          print("Failed to fetch movies: \(error)")
          return []
        }
    }
    
    func deleteExchangeRates() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Quote")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try persistentContainer.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey : objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [persistentContainer.viewContext])
        } catch {
            fatalError("Failed to execute delete request: \(error)")
        }
    }
    
}
