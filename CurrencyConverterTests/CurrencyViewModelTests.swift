import XCTest
import CoreData

@testable import CurrencyConverter

class CurrencyViewModelTests: XCTestCase {

    var storageProvider: StorageProvider!
    
    override func setUp() {
        storageProvider = StorageProvider(storeType: .inMemory)
        
    }
    
    override func tearDown() {
        storageProvider = nil
    }

    func testJSONMappingForLiveRatesEndPoint() throws {

        let bundle = Bundle(for: type(of: self))

        guard let url = bundle.url(forResource: "CurrencyLayerAPIResponse", withExtension: "json") else {
            XCTFail("Missing file : CurrencyLayerAPIResponse.json")
            return
        }

        let data = try Data(contentsOf: url)
        let exchageRates: [String:Double] = try JSONDecoder().decode(CurrencyLayerAPIResponse.self, from: data).quotes

        XCTAssertFalse(exchageRates.isEmpty)
    }
    
    func testJSONMappingForSupportedCurrencyEndPoint() throws {

        let bundle = Bundle(for: type(of: self))

        guard let url = bundle.url(forResource: "SupportedCurrenciesResponse", withExtension: "json") else {
            XCTFail("Missing file : SupportedCurrenciesResponse.json")
            return
        }

        let data = try Data(contentsOf: url)
        let allCurrencies: [String] = try JSONDecoder().decode(SupportedCurrencies.self, from: data).currencies?.keys.sorted(by: <) as! [String]

        XCTAssertFalse(allCurrencies.isEmpty)
    }
    
    
    func testPersistentSorageHasNoPersistedSupportedCurrencies() {
        let request: NSFetchRequest<SupportedCurrency> = SupportedCurrency.fetchRequest()
        let context = storageProvider.persistentContainer.viewContext

        do {

            let count = try context.count(for: request)
            XCTAssertEqual(count, 0)

        } catch (let error) {
            XCTFail("Test fail : \(error.localizedDescription)")
        }

    }
    
    func testPersistentSorageHasNoExchangeRates() {
        let request: NSFetchRequest<Quote> = Quote.fetchRequest()
        let context = storageProvider.persistentContainer.viewContext

        do {

            let count = try context.count(for: request)
            XCTAssertEqual(count, 0)

        } catch (let error) {
            XCTFail("Test fail : \(error.localizedDescription)")
        }

    }
    
    func testStorageProviderHasPersistedSupportedCurrencies() {
        let request: NSFetchRequest<SupportedCurrency> = SupportedCurrency.fetchRequest()
        let context = storageProvider.persistentContainer.viewContext

        do {

            let inititalCount = try context.count(for: request)
            XCTAssertEqual(inititalCount, 0)

            storageProvider.saveSupportedCurrency(currencies: currencies)

            let finalCount = try context.count(for: request)
            XCTAssertEqual(finalCount, 5)

        } catch (let error) {
            XCTFail("Test fail : \(error.localizedDescription)")
        }
    }

    func testStorageProviderPersistedExhangeRates() {

        let request: NSFetchRequest<Quote> = Quote.fetchRequest()
        let context = storageProvider.persistentContainer.viewContext

        do {

            let inititalCount = try context.count(for: request)
            XCTAssertEqual(inititalCount, 0)

            storageProvider.saveExchangeRates(quotes: quotes)

            let finalCount = try context.count(for: request)
            XCTAssertEqual(finalCount, 5)

        } catch (let error) {
            XCTFail("Test fail : \(error.localizedDescription)")
        }
    }

}
