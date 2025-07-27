//
//  TransactionIntegrationTests.swift
//  1LimitTests
//
//  Integration tests for complete transaction flow with polling
//

import XCTest
@testable import _Limit

final class TransactionIntegrationTests: XCTestCase {
    
    var transactionManager: TransactionManager!
    var mockPersistence: MockTransactionPersistenceManager!
    var mockPolling: MockTransactionPollingService!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockPersistence = MockTransactionPersistenceManager()
        mockPolling = MockTransactionPollingService()
        transactionManager = TransactionManager(
            persistenceManager: mockPersistence,
            pollingService: mockPolling
        )
    }
    
    override func tearDown() {
        transactionManager = nil
        mockPersistence = nil
        mockPolling = nil
        super.tearDown()
    }
    
    // MARK: - TransactionManager Integration Tests
    
    @MainActor
    func testTransactionManagerInitialization() {
        // Given: TransactionManager is created
        
        // Then: It should be properly initialized
        XCTAssertFalse(transactionManager.isLoading)
        XCTAssertEqual(transactionManager.transactions.count, 0)
        XCTAssertNil(transactionManager.errorMessage)
    }
    
    @MainActor
    func testLoadTransactions() async {
        // Given: Some mock transactions
        let transaction1 = createTestTransaction(fromAmount: "100.0", status: .pending)
        let transaction2 = createTestTransaction(fromAmount: "200.0", status: .confirmed)
        mockPersistence.setTransactions([transaction1, transaction2])
        
        // When: Loading transactions
        await transactionManager.loadTransactions()
        
        // Then: Transactions should be loaded
        XCTAssertEqual(transactionManager.transactions.count, 2)
        XCTAssertFalse(transactionManager.isLoading)
        XCTAssertNil(transactionManager.errorMessage)
    }
    
    @MainActor
    func testLoadTransactionsWithError() async {
        // Given: Persistence manager configured to throw error
        mockPersistence.shouldThrowError = true
        
        // When: Loading transactions
        await transactionManager.loadTransactions()
        
        // Then: Should handle error gracefully
        XCTAssertEqual(transactionManager.transactions.count, 0)
        XCTAssertFalse(transactionManager.isLoading)
        XCTAssertNotNil(transactionManager.errorMessage)
        XCTAssertTrue(transactionManager.errorMessage!.contains("Failed to load transactions"))
    }
    
    @MainActor
    func testFilterTransactions() async {
        // Given: Mix of transaction statuses
        let pendingTx = createTestTransaction(fromAmount: "100.0", status: .pending)
        let confirmedTx = createTestTransaction(fromAmount: "200.0", status: .confirmed)
        let failedTx = createTestTransaction(fromAmount: "300.0", status: .failed)
        
        mockPersistence.setTransactions([pendingTx, confirmedTx, failedTx])
        await transactionManager.loadTransactions()
        
        // When/Then: Filter by different statuses
        let allTransactions = transactionManager.getFilteredTransactions(by: "All")
        XCTAssertEqual(allTransactions.count, 3)
        
        let pendingOnly = transactionManager.getFilteredTransactions(by: "Pending")
        XCTAssertEqual(pendingOnly.count, 1)
        XCTAssertEqual(pendingOnly.first?.status, .pending)
        
        let confirmedOnly = transactionManager.getFilteredTransactions(by: "Confirmed")
        XCTAssertEqual(confirmedOnly.count, 1)
        XCTAssertEqual(confirmedOnly.first?.status, .confirmed)
        
        let filledOnly = transactionManager.getFilteredTransactions(by: "Filled")
        XCTAssertEqual(filledOnly.count, 1)
        XCTAssertEqual(filledOnly.first?.status, .confirmed)
        
        let failedOnly = transactionManager.getFilteredTransactions(by: "Failed")
        XCTAssertEqual(failedOnly.count, 1)
        XCTAssertEqual(failedOnly.first?.status, .failed)
    }
    
    @MainActor
    func testDeleteTransaction() async {
        // Given: Transactions in manager
        let transaction1 = createTestTransaction(fromAmount: "100.0")
        let transaction2 = createTestTransaction(fromAmount: "200.0")
        
        mockPersistence.setTransactions([transaction1, transaction2])
        await transactionManager.loadTransactions()
        XCTAssertEqual(transactionManager.transactions.count, 2)
        
        // When: Deleting one transaction
        await transactionManager.deleteTransaction(transaction1)
        
        // Then: Transaction should be removed
        XCTAssertEqual(transactionManager.transactions.count, 1)
        XCTAssertEqual(transactionManager.transactions.first?.id, transaction2.id)
        XCTAssertEqual(mockPersistence.getTransactionCount(), 1)
    }
    
    @MainActor
    func testClearAllTransactions() async {
        // Given: Transactions in manager
        let transaction1 = createTestTransaction(fromAmount: "100.0")
        let transaction2 = createTestTransaction(fromAmount: "200.0")
        
        mockPersistence.setTransactions([transaction1, transaction2])
        await transactionManager.loadTransactions()
        XCTAssertEqual(transactionManager.transactions.count, 2)
        
        // When: Clearing all transactions
        await transactionManager.clearAllTransactions()
        
        // Then: All transactions should be removed
        XCTAssertEqual(transactionManager.transactions.count, 0)
        XCTAssertEqual(mockPersistence.getTransactionCount(), 0)
    }
    
    @MainActor
    func testTransactionUpdateFromPolling() async {
        // Given: Pending transaction
        let pendingTransaction = createTestTransaction(status: .pending)
        mockPersistence.setTransactions([pendingTransaction])
        await transactionManager.loadTransactions()
        
        XCTAssertEqual(transactionManager.transactions.first?.status, .pending)
        
        // When: Polling service reports update
        let confirmedTransaction = pendingTransaction.withUpdatedStatus(
            status: .confirmed,
            blockNumber: "12345678",
            gasUsed: "21000"
        )
        
        // Simulate polling callback
        mockPolling.onTransactionUpdate?(confirmedTransaction)
        
        // Then: Transaction should be updated in manager
        XCTAssertEqual(transactionManager.transactions.first?.status, .confirmed)
        XCTAssertEqual(transactionManager.transactions.first?.blockNumber, "12345678")
        XCTAssertEqual(transactionManager.transactions.first?.gasUsed, "21000")
    }
    
    @MainActor
    func testRefreshTransactions() async {
        // Given: Initial transactions
        let transaction1 = createTestTransaction(fromAmount: "100.0")
        mockPersistence.setTransactions([transaction1])
        await transactionManager.loadTransactions()
        XCTAssertEqual(transactionManager.transactions.count, 1)
        
        // Given: More transactions added to persistence
        let transaction2 = createTestTransaction(fromAmount: "200.0")
        mockPersistence.setTransactions([transaction1, transaction2])
        
        // When: Refreshing transactions
        await transactionManager.refreshTransactions()
        
        // Then: Should load all transactions
        XCTAssertEqual(transactionManager.transactions.count, 2)
    }
    
    // MARK: - Complete Flow Tests
    
    @MainActor
    func testCompleteTransactionLifecycle() async {
        // Given: Empty transaction manager
        XCTAssertEqual(transactionManager.transactions.count, 0)
        
        // When: New pending transaction is created (simulating order submission)
        let pendingTransaction = createTestTransaction(status: .pending)
        try? await mockPersistence.saveTransaction(pendingTransaction)
        await transactionManager.loadTransactions()
        
        // Then: Transaction should appear
        XCTAssertEqual(transactionManager.transactions.count, 1)
        XCTAssertEqual(transactionManager.transactions.first?.status, .pending)
        
        // When: Polling updates transaction to confirmed
        let confirmedTransaction = pendingTransaction.withUpdatedStatus(
            status: .confirmed,
            blockNumber: "12345678",
            gasUsed: "21000",
            gasPrice: "30000000000"
        )
        
        // Simulate successful polling update
        mockPolling.onTransactionUpdate?(confirmedTransaction)
        
        // Then: Transaction should be updated
        XCTAssertEqual(transactionManager.transactions.first?.status, .confirmed)
        XCTAssertNotNil(transactionManager.transactions.first?.blockNumber)
        
        // When: User deletes transaction
        await transactionManager.deleteTransaction(confirmedTransaction)
        
        // Then: Transaction should be removed
        XCTAssertEqual(transactionManager.transactions.count, 0)
    }
    
    @MainActor
    func testPollingStartsForPendingTransactions() async {
        // Given: Mix of transactions, some that need polling
        let pendingTx = createTestTransaction(status: .pending, needsPolling: true)
        let confirmedTx = createTestTransaction(status: .confirmed, needsPolling: false)
        let oldPendingTx = createTestTransaction(
            status: .pending, 
            needsPolling: false, 
            createdAt: Date().addingTimeInterval(-150) // 2.5 minutes ago
        )
        
        mockPersistence.setTransactions([pendingTx, confirmedTx, oldPendingTx])
        
        // When: Loading transactions (which should start polling)
        await transactionManager.loadTransactions()
        
        // Then: Should have loaded all transactions
        XCTAssertEqual(transactionManager.transactions.count, 3)
        
        // Note: We can't directly test if polling started since it's async,
        // but the manager should call startPolling for qualifying transactions
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testDeleteTransactionError() async {
        // Given: Persistence manager configured to throw error on delete
        let transaction = createTestTransaction()
        mockPersistence.setTransactions([transaction])
        await transactionManager.loadTransactions()
        
        // Configure error for delete operation
        mockPersistence.shouldThrowError = true
        
        // When: Attempting to delete transaction
        await transactionManager.deleteTransaction(transaction)
        
        // Then: Should handle error gracefully
        XCTAssertNotNil(transactionManager.errorMessage)
        XCTAssertTrue(transactionManager.errorMessage!.contains("Failed to delete transaction"))
        
        // Transaction should still be present since delete failed
        XCTAssertEqual(transactionManager.transactions.count, 1)
    }
    
    @MainActor
    func testClearAllTransactionsError() async {
        // Given: Transactions and error-configured persistence
        let transaction = createTestTransaction()
        mockPersistence.setTransactions([transaction])
        await transactionManager.loadTransactions()
        
        mockPersistence.shouldThrowError = true
        
        // When: Attempting to clear all transactions
        await transactionManager.clearAllTransactions()
        
        // Then: Should handle error gracefully
        XCTAssertNotNil(transactionManager.errorMessage)
        XCTAssertTrue(transactionManager.errorMessage!.contains("Failed to clear transactions"))
    }
    
    // MARK: - Factory Tests
    
    @MainActor
    func testTransactionManagerFactory() {
        // Test production factory
        let productionManager = TransactionManagerFactory.createProduction()
        XCTAssertNotNil(productionManager)
        
        // Test test factory
        let testManager = TransactionManagerFactory.createTest()
        XCTAssertNotNil(testManager)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTransaction(
        fromAmount: String = "100.0",
        status: TransactionStatus = .pending,
        needsPolling: Bool = true,
        createdAt: Date = Date()
    ) -> Transaction {
        return Transaction(
            type: "Limit Order",
            fromAmount: fromAmount,
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: status,
            txHash: needsPolling ? "0x1234567890abcdef" : nil,
            createdAt: createdAt
        )
    }
}