# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**1Limit** is an iOS SwiftUI application implementing a 1inch Router V6 limit order wallet for the Unite DeFi hackathon. The app features a 3-tab interface (Home, Trade, Transactions) with integrated debug functionality for testing Router V6 limit order creation and execution on Polygon Mainnet. This project ports the 1inch Router V6 SDK from Go to Swift.

## Build and Run Commands

```bash
# Build the iOS project
xcodebuild -scheme 1Limit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run with Xcode (recommended for iOS development)
open 1Limit.xcodeproj

# Check for build errors
xcodebuild -scheme 1Limit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | grep -A 5 -B 5 "error:"
```

## Architecture and Code Structure

### Core Application Architecture

**1Limit iOS** implements a SwiftUI-based wallet application with the following key components:

1. **ContentView.swift**: Main tab bar controller with NavigationView wrapper
2. **RouterV6Manager**: Core 1inch Router V6 SDK functionality ported from Go
3. **WalletLoader**: Secure JSON wallet loading with private key management
4. **Tab Structure**: Home, Trade, Transactions views with debug modal

### UI Architecture

**Tab Navigation Structure**:
- **HomeView**: Welcome screen with wallet status and Router V6 info
- **TradeView**: Limit order creation interface with token pair selection
- **TransactionsView**: Order history with status filtering (Pending/Filled/Cancelled)
- **DebugView**: Modal debug console for testing Router V6 flow

**Debug Integration**: Purple debug button in navigation bar opens modal with complete Router V6 transaction simulation.

### Router V6 Implementation (Ported from Go)

**RouterV6Manager** (`RouterV6Manager.swift`) implements:
- **SDK-Style Salt Generation**: 96-bit salt generation matching 1inch SDK
- **MakerTraits Calculation**: Proper nonce positioning in bits 120-160
- **EIP-712 Domain Creation**: Polygon Mainnet domain for Router V6
- **EIP-2098 Compact Signatures**: r, vs format required by Router V6 contracts
- **Real Wallet Integration**: Loads actual wallet JSON with private key masking

### Wallet Security Architecture

**WalletLoader** (`WalletLoader.swift`) provides:
- **Multi-Source Loading**: Bundle resources → Documents directory → Mock fallback
- **Address Masking**: Safe logging without exposing full addresses
- **Private Key Masking**: Secure display with asterisk padding
- **Validation**: Wallet data format validation before use

### Network Configuration

**Polygon Mainnet Configuration**:
- **Router V6 Contract**: `0x111111125421cA6dc452d289314280a0f8842A65`
- **WMATIC Token**: `0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270`
- **USDC Token**: `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359`
- **Chain ID**: 137 (Polygon Mainnet)

## Router V6 Technical Implementation

### Order Creation Flow (Ported from Go)

1. **Load Wallet**: Secure JSON loading with validation
2. **Generate Parameters**: SDK-style salt (96-bit) and 40-bit nonce
3. **Calculate MakerTraits**: Bit-packed traits with nonce in bits 120-160
4. **Create EIP-712 Domain**: Router V6 domain for Polygon
5. **Sign Order**: EIP-712 typed data signing
6. **Convert Signature**: EIP-2098 compact format (r, vs)
7. **Prepare Transaction**: fillOrder method parameters

### EIP-712 Domain Structure
```swift
EIP712DomainInfo(
    name: "1inch Aggregation Router",
    version: "6", 
    chainID: 137,
    verifyingContract: "0x111111125421cA6dc452d289314280a0f8842A65"
)
```

### Test Parameters
- **Making Amount**: 0.01 WMATIC (10000000000000000 wei)
- **Taking Amount**: 0.01 USDC (10000 units)
- **Gas Limit**: 300000 (matching Go implementation)
- **Gas Price**: Network base + 20% boost

## Security Implementation

### Wallet File Protection
- **Gitignore Rules**: All `wallet_*.json` files excluded from commits
- **Private Key Masking**: `0x1234...***` format for safe logging
- **Address Masking**: `0x1234...abcd` format for display
- **Validation**: Format validation before wallet use

### Development Safety
- **Mock Fallback**: Safe mock wallet if JSON loading fails
- **Bundle Loading**: Wallet files can be included in app bundle
- **Documents Fallback**: Secondary loading from app documents

## State Management

**SwiftUI Architecture**:
- **@StateObject**: RouterV6Manager for debug functionality
- **@State**: Local view state for forms and UI interactions
- **@Environment**: Dismiss for modal presentation
- **ObservableObject**: RouterV6Manager publishes execution state

## Debug Flow Integration

The debug screen (`DebugView.swift`) integrates with `RouterV6Manager` to provide:
- **Real-time Logging**: Step-by-step execution with emoji indicators
- **Wallet Integration**: Loads and validates actual wallet JSON
- **Order Creation**: Complete Router V6 order generation and signing
- **Transaction Preparation**: Ready-to-submit fillOrder transaction data
- **Polygonscan Links**: Generated transaction hash with explorer link

## Development Workflow

### Testing Router V6 Integration
1. **Load Debug Screen**: Tap purple debug button in navigation
2. **Execute Test Flow**: Tap "Execute Test Transaction"
3. **Monitor Logs**: Real-time step-by-step execution display
4. **Verify Parameters**: Check salt generation, nonce calculation, signature format

### Adding New Features
- **Tab Views**: Add new views to ContentView TabView structure
- **Router Integration**: Extend RouterV6Manager for new functionality
- **Wallet Operations**: Use WalletLoader for secure wallet management
- **State Updates**: Follow SwiftUI @Published pattern for reactive updates

## Integration with Go Implementation

This iOS implementation directly ports the Go Router V6 SDK:
- **Same Contract Addresses**: Identical Router V6 deployment
- **Compatible Parameters**: Same salt generation and MakerTraits calculation  
- **Matching Signatures**: Produces identical EIP-712 signatures
- **Shared Test Wallet**: Uses same wallet JSON format
- **Router V6 Compliance**: Full compatibility with Go implementation

## Debug and Testing Commands

### Check Latest Debug Logs
```bash
# View the latest debug log file
ls -la logs/ | tail -1
cat logs/$(ls -t logs/ | head -1)

# Or tail the most recent log in real-time
tail -f logs/$(ls -t logs/ | head -1)
```

### Analyze Router V6 Transactions
```bash
# Check a specific transaction hash
python3 scripts/check_wallet_transactions.py --tx 0x<transaction_hash>

# Check wallet transaction history
python3 scripts/check_wallet_transactions.py
```

### Current Status
- **Latest Log**: `logs/1limit_debug_2025-07-26_09-51-52.log`
- **Last Transaction**: `0x679a6668920ab963bfbc1796358023cb566a849b885f9829952e8026da0a2c13` (FAILED)
- **Issue**: Transaction reaches Polygon mainnet but Router V6 contract rejects it (30k gas used vs 96k for working transactions)
- **Next Steps**: Need to debug parameter encoding differences with working RouterV6Wallet implementation