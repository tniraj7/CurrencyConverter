import Foundation
import Combine

class NetworkManager {
    
    static let shared = NetworkManager()
    
    enum APIError: Error {
        case networkErrors(error: String)
        case responseError(error: String)
        case unknownError
    }
    
    private init() {}
    
    func makeHttpRequest<T: Decodable>(for url: String) -> AnyPublisher<T, Error> {
        
        guard let url = URL(string: url) else {
            fatalError("Bad url")
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "GET"
        request.addValue("Content-Type", forHTTPHeaderField: "application/json")
        
        let decoder = JSONDecoder()

        let publisher = URLSession.shared.dataTaskPublisher(for: request)
            .receive(on: RunLoop.main)
            .map { $0.data }
            .mapError { error -> Error in
                switch error {
                
                case URLError.cannotFindHost:
                    return APIError.networkErrors(error:"Cannot find host url")
                    
                case URLError.badURL:
                    return APIError.networkErrors(error:"Bad url")
                    
                default:
                    return APIError.responseError(error: error.localizedDescription)
                }
            }
            .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
        
        return publisher
    }
}
