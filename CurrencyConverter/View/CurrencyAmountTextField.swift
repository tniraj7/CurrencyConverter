import SwiftUI

struct CurrencyAmountTextField: View {
    
    @Binding var amount: String
    let textFieldHint: String = "Input amount"
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            TextField(textFieldHint, text: $amount)
                .accessibility(identifier: "amountTextField")
                .padding(.leading, 30)
                .keyboardType(.numberPad)
        }
        .padding(.all, 10)
        .background(Color(.systemGray5))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
