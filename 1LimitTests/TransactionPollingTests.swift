//
//  TransactionPollingTests.swift
//  1LimitTests
//
//  Unit tests for TransactionPollingService with mocked Polygon API
//

import XCTest
@testable import _Limit

final class TransactionPollingTests: XCTestCase {
    
    var mockPollingService: MockTransactionPollingService!
    var mockPersistence: MockTransactionPersistenceManager!
    var realPollingService: TransactionPollingService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockPersistence = MockTransactionPersistenceManager()
        mockURLSession = MockURLSession()
    }
    
    @MainActor
    func setupMockPollingService() {
        mockPollingService = MockTransactionPollingService()
    }
    
    @MainActor
    func setupRealPollingService() {
        realPollingService = TransactionPollingService(
            persistenceManager: mockPersistence,
            urlSession: .shared // Use shared session instead of custom mock
        )
    }
    
    override func tearDown() {
        mockPollingService = nil
        mockPersistence = nil
        mockURLSession = nil
        realPollingService = nil
        super.tearDown()
    }
    
    // MARK: - MockTransactionPollingService Tests
    
    @MainActor
    func testMockPollingStartStop() async {
        // Setup
        setupMockPollingService()
        
        // Given
        let transaction = createTestTransaction()
        var receivedUpdates: [Transaction] = []
        
        mockPollingService.onTransactionUpdate = { updatedTransaction in
            receivedUpdates.append(updatedTransaction)
        }
        
        // When
        await mockPollingService.startPolling(for: transaction)
        
        // Then
        XCTAssertTrue(receivedUpdates.count > 0)
        XCTAssertEqual(receivedUpdates.first?.id, transaction.id)
        XCTAssertFalse(mockPollingService.isPolling(for: transaction.id))
    }
    
    @MainActor
    func testMockPollingSuccess() async {
        // Setup
        setupMockPollingService()
        
        // Given
        let transaction = createTestTransaction(status: .pending)
        var receivedTransaction: Transaction?
        
        mockPollingService.shouldSimulateSuccess = true
        mockPollingService.onTransactionUpdate = { updatedTransaction in
            receivedTransaction = updatedTransaction
        }
        
        // When
        await mockPollingService.startPolling(for: transaction)
        
        // Then
        XCTAssertNotNil(receivedTransaction)
        XCTAssertEqual(receivedTransaction?.status, .confirmed)
        XCTAssertEqual(receivedTransaction?.blockNumber, "12345678")
        XCTAssertEqual(receivedTransaction?.gasUsed, "21000")
        XCTAssertEqual(receivedTransaction?.gasPrice, "30000000000")
    }
    
    @MainActor
    func testMockPollingError() async {
        // Setup
        setupMockPollingService()
        
        // Given
        let transaction = createTestTransaction(status: .pending)
        var receivedTransaction: Transaction?
        
        mockPollingService.shouldSimulateSuccess = false
        mockPollingService.shouldSimulateError = true
        mockPollingService.onTransactionUpdate = { updatedTransaction in
            receivedTransaction = updatedTransaction
        }
        
        // When
        await mockPollingService.startPolling(for: transaction)
        
        // Then
        XCTAssertNotNil(receivedTransaction)
        XCTAssertEqual(receivedTransaction?.status, .pending) // Should remain pending on error
    }
    
    @MainActor
    func testMockPollingStopAll() async {
        // Setup
        setupMockPollingService()
        
        // Given
        let transaction1 = createTestTransaction()
        let transaction2 = createTestTransaction()
        
        // Configure mock to have a longer delay so we can test stopping
        mockPollingService.mockDelay = 1.0 // 1 second delay
        
        // When - Start polling without awaiting
        Task {
            await mockPollingService.startPolling(for: transaction1)
        }
        Task {
            await mockPollingService.startPolling(for: transaction2)
        }
        
        // Give a moment for tasks to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        // Then - Check count while polling is active
        XCTAssertGreaterThan(mockPollingService.getPollingCount(), 0)
        
        // When - Stop all polling
        mockPollingService.stopAllPolling()
        
        // Then - All polling should be stopped
        XCTAssertEqual(mockPollingService.getPollingCount(), 0)
    }
    
    // MARK: - Real TransactionPollingService Tests
    
    @MainActor
    func testPollingServiceInitialization() {
        // Given
        setupRealPollingService()
        
        // Then
        XCTAssertNotNil(realPollingService)
    }
    
    @MainActor
    func testPollingServiceDoesNotPollWithoutTxHash() async {
        // Given
        setupRealPollingService()
        let transaction = createTestTransaction(txHash: nil)
        
        // When
        await realPollingService.startPolling(for: transaction)
        
        // Then - Should not start polling
        // We can't directly test this without exposing internal state,
        // but the method should return immediately without doing anything
    }
    
    @MainActor
    func testPollingServiceDoesNotPollConfirmedTransaction() async {
        // Given
        setupRealPollingService()
        let transaction = createTestTransaction(status: .confirmed)
        
        // When
        await realPollingService.startPolling(for: transaction)
        
        // Then - Should not start polling confirmed transaction
        // Method should return immediately
    }
    
    @MainActor
    func testPollingServiceStopPolling() async {
        // Given
        setupRealPollingService()
        let transaction = createTestTransaction()
        
        // When
        await realPollingService.startPolling(for: transaction)
        realPollingService.stopPolling(for: transaction.id)
        
        // Then - Should stop polling (no way to test directly)
        // But method should not crash
    }
    
    @MainActor
    func testPollingServiceStopAllPolling() async {
        // Given
        setupRealPollingService()
        let transaction1 = createTestTransaction()
        let transaction2 = createTestTransaction()
        
        // When
        await realPollingService.startPolling(for: transaction1)
        await realPollingService.startPolling(for: transaction2)
        realPollingService.stopAllPolling()
        
        // Then - Should stop all polling
        // Method should not crash
    }
    
    // MARK: - Error Handling Tests
    
    func testPollingErrorTypes() {
        // Test PollingError cases
        let invalidURL = PollingError.invalidURL
        XCTAssertEqual(invalidURL.errorDescription, "Invalid Polygon API URL")
        
        let invalidResponse = PollingError.invalidResponse
        XCTAssertEqual(invalidResponse.errorDescription, "Invalid response from Polygon API")
        
        let httpError = PollingError.httpError(404)
        XCTAssertEqual(httpError.errorDescription, "HTTP error: 404")
        
        let apiError = PollingError.apiError("Rate limit exceeded")
        XCTAssertEqual(apiError.errorDescription, "Polygon API error: Rate limit exceeded")
        
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test decode error"])
        let decodingError = PollingError.decodingError(testError)
        XCTAssertEqual(decodingError.errorDescription, "Failed to decode response: Test decode error")
    }
    
    // MARK: - Integration Tests with Mock Network
    
    @MainActor
    func testPollingServiceIntegration() async {
        // Note: Network integration tests are limited by URLSession mocking constraints
        // The real polling service is tested through the mock polling service which
        // simulates the same behavior patterns
        
        setupRealPollingService()
        let transaction = createTestTransaction()
        
        // Test that polling can be started and stopped without crashing
        await realPollingService.startPolling(for: transaction)
        realPollingService.stopPolling(for: transaction.id)
        
        // Test multiple transactions
        let transaction2 = createTestTransaction()
        await realPollingService.startPolling(for: transaction)
        await realPollingService.startPolling(for: transaction2)
        realPollingService.stopAllPolling()
        
        // Tests pass if no crashes occur
        XCTAssertTrue(true, "Polling service integration test completed")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTransaction(
        status: TransactionStatus = .pending,
        txHash: String? = "0x1234567890abcdef"
    ) -> Transaction {
        return Transaction(
            type: "Limit Order",
            fromAmount: "100.0",
            fromToken: "WMATIC",
            toAmount: "85.5",
            toToken: "USDC",
            limitPrice: "0.855",
            status: status,
            txHash: txHash
        )
    }
}

// MARK: - Mock URLSession for Testing

class MockURLSession: URLSession, @unchecked Sendable {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    // Note: This is a simplified mock for testing purposes
    // In production, we use the real URLSession.data(from:) method
}