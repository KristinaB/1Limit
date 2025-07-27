# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**1Limit** is an iOS SwiftUI application implementing a 1inch Router V6 limit order wallet for the Unite DeFi hackathon. The app features a 3-tab interface (Home, Trade, Transactions) with integrated debug functionality for testing Router V6 limit order creation and execution on Polygon Mainnet. This project ports the 1inch Router V6 SDK from Go to Swift.

## Build and Run Commands

```bash
# Build the iOS project
xcodebuild -scheme 1Limit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run with Xcode (recommended for iOS development)
open 1Limit.xcodeproj

# Check for build errors
xcodebuild -scheme 1Limit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -A 5 -B 5 "error:"

# Build and run in simulator (one command)
xcodebuild -scheme 1Limit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build && xcrun simctl install booted build/Debug-iphonesimulator/1Limit.app
```

## Fast Test Suite

The project uses a bundled test approach for maximum speed (~60 seconds total):

```bash
# Run all bundled tests (FASTEST - recommended)
./run_fast_tests.sh all

# Run specific test bundles
./run_fast_tests.sh navigation    # Tab navigation + content persistence
./run_fast_tests.sh trade         # Trade form interactions + validation  
./run_fast_tests.sh wallet        # Wallet creation flow testing
./run_fast_tests.sh content       # UI content verification across all views
./run_fast_tests.sh order         # Order creation + confirmation flows

# Run individual bundled tests
./run_single_test.sh testNavigationAndTabBarBundle BundledUITests
./run_single_test.sh testTradeFormInteractionsBundle BundledUITests
```

**Test Architecture:**
- Each bundle runs multiple related tests in a single app session
- Avoids slow app startup/shutdown cycles between tests
- Uses coordinate-based tapping to prevent accessibility errors
- ~5x faster than individual test execution
- Target on the test suite is to have a low total test suite time

## Project Architecture

### Core Architecture Pattern
The app uses a dependency injection pattern with protocol-based architecture for the Router V6 implementation:

- **RouterV6Manager**: Main coordinator class using dependency injection, manages the complete Router V6 order creation and execution flow
- **Protocol-Based Services**: All major services implement protocols defined in `Protocols/RouterV6Protocols.swift`
- **Factory Pattern**: `RouterV6ManagerFactory` creates properly configured instances for production and testing

### Key Components

#### Main Application Structure
- `_LimitApp.swift`: SwiftUI app entry point
- `ContentView.swift`: Main tab view container (Home, Trade, Transactions) with debug toolbar
- `DebugView.swift`: Debug interface for testing Router V6 transactions

#### Router V6 Core Services (Services/ directory)
- **OrderFactory**: Creates Router V6 orders with parameter generation and validation
- **TransactionSubmitter**: Handles blockchain transaction submission
- **BalanceChecker**: Validates wallet balances and token allowances
- **GasPriceEstimator**: Estimates gas prices and calculates transaction fees
- **PriceService**: Fetches token prices and market data
- **ChartDataService**: Provides chart data for trading interface

#### Supporting Components
- **WalletLoader**: Secure wallet loading from JSON file with iOS bundle integration
- **EIP712SignerWeb3**: EIP-712 signing implementation for Router V6 orders
- **RouterV6Protocols**: Protocol definitions for all services

### Dependencies
- **web3swift**: Ethereum blockchain interaction
- **BigInt**: Large number arithmetic for blockchain values
- **CryptoSwift**: Cryptographic operations

### Network Configuration
- **Polygon Mainnet**: Production environment (Chain ID: 137)
- **Router V6 Contract**: `0x111111125421cA6dc452d289314280a0f8842A65`
- **WMATIC Token**: `0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270`
- **USDC Token**: `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359`

### Debug and Testing
- Debug logging writes to `/Users/makevoid/apps/1Limit/logs/` directory
- Python script `scripts/check_wallet_transactions.py` for wallet verification on Polygon Mainnet
- Factory pattern supports both production and test configurations

## Development Notes

- **Target Device**: Always use iPhone 16 as the target when using xcodebuild
- **Wallet Security**: Wallet data loads from `wallet_0x3f847d.json` in bundle or documents directory
- **Logging**: Debug transactions create timestamped log files for debugging Router V6 flows
- **Architecture**: Follow the existing protocol-based dependency injection pattern when adding new services

## Git Commit Style

When creating commit messages, use lots of emojis including:
- 👩‍💻 Girl doing jobs emojis (👩‍🔧👩‍🎨👩‍🚀👩‍💼👩‍🔬👩‍🎓👩‍⚕️👩‍🏫👩‍🌾👩‍🍳👩‍🎤👩‍🎬👩‍🎯👩‍🏭👩‍💻👩‍🔧👩‍✈️)
- 🎯 Action emojis (🚀🎨🔧💫✨🎯🔥💎⚡️🎪🎭🎨🎬🎵🎪)
- 🦄 Animals (🦄🐱🐶🐼🐨🐸🐧🦋🐝🦊🐺🐯🦁🐘🐙🦀🐬🐳🦈🦖🦕🐲)

Example: "👩‍💻🦄 Fix wallet creation tests with sparkly new assertions! ✨🎯🐱"

## Reminder Notes

- ask me to run these