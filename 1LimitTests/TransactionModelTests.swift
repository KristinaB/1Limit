//
//  TransactionModelTests.swift
//  1LimitTests
//
//  Unit tests for Transaction model and related functionality
//

import XCTest
@testable import _Limit

final class TransactionModelTests: XCTestCase {
    
    // MARK: - Transaction Model Tests
    
    func testTransactionInitialization() {
        // Given
        let id = UUID()
        let type = "Limit Order"
        let fromAmount = "100.0"
        let fromToken = "WMATIC"
        let toAmount = "85.5"
        let toToken = "USDC"
        let limitPrice = "0.855"
        let status = TransactionStatus.pending
        let txHash = "0x1234567890abcdef"
        
        // When
        let transaction = Transaction(
            id: id,
            type: type,
            fromAmount: fromAmount,
            fromToken: fromToken,
            toAmount: toAmount,
            toToken: toToken,
            limitPrice: limitPrice,
            status: status,
            txHash: txHash
        )
        
        // Then
        XCTAssertEqual(transaction.id, id)
        XCTAssertEqual(transaction.type, type)
        XCTAssertEqual(transaction.fromAmount, fromAmount)
        XCTAssertEqual(transaction.fromToken, fromToken)
        XCTAssertEqual(transaction.toAmount, toAmount)
        XCTAssertEqual(transaction.toToken, toToken)
        XCTAssertEqual(transaction.limitPrice, limitPrice)
        XCTAssertEqual(transaction.status, status)
        XCTAssertEqual(transaction.txHash, txHash)
        XCTAssertNotNil(transaction.createdAt)
    }
    
    func testTransactionWithUpdatedStatus() {
        // Given
        let originalTransaction = Transaction(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: .pending,
            txHash: "0x1234567890abcdef"
        )
        
        let blockNumber = "12345678"
        let gasUsed = "21000"
        let gasPrice = "30000000000"
        
        // When
        let updatedTransaction = originalTransaction.withUpdatedStatus(
            status: .confirmed,
            blockNumber: blockNumber,
            gasUsed: gasUsed,
            gasPrice: gasPrice
        )
        
        // Then
        XCTAssertEqual(updatedTransaction.id, originalTransaction.id)
        XCTAssertEqual(updatedTransaction.status, .confirmed)
        XCTAssertEqual(updatedTransaction.blockNumber, blockNumber)
        XCTAssertEqual(updatedTransaction.gasUsed, gasUsed)
        XCTAssertEqual(updatedTransaction.gasPrice, gasPrice)
        XCTAssertNotNil(updatedTransaction.lastPolledAt)
        
        // Original fields should remain unchanged
        XCTAssertEqual(updatedTransaction.fromAmount, originalTransaction.fromAmount)
        XCTAssertEqual(updatedTransaction.txHash, originalTransaction.txHash)
        XCTAssertEqual(updatedTransaction.createdAt, originalTransaction.createdAt)
    }
    
    func testTransactionNeedsPolling() {
        // Given - Pending transaction with txHash, created recently
        let pendingTransaction = Transaction(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: .pending,
            txHash: "0x1234567890abcdef",
            createdAt: Date()
        )
        
        // Then - Should need polling
        XCTAssertTrue(pendingTransaction.needsPolling)
        
        // Given - Confirmed transaction
        let confirmedTransaction = pendingTransaction.withUpdatedStatus(status: .confirmed)
        
        // Then - Should not need polling
        XCTAssertFalse(confirmedTransaction.needsPolling)
        
        // Given - Pending transaction without txHash
        let noHashTransaction = Transaction(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: .pending,
            txHash: nil
        )
        
        // Then - Should not need polling
        XCTAssertFalse(noHashTransaction.needsPolling)
        
        // Given - Old pending transaction (beyond 2 minutes)
        let oldTransaction = Transaction(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: .pending,
            txHash: "0x1234567890abcdef",
            createdAt: Date().addingTimeInterval(-130) // 130 seconds ago
        )
        
        // Then - Should not need polling (beyond 2 minute limit)
        XCTAssertFalse(oldTransaction.needsPolling)
    }
    
    func testTransactionTimeUntilNextPoll() {
        // Given
        let lastPolled = Date().addingTimeInterval(-3) // 3 seconds ago
        let transaction = Transaction(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: .pending,
            txHash: "0x1234567890abcdef",
            lastPolledAt: lastPolled
        )
        
        // When
        let timeUntilNext = transaction.timeUntilNextPoll
        
        // Then - Should be approximately 2 seconds (5 - 3)
        XCTAssertLessThanOrEqual(timeUntilNext, 2.1)
        XCTAssertGreaterThanOrEqual(timeUntilNext, 1.9)
        
        // Given - Never polled before
        let neverPolledTransaction = Transaction(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855"
        )
        
        // Then - Should be 0 (ready to poll immediately)
        XCTAssertEqual(neverPolledTransaction.timeUntilNextPoll, 0)
    }
    
    func testTransactionStatusEnum() {
        // Test all cases
        XCTAssertEqual(TransactionStatus.pending.rawValue, "Pending")
        XCTAssertEqual(TransactionStatus.confirmed.rawValue, "Confirmed")
        XCTAssertEqual(TransactionStatus.failed.rawValue, "Failed")
        XCTAssertEqual(TransactionStatus.cancelled.rawValue, "Cancelled")
        
        // Test legacy compatibility
        XCTAssertEqual(TransactionStatus.filled, TransactionStatus.confirmed)
    }
    
    func testTransactionCodable() throws {
        // Given
        let transaction = Transaction(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: .confirmed,
            txHash: "0x1234567890abcdef",
            blockNumber: "12345678",
            gasUsed: "21000",
            gasPrice: "30000000000"
        )
        
        // When - Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(transaction)
        
        // Then - Should not throw
        XCTAssertGreaterThan(data.count, 0)
        
        // When - Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedTransaction = try decoder.decode(Transaction.self, from: data)
        
        // Then - Should match original
        XCTAssertEqual(decodedTransaction.id, transaction.id)
        XCTAssertEqual(decodedTransaction.type, transaction.type)
        XCTAssertEqual(decodedTransaction.fromAmount, transaction.fromAmount)
        XCTAssertEqual(decodedTransaction.status, transaction.status)
        XCTAssertEqual(decodedTransaction.txHash, transaction.txHash)
        XCTAssertEqual(decodedTransaction.blockNumber, transaction.blockNumber)
    }
    
    func testTransactionCreationParams() {
        // Given
        let params = TransactionCreationParams(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            txHash: "0x1234567890abcdef"
        )
        
        // When
        let transaction = params.toTransaction()
        
        // Then
        XCTAssertEqual(transaction.type, params.type)
        XCTAssertEqual(transaction.fromAmount, params.fromAmount)
        XCTAssertEqual(transaction.fromToken, params.fromToken)
        XCTAssertEqual(transaction.toAmount, params.toAmount)
        XCTAssertEqual(transaction.toToken, params.toToken)
        XCTAssertEqual(transaction.limitPrice, params.limitPrice)
        XCTAssertEqual(transaction.txHash, params.txHash)
        XCTAssertEqual(transaction.status, .pending) // Default status
        XCTAssertNotNil(transaction.id)
        XCTAssertNotNil(transaction.createdAt)
    }
    
    func testPolygonTransactionReceiptCodable() throws {
        // Given
        let receiptJSON = """
        {
            "status": "1",
            "message": "OK",
            "result": {
                "status": "1",
                "blockNumber": "12345678",
                "gasUsed": "21000",
                "gasPrice": "30000000000",
                "transactionHash": "0x1234567890abcdef"
            }
        }
        """.data(using: .utf8)!
        
        // When
        let receipt = try JSONDecoder().decode(PolygonTransactionReceipt.self, from: receiptJSON)
        
        // Then
        XCTAssertEqual(receipt.status, "1")
        XCTAssertEqual(receipt.message, "OK")
        XCTAssertNotNil(receipt.result)
        XCTAssertEqual(receipt.result?.status, "1")
        XCTAssertEqual(receipt.result?.blockNumber, "12345678")
        XCTAssertEqual(receipt.result?.gasUsed, "21000")
        XCTAssertEqual(receipt.result?.gasPrice, "30000000000")
        XCTAssertEqual(receipt.result?.transactionHash, "0x1234567890abcdef")
    }
    
    func testPolygonReceiptErrorResponse() throws {
        // Given
        let errorJSON = """
        {
            "status": "0",
            "message": "NOTOK",
            "result": null
        }
        """.data(using: .utf8)!
        
        // When
        let receipt = try JSONDecoder().decode(PolygonTransactionReceipt.self, from: errorJSON)
        
        // Then
        XCTAssertEqual(receipt.status, "0")
        XCTAssertEqual(receipt.message, "NOTOK")
        XCTAssertNil(receipt.result)
    }
}