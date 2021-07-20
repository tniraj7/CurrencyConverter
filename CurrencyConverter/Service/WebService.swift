import Foundation
import Combine

class WebService {
    
    static let shared = WebService()
    private init() {}
    
    var baseURL = "http://api.currencylayer.com/"
    var apiKey = "?access_key=7dc8f4eb8a8eee89a7f9628f6bbeb1c8"
    
    enum endpoint: String {
        case list = "list"
        case realtime = "live"
    }
    
    
    func getRealTimeRates() -> AnyPublisher<CurrencyLayerAPIResponse, Error>  {
        let urlString = baseURL + endpoint.realtime.rawValue + apiKey
        return NetworkManager.shared.makeHttpRequest(for: urlString)
    }
    
    func getListOfSupportedCurrencies() -> AnyPublisher<SupportedCurrencies, Error> {
        let urlString = baseURL + endpoint.list.rawValue + apiKey
        return NetworkManager.shared.makeHttpRequest(for: urlString)
    }
}
