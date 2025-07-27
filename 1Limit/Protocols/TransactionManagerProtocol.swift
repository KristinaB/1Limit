//
//  TransactionManagerProtocol.swift
//  1Limit
//
//  Protocol for transaction manager to support widget integration 🔄✨
//

import Foundation

protocol TransactionManagerProtocol {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func getAllTransactions() -> [Transaction]
    func getFilteredTransactions(by filter: String) -> [Transaction]
    func addTransaction(_ transaction: Transaction)
    func refreshTransactions() async
    func getLatestOpenOrders(limit: Int) -> [Transaction]
    func getLatestClosedOrders(limit: Int) -> [Transaction]
}