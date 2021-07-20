import Foundation
import Combine

enum DataSource {
    case remote
    case local
}

class CurrencyViewModel: ObservableObject {
    
    @Published private(set) var quotes: [String : Double] = [:]
    @Published private(set) var supportedCurrencyList: [String] = []
    @Published private(set) var isLoading = Bool()
    @Published private(set) var dataSource: DataSource = .remote
    @Published private(set) var convertedRates: [String : Double] = [:]
    @Published var baseCurrency = ""
    @Published var amount = ""
    
    let refreshTime : TimeInterval = 30 * 60
    private var cancellable = Set<AnyCancellable>()
    
    init() {
        refresh()
        observeInput()
        observeBaseCurrency()
    }
    
    func observeInput() {
        
        $amount
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] amount in
                
                guard let self = self else { return }
                
                if amount != nil && amount != "" {
                    
                    if (StorageProvider.shared.getStoredExchangeRates().count == 0) {
                        self.fetchRealTimeRate()
                    } else {
                        
                        let rates = StorageProvider.shared.getStoredExchangeRates()
                        self.quotes.removeAll()
                        for rate in rates {
                            self.quotes[rate.currency!] = rate.value
                        }
                    }
                    
                    let baseCurrency = UserDefaults.standard.string(forKey: "baseCurrency")
                    if let baseCurrency = baseCurrency {
                        let keys = self.quotes.keys.sorted()
                        if (keys.contains("USD\(baseCurrency)")) {
                            let pair = self.quotes.first(where: { $0.key.contains("USD\(baseCurrency)") })
                            self.calculateExchangeRate(USDToBaseCurencyRate: pair?.value, amountToConvert: Double(amount)!)
                        }
                    }
                }
            }
            .store(in: &cancellable)
    }
    
    private func observeBaseCurrency() {
        $baseCurrency
            .sink { currency in
                if (self.quotes.keys.contains("USD\(currency)")) {
                    let pair = self.quotes.first(where: { $0.key.contains("USD\(currency)") })
                    self.calculateExchangeRate(USDToBaseCurencyRate: pair?.value)
                }
            }.store(in: &cancellable)
    }
    
    private func calculateExchangeRate(USDToBaseCurencyRate: Double?, amountToConvert: Double = 1) {
        let baseCurrencyToUSD = 1/(USDToBaseCurencyRate!)
        self.quotes.forEach { (key: String, value: Double) in
            let baseCurrencyToOtherExchangeRate = baseCurrencyToUSD * amountToConvert * value
            self.convertedRates[key] = baseCurrencyToOtherExchangeRate
        }
    }
    
    func fetchRealTimeRate() {
        WebService.shared.getRealTimeRates()
            .map { $0 }
            .sink { _ in } receiveValue: { [weak self] response in
                self?.quotes = response.quotes
                StorageProvider.shared.saveExchangeRates(quotes: response.quotes)
            }
            .store(in: &cancellable)
        dataSource = .remote
    }
    
    func fetchSupportedCurrencies() {
        isLoading = true
        
        WebService.shared.getListOfSupportedCurrencies()
            .map { $0.currencies }
            .sink(receiveCompletion: { [weak self] completion in
                
                switch completion {
                
                case .failure(let error):
                    print(error.localizedDescription)
                    self?.isLoading = false
                    break
                    
                case .finished:
                    self?.isLoading = false
                    break
                    
                }
                
            }) { [weak self] currencies in
                
                self?.isLoading = false
                guard let currencies = currencies else {
                    return
                }
                self?.supportedCurrencyList  = currencies.keys.sorted(by: <)
                StorageProvider.shared.saveSupportedCurrency(currencies: currencies.keys.sorted(by: <))
            }
            .store(in: &cancellable)
    }
    
    func refresh() {
        
        guard let storedTime = UserDefaults.standard.value(forKey: "preferenceTime") as? Date else {
            fetchFromRemote()
            return
        }
        
        let thirtyMinutesAfterStoredTime = storedTime.addingTimeInterval(refreshTime)
        let currentTime = Date()
        
        if currentTime > thirtyMinutesAfterStoredTime {
            fetchFromRemote()
        } else {
            fetchFromLocalStorage()
        }
    }
    
    private func fetchFromRemote() {
        fetchSupportedCurrencies()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.fetchRealTimeRate()
        }
        dataSource = .remote
        saveCurrentTime()
    }
    
    private func fetchFromLocalStorage() {
        isLoading = true
        dataSource = .local
        let currencies = StorageProvider.shared.getSupportedCurrencyList()
        supportedCurrencyList.removeAll()
        currencies.forEach { currency in
            supportedCurrencyList.append(currency.currencyName!)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    private func saveCurrentTime() {
        UserDefaults.standard.set(Date(), forKey: "preferenceTime")
    }
}
