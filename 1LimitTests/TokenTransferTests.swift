//
//  TokenTransferTests.swift
//  1LimitTests
//
//  Tests for token transfer service and models
//

import XCTest
@testable import _Limit

final class TokenTransferTests: XCTestCase {
    
    var transferService: MockTokenTransferService!
    
    override func setUpWithError() throws {
        transferService = MockTokenTransferService()
    }
    
    override func tearDownWithError() throws {
        transferService = nil
    }
    
    // MARK: - TransferableToken Tests
    
    func testMaticTokenCreation() {
        let maticToken = TransferableToken.matic(
            balance: "1.5",
            balanceFormatted: "1.50",
            usdValue: "$1.28"
        )
        
        XCTAssertEqual(maticToken.symbol, "MATIC")
        XCTAssertEqual(maticToken.name, "Polygon")
        XCTAssertNil(maticToken.contractAddress)
        XCTAssertEqual(maticToken.decimals, 18)
        XCTAssertTrue(maticToken.isNative)
        XCTAssertEqual(maticToken.displayName, "MATIC (Polygon)")
        XCTAssertNil(maticToken.displayAddress)
    }
    
    func testERC20TokenCreation() {
        let usdcToken = TransferableToken.erc20(
            symbol: "USDC",
            name: "USD Coin",
            contractAddress: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
            decimals: 6,
            balance: "100.0",
            balanceFormatted: "100.00",
            usdValue: "$100.00"
        )
        
        XCTAssertEqual(usdcToken.symbol, "USDC")
        XCTAssertEqual(usdcToken.name, "USD Coin")
        XCTAssertEqual(usdcToken.contractAddress, "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359")
        XCTAssertEqual(usdcToken.decimals, 6)
        XCTAssertFalse(usdcToken.isNative)
        XCTAssertEqual(usdcToken.displayName, "USDC (USD Coin)")
        XCTAssertEqual(usdcToken.displayAddress, "0x3c49...3359")
    }
    
    func testTokenEquality() {
        let token1 = TransferableToken.matic(balance: "1.0", balanceFormatted: "1.00", usdValue: "$0.85")
        let token2 = TransferableToken.matic(balance: "2.0", balanceFormatted: "2.00", usdValue: "$1.70")
        
        // Tokens should be equal if all properties match (except id which is UUID)
        XCTAssertNotEqual(token1.id, token2.id) // IDs are different UUIDs
        
        // Create identical tokens (except UUID)
        let token3 = TransferableToken.matic(balance: "1.0", balanceFormatted: "1.00", usdValue: "$0.85")
        let token4 = TransferableToken.matic(balance: "1.0", balanceFormatted: "1.00", usdValue: "$0.85")
        
        // They should be equal in content but have different IDs
        XCTAssertNotEqual(token3.id, token4.id)
        XCTAssertEqual(token3.symbol, token4.symbol)
        XCTAssertEqual(token3.balance, token4.balance)
    }
    
    // MARK: - SendTransaction Tests
    
    func testSendTransactionCreation() {
        let token = TransferableToken.matic(balance: "5.0", balanceFormatted: "5.00", usdValue: "$4.25")
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: token,
            amount: "1.5",
            amountWei: "1500000000000000000",
            gasEstimate: "0.002",
            gasCostUSD: "$0.0034"
        )
        
        XCTAssertEqual(transaction.fromAddress, "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16")
        XCTAssertEqual(transaction.toAddress, "0x1234567890123456789012345678901234567890")
        XCTAssertEqual(transaction.amount, "1.5")
        XCTAssertEqual(transaction.amountWei, "1500000000000000000")
        XCTAssertEqual(transaction.gasEstimate, "0.002")
        XCTAssertEqual(transaction.gasCostUSD, "$0.0034")
    }
    
    func testTotalCostCalculationForNativeToken() {
        let maticToken = TransferableToken.matic(balance: "5.0", balanceFormatted: "5.00", usdValue: "$4.25")
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: maticToken,
            amount: "1.5",
            amountWei: "1500000000000000000",
            gasEstimate: "0.002",
            gasCostUSD: "$0.0034"
        )
        
        XCTAssertEqual(transaction.totalCostFormatted, "1.502000 MATIC")
    }
    
    func testTotalCostCalculationForERC20Token() {
        let usdcToken = TransferableToken.erc20(
            symbol: "USDC",
            name: "USD Coin",
            contractAddress: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
            decimals: 6,
            balance: "100.0",
            balanceFormatted: "100.00",
            usdValue: "$100.00"
        )
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: usdcToken,
            amount: "50.0",
            amountWei: "50000000",
            gasEstimate: "0.003",
            gasCostUSD: "$0.0051"
        )
        
        // ERC-20 tokens don't include gas in total cost (gas is paid in MATIC)
        XCTAssertNil(transaction.totalCostFormatted)
    }
    
    // MARK: - Gas Estimation Tests
    
    @MainActor
    func testGasEstimationForNativeTransfer() async throws {
        let maticToken = TransferableToken.matic(balance: "5.0", balanceFormatted: "5.00", usdValue: "$4.25")
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: maticToken,
            amount: "1.0",
            amountWei: "1000000000000000000",
            gasEstimate: nil,
            gasCostUSD: nil
        )
        
        transferService.shouldSucceed = true
        transferService.gasEstimateDelay = 0.1
        
        let result = try await transferService.estimateGas(for: transaction)
        
        XCTAssertEqual(result.gasEstimate, "0.002")
        XCTAssertEqual(result.gasCostUSD, "$0.0034")
        XCTAssertEqual(result.gasLimit, "21000")
        XCTAssertEqual(result.gasPrice, "30.0")
    }
    
    @MainActor
    func testGasEstimationForERC20Transfer() async throws {
        let usdcToken = TransferableToken.erc20(
            symbol: "USDC",
            name: "USD Coin",
            contractAddress: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
            decimals: 6,
            balance: "100.0",
            balanceFormatted: "100.00",
            usdValue: "$100.00"
        )
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: usdcToken,
            amount: "50.0",
            amountWei: "50000000",
            gasEstimate: nil,
            gasCostUSD: nil
        )
        
        transferService.shouldSucceed = true
        transferService.gasEstimateDelay = 0.1
        
        let result = try await transferService.estimateGas(for: transaction)
        
        XCTAssertEqual(result.gasEstimate, "0.002")
        XCTAssertEqual(result.gasCostUSD, "$0.0034")
        XCTAssertEqual(result.gasLimit, "65000") // Higher gas limit for ERC-20
        XCTAssertEqual(result.gasPrice, "30.0")
    }
    
    @MainActor
    func testGasEstimationFailure() async {
        let maticToken = TransferableToken.matic(balance: "5.0", balanceFormatted: "5.00", usdValue: "$4.25")
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: maticToken,
            amount: "1.0",
            amountWei: "1000000000000000000",
            gasEstimate: nil,
            gasCostUSD: nil
        )
        
        transferService.shouldSucceed = false
        transferService.gasEstimateDelay = 0.1
        
        do {
            _ = try await transferService.estimateGas(for: transaction)
            XCTFail("Expected gas estimation to fail")
        } catch let error as TransferError {
            switch error {
            case .networkError(let message):
                XCTAssertEqual(message, "Mock gas estimation failed")
            default:
                XCTFail("Expected networkError, got \(error)")
            }
        }
    }
    
    // MARK: - Transfer Execution Tests
    
    @MainActor
    func testSuccessfulNativeTransfer() async throws {
        let maticToken = TransferableToken.matic(balance: "5.0", balanceFormatted: "5.00", usdValue: "$4.25")
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: maticToken,
            amount: "1.0",
            amountWei: "1000000000000000000",
            gasEstimate: "0.002",
            gasCostUSD: "$0.0034"
        )
        
        transferService.shouldSucceed = true
        transferService.transferDelay = 0.1
        
        let success = try await transferService.executeSend(transaction)
        
        XCTAssertTrue(success)
    }
    
    @MainActor
    func testSuccessfulERC20Transfer() async throws {
        let usdcToken = TransferableToken.erc20(
            symbol: "USDC",
            name: "USD Coin",
            contractAddress: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
            decimals: 6,
            balance: "100.0",
            balanceFormatted: "100.00",
            usdValue: "$100.00"
        )
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: usdcToken,
            amount: "50.0",
            amountWei: "50000000",
            gasEstimate: "0.003",
            gasCostUSD: "$0.0051"
        )
        
        transferService.shouldSucceed = true
        transferService.transferDelay = 0.1
        
        let success = try await transferService.executeSend(transaction)
        
        XCTAssertTrue(success)
    }
    
    @MainActor
    func testFailedTransfer() async {
        let maticToken = TransferableToken.matic(balance: "5.0", balanceFormatted: "5.00", usdValue: "$4.25")
        
        let transaction = SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: maticToken,
            amount: "1.0",
            amountWei: "1000000000000000000",
            gasEstimate: "0.002",
            gasCostUSD: "$0.0034"
        )
        
        transferService.shouldSucceed = false
        transferService.transferDelay = 0.1
        
        do {
            _ = try await transferService.executeSend(transaction)
            XCTFail("Expected transfer to fail")
        } catch let error as TransferError {
            switch error {
            case .transactionFailed(let message):
                XCTAssertEqual(message, "Mock transfer failed")
            default:
                XCTFail("Expected transactionFailed, got \(error)")
            }
        }
    }
    
    // MARK: - Transfer Error Tests
    
    func testTransferErrorDescriptions() {
        XCTAssertEqual(TransferError.noWallet.localizedDescription, "No wallet available")
        XCTAssertEqual(TransferError.insufficientBalance.localizedDescription, "Insufficient balance for transfer")
        XCTAssertEqual(TransferError.invalidAmount.localizedDescription, "Invalid transfer amount")
        XCTAssertEqual(TransferError.missingContractAddress.localizedDescription, "Token contract address not found")
        XCTAssertEqual(TransferError.gasPriceUnavailable.localizedDescription, "Could not get current gas price")
        XCTAssertEqual(TransferError.networkError("test").localizedDescription, "Network error: test")
        XCTAssertEqual(TransferError.transactionFailed("test").localizedDescription, "Transaction failed: test")
    }
}