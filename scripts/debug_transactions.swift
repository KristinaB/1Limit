#!/usr/bin/env swift

import Foundation

// Transaction status enum
enum TransactionStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case failed = "Failed"
    case cancelled = "Cancelled"
}

// Transaction model
struct Transaction: Identifiable, Codable {
    let id: UUID
    let type: String
    let fromAmount: String
    let fromToken: String
    let toAmount: String
    let toToken: String
    let limitPrice: String
    let status: TransactionStatus
    let date: Date
    let txHash: String?
    let blockNumber: String?
    let gasUsed: String?
    let gasPrice: String?
    let lastPolledAt: Date?
    let createdAt: Date
}

// Test JSON parsing
let jsonString = """
[{"fromAmount":"0.01","date":"2025-07-27T06:40:16Z","type":"Limit Order","id":"3F77BD56-E51A-4A86-B340-5CA4616E0F6D","limitPrice":"0.238","status":"Pending","txHash":"0x523ba3633b331f5a30584f02a656e5e45bdfc4e99d24933297a9291420a0af25","createdAt":"2025-07-27T06:40:16Z","toToken":"USDC","fromToken":"WMATIC","toAmount":"Calculating..."}]
"""

print("🧪 Testing Transaction JSON Parsing")
print("===================================")

do {
    let jsonData = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let transactions = try decoder.decode([Transaction].self, from: jsonData)
    
    print("✅ Successfully parsed \(transactions.count) transaction(s)")
    for tx in transactions {
        print("📄 Transaction ID: \(tx.id)")
        print("📊 Status: \(tx.status.rawValue)")
        print("💰 Amount: \(tx.fromAmount) \(tx.fromToken)")
        print("🔗 Hash: \(tx.txHash ?? "nil")")
        print("📅 Date: \(tx.date)")
        print("")
    }
} catch {
    print("❌ Failed to parse JSON: \(error)")
    if let decodingError = error as? DecodingError {
        switch decodingError {
        case .keyNotFound(let key, let context):
            print("Missing key '\(key.stringValue)' in \(context.debugDescription)")
        case .typeMismatch(let type, let context):
            print("Type mismatch for \(type) in \(context.debugDescription)")
        case .valueNotFound(let type, let context):
            print("Value not found for \(type) in \(context.debugDescription)")
        case .dataCorrupted(let context):
            print("Data corrupted: \(context.debugDescription)")
        @unknown default:
            print("Unknown decoding error")
        }
    }
}