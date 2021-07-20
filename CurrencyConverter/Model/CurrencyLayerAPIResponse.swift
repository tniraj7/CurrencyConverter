import Foundation

struct CurrencyLayerAPIResponse: Codable {
    let timestamp: Int
    let quotes: [String: Double]
}
