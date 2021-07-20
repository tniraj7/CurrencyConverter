import SwiftUI
import Combine

struct CurrencyView: View {
    
    @StateObject var viewModel = CurrencyViewModel()
    @State var amount = ""
    @State var baseCurrency = UserDefaults.standard.string(forKey: "baseCurrency")
    
    func getExchangeRateForCurrency(currency: String) -> String {
        var result = String()
        let rate = viewModel.convertedRates.first(where: { $0.key.contains(("USD\(currency)")) })
        if let exchangeRate = rate?.value {
            result = "\(exchangeRate)"
        }
        return result
    }
    
    var body: some View {
        
        NavigationView {
            
            if viewModel.isLoading {
                
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.1)
                    
                    Text((viewModel.dataSource == .remote) ? "Loading from remote" : "Loading from disk")
                        .padding(.leading, 10)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)
                
            } else {
                VStack {
                    HStack {
                        if baseCurrency == "" {
                           Text("...")
                                .font(.title)
                                .padding(.leading, 16)
                        } else if (baseCurrency != nil) {
                            Text(baseCurrency!)
                                .accessibility(identifier: "selectedBaseCurrency")
                                .font(.title)
                                .padding(.all, 10)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        CurrencyAmountTextField(amount: $viewModel.amount)
                    }
                    
                    List(viewModel.supportedCurrencyList, id: \.self) { item in
                        HStack {
                            Text(item)
                            
                            Spacer()
                            
                            Text(getExchangeRateForCurrency(currency: item))
                                .accessibility(identifier: "convertedAmount")
                        }
                        .padding(.horizontal, 16)
                    }
                    .accessibility(identifier: "currencyList")
                }
                .toolbar(content: {
                    Menu("Choose Currency") {
                        ForEach(viewModel.supportedCurrencyList, id: \.self) { (currency) in
                            
                            Button(action: {
                                viewModel.refresh()
                                self.baseCurrency = currency
                                viewModel.baseCurrency = currency
                                UserDefaults.standard.set(currency as String, forKey: "baseCurrency")
                            }, label: {
                                HStack {
                                    Text("\(currency)")
                                    Spacer()
                                    if (viewModel.baseCurrency == currency) {
                                        
                                        Image(systemName: "checkmark")
                                    }
                                }
                            })
                            
                        }
                    }.accessibility(identifier: "selectCurrencyMenu")
                    
                })
                .navigationTitle("Currency Converter")
            }
        }
    }
}
