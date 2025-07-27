//
//  TransactionPersistenceTests.swift
//  1LimitTests
//
//  Unit tests for TransactionPersistenceManager and related functionality
//

import XCTest
@testable import _Limit

final class TransactionPersistenceTests: XCTestCase {
    
    var mockPersistence: MockTransactionPersistenceManager!
    
    override func setUp() {
        super.setUp()
        mockPersistence = MockTransactionPersistenceManager()
    }
    
    override func tearDown() {
        mockPersistence = nil
        super.tearDown()
    }
    
    // MARK: - MockTransactionPersistenceManager Tests
    
    func testSaveTransaction() async throws {
        // Given
        let transaction = createTestTransaction()
        
        // When
        try await mockPersistence.saveTransaction(transaction)
        
        // Then
        let savedTransactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(savedTransactions.count, 1)
        XCTAssertEqual(savedTransactions.first?.id, transaction.id)
        XCTAssertEqual(savedTransactions.first?.type, transaction.type)
    }
    
    func testSaveMultipleTransactions() async throws {
        // Given
        let transaction1 = createTestTransaction(fromAmount: "100.0")
        let transaction2 = createTestTransaction(fromAmount: "200.0")
        
        // When
        try await mockPersistence.saveTransaction(transaction1)
        try await mockPersistence.saveTransaction(transaction2)
        
        // Then
        let savedTransactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(savedTransactions.count, 2)
        
        // Should be sorted by creation date (newest first)
        XCTAssertTrue(savedTransactions[0].createdAt >= savedTransactions[1].createdAt)
    }
    
    func testSaveTransactionReplacesExisting() async throws {
        // Given
        let originalTransaction = createTestTransaction()
        let updatedTransaction = originalTransaction.withUpdatedStatus(
            status: .confirmed,
            blockNumber: "12345678"
        )
        
        // When
        try await mockPersistence.saveTransaction(originalTransaction)
        try await mockPersistence.saveTransaction(updatedTransaction)
        
        // Then
        let savedTransactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(savedTransactions.count, 1)
        XCTAssertEqual(savedTransactions.first?.status, .confirmed)
        XCTAssertEqual(savedTransactions.first?.blockNumber, "12345678")
    }
    
    func testLoadEmptyTransactions() async throws {
        // When
        let transactions = try await mockPersistence.loadTransactions()
        
        // Then
        XCTAssertEqual(transactions.count, 0)
    }
    
    func testUpdateTransaction() async throws {
        // Given
        let originalTransaction = createTestTransaction()
        try await mockPersistence.saveTransaction(originalTransaction)
        
        let updatedTransaction = originalTransaction.withUpdatedStatus(
            status: .confirmed,
            blockNumber: "12345678",
            gasUsed: "21000"
        )
        
        // When
        try await mockPersistence.updateTransaction(updatedTransaction)
        
        // Then
        let savedTransactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(savedTransactions.count, 1)
        XCTAssertEqual(savedTransactions.first?.status, .confirmed)
        XCTAssertEqual(savedTransactions.first?.blockNumber, "12345678")
        XCTAssertEqual(savedTransactions.first?.gasUsed, "21000")
    }
    
    func testUpdateNonExistentTransaction() async {
        // Given
        let transaction = createTestTransaction()
        
        // When/Then
        do {
            try await mockPersistence.updateTransaction(transaction)
            XCTFail("Should have thrown transactionNotFound error")
        } catch let error as PersistenceError {
            if case .transactionNotFound(let id) = error {
                XCTAssertEqual(id, transaction.id)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testDeleteTransaction() async throws {
        // Given
        let transaction1 = createTestTransaction(fromAmount: "100.0")
        let transaction2 = createTestTransaction(fromAmount: "200.0")
        
        try await mockPersistence.saveTransaction(transaction1)
        try await mockPersistence.saveTransaction(transaction2)
        
        // When
        try await mockPersistence.deleteTransaction(id: transaction1.id)
        
        // Then
        let remainingTransactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(remainingTransactions.count, 1)
        XCTAssertEqual(remainingTransactions.first?.id, transaction2.id)
    }
    
    func testDeleteNonExistentTransaction() async {
        // Given
        let nonExistentId = UUID()
        
        // When/Then
        do {
            try await mockPersistence.deleteTransaction(id: nonExistentId)
            XCTFail("Should have thrown transactionNotFound error")
        } catch let error as PersistenceError {
            if case .transactionNotFound(let id) = error {
                XCTAssertEqual(id, nonExistentId)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testDeleteAllTransactions() async throws {
        // Given
        let transaction1 = createTestTransaction(fromAmount: "100.0")
        let transaction2 = createTestTransaction(fromAmount: "200.0")
        
        try await mockPersistence.saveTransaction(transaction1)
        try await mockPersistence.saveTransaction(transaction2)
        
        // When
        try await mockPersistence.deleteAllTransactions()
        
        // Then
        let remainingTransactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(remainingTransactions.count, 0)
    }
    
    func testErrorHandling() async {
        // Given
        mockPersistence.shouldThrowError = true
        let testError = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockPersistence.errorToThrow = PersistenceError.saveFailed(testError)
        
        let transaction = createTestTransaction()
        
        // When/Then - Save should throw
        do {
            try await mockPersistence.saveTransaction(transaction)
            XCTFail("Should have thrown error")
        } catch let error as PersistenceError {
            if case .saveFailed = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // When/Then - Load should throw
        do {
            _ = try await mockPersistence.loadTransactions()
            XCTFail("Should have thrown error")
        } catch let error as PersistenceError {
            if case .saveFailed = error {
                // Expected (using same error for simplicity)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testMockHelpers() async throws {
        // Given
        let transaction1 = createTestTransaction(fromAmount: "100.0")
        let transaction2 = createTestTransaction(fromAmount: "200.0")
        
        // When
        mockPersistence.setTransactions([transaction1, transaction2])
        
        // Then
        XCTAssertEqual(mockPersistence.getTransactionCount(), 2)
        
        let loadedTransactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(loadedTransactions.count, 2)
        XCTAssertTrue(loadedTransactions.contains { $0.id == transaction1.id })
        XCTAssertTrue(loadedTransactions.contains { $0.id == transaction2.id })
    }
    
    // MARK: - PersistenceError Tests
    
    func testPersistenceErrorDescriptions() {
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        let saveFailed = PersistenceError.saveFailed(testError)
        XCTAssertEqual(saveFailed.errorDescription, "Failed to save transactions: Test error")
        
        let loadFailed = PersistenceError.loadFailed(testError)
        XCTAssertEqual(loadFailed.errorDescription, "Failed to load transactions: Test error")
        
        let transactionId = UUID()
        let notFound = PersistenceError.transactionNotFound(transactionId)
        XCTAssertEqual(notFound.errorDescription, "Transaction not found: \(transactionId.uuidString)")
        
        let deallocated = PersistenceError.managerDeallocated
        XCTAssertEqual(deallocated.errorDescription, "Transaction manager was deallocated")
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() async throws {
        // Given
        let pendingTransaction = createTestTransaction(status: .pending)
        let confirmedTransaction = pendingTransaction.withUpdatedStatus(
            status: .confirmed,
            blockNumber: "12345678",
            gasUsed: "21000",
            gasPrice: "30000000000"
        )
        
        // When - Save initial transaction
        try await mockPersistence.saveTransaction(pendingTransaction)
        var transactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.status, .pending)
        
        // When - Update transaction status
        try await mockPersistence.updateTransaction(confirmedTransaction)
        transactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.status, .confirmed)
        XCTAssertEqual(transactions.first?.blockNumber, "12345678")
        
        // When - Delete transaction
        try await mockPersistence.deleteTransaction(id: confirmedTransaction.id)
        transactions = try await mockPersistence.loadTransactions()
        XCTAssertEqual(transactions.count, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTransaction(
        fromAmount: String = "100.0",
        status: TransactionStatus = .pending
    ) -> Transaction {
        return Transaction(
            type: "Limit Order",
            fromAmount: fromAmount,
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: status,
            txHash: "0x1234567890abcdef"
        )
    }
}