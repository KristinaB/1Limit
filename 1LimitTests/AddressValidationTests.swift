//
//  AddressValidationTests.swift
//  1LimitTests
//
//  Tests for address validation service
//

import XCTest
@testable import _Limit

final class AddressValidationTests: XCTestCase {
    
    var addressValidator: AddressValidationService!
    
    override func setUpWithError() throws {
        addressValidator = AddressValidationService()
    }
    
    override func tearDownWithError() throws {
        addressValidator = nil
    }
    
    // MARK: - Valid Address Tests
    
    func testValidEthereumAddress() {
        let validAddress = "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16"
        let result = addressValidator.validateAddress(validAddress)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedAddress, validAddress.lowercased())
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidAddressWithMixedCase() {
        let mixedCaseAddress = "0x742d35Cc6635C0532925A3b8D0F8dff47E2b4C16"
        let result = addressValidator.validateAddress(mixedCaseAddress)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedAddress, mixedCaseAddress.lowercased())
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidAddressWithWhitespace() {
        let addressWithWhitespace = "  0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16  \n"
        let result = addressValidator.validateAddress(addressWithWhitespace)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedAddress, "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16")
        XCTAssertNil(result.errorMessage)
    }
    
    // MARK: - Invalid Address Tests
    
    func testEmptyAddress() {
        let result = addressValidator.validateAddress("")
        
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.normalizedAddress)
        XCTAssertEqual(result.errorMessage, "Please enter a recipient address")
    }
    
    func testAddressWithoutPrefix() {
        let result = addressValidator.validateAddress("742d35cc6635c0532925a3b8d0f8dff47e2b4c16")
        
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.normalizedAddress)
        XCTAssertEqual(result.errorMessage, "Address must start with '0x'")
    }
    
    func testAddressTooShort() {
        let result = addressValidator.validateAddress("0x742d35cc")
        
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.normalizedAddress)
        XCTAssertEqual(result.errorMessage, "Address must be 42 characters long")
    }
    
    func testAddressTooLong() {
        let result = addressValidator.validateAddress("0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16ABC")
        
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.normalizedAddress)
        XCTAssertEqual(result.errorMessage, "Address must be 42 characters long")
    }
    
    func testAddressWithInvalidCharacters() {
        let result = addressValidator.validateAddress("0x742d35cc6635c0532925a3b8d0f8dff47e2b4g16")
        
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.normalizedAddress)
        XCTAssertEqual(result.errorMessage, "Address contains invalid characters")
    }
    
    func testZeroAddress() {
        let zeroAddress = "0x0000000000000000000000000000000000000000"
        let result = addressValidator.validateAddress(zeroAddress)
        
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.normalizedAddress)
        XCTAssertEqual(result.errorMessage, "Cannot send to zero address")
    }
    
    // MARK: - Quick Validation Tests
    
    func testIsValidEthereumAddress() {
        XCTAssertTrue(addressValidator.isValidEthereumAddress("0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16"))
        XCTAssertFalse(addressValidator.isValidEthereumAddress("invalid"))
        XCTAssertFalse(addressValidator.isValidEthereumAddress(""))
    }
    
    // MARK: - Real Address Tests
    
    func testKnownContractAddresses() {
        // USDC contract on Polygon
        let usdcAddress = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
        let result = addressValidator.validateAddress(usdcAddress)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedAddress, usdcAddress.lowercased())
    }
    
    func testCommonWalletAddresses() {
        // Test various real wallet address formats
        let addresses = [
            "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045", // Vitalik's address
            "0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE"  // Binance hot wallet
        ]
        
        for address in addresses {
            let result = addressValidator.validateAddress(address)
            XCTAssertTrue(result.isValid, "Address \(address) should be valid")
            XCTAssertEqual(result.normalizedAddress, address.lowercased())
        }
    }
}