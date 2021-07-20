import XCTest

class CurrencyConverterUITests: XCTestCase {

    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testSelectBaseCurrency() throws {

        let chooseCurrencyButton = app.buttons["selectCurrencyMenu"]
        chooseCurrencyButton.tap()
        
        let buttonAustralianDollar = app.buttons["AED"]
        buttonAustralianDollar.tap()

        let text = app.staticTexts["selectedBaseCurrency"].firstMatch
        XCTAssertTrue(text.label == "AED", "Base Currency was selected successfully")

    }
    
    func testUserTypedInputAmountToConvertAUD() {
        
        let chooseCurrencyButton = app.buttons["selectCurrencyMenu"]
        chooseCurrencyButton.tap()

        let buttonAustralianDollar = app.buttons["AUD"]
        buttonAustralianDollar.tap()

        let text = app.staticTexts["selectedBaseCurrency"].firstMatch
        XCTAssertTrue(text.label == "AUD", "Base Currency was selected successfully")
        
        let textField = app.textFields["amountTextField"].firstMatch
        textField.tap()
        textField.typeText("100")
        
        
        let exp = expectation(description: "Wait for debounce period to get result")
        let result = XCTWaiter.wait(for: [exp], timeout: 5.0)
        
        if result == XCTWaiter.Result.timedOut {
            
            let table = app.tables["currencyList"].firstMatch
            let cellAED = table.cells.staticTexts["convertedAmount"].firstMatch
            let cellAmountValue = cellAED.label
            let convertedValue = "269.7061145070397"
            
            XCTAssertTrue(cellAmountValue == convertedValue, "User typed and got the converted rate")
        } else {
            XCTFail("Conversion failed")
        }
    }

}
