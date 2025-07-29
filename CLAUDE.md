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

# Run single test from integration tests (for debugging)
./run_single_test.sh testCompleteTransactionLifecycle TransactionIntegrationTests
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

### Wallet Management & Tab Visibility Features

#### No-Wallet Initialization State
The app implements a progressive disclosure pattern for wallet functionality:

- **Initial State**: App starts with no active wallet, showing only the Home tab
- **Wallet Selection**: Users must explicitly choose to create, import, or use test wallet
- **Tab Activation**: Trade and Transactions tabs only appear after wallet activation
- **Reset Behavior**: Debug reset returns to no-wallet state, hiding additional tabs

#### Wallet State Management
- **ContentView.swift**: Manages dynamic tab visibility based on `hasWallet` state
- **HomeView.swift**: Handles wallet loading/switching with callback notifications
- **NoWalletView.swift**: Provides wallet selection interface (Create/Import/Test)
- **DebugView.swift**: Reset functionality that clears wallet state and returns to Home

#### Wallet Options
1. **Create New Wallet**: Generate new wallet with recovery phrase backup
2. **Import Existing Wallet**: Import from recovery phrase (12-word mnemonic)
3. **Use Test Wallet**: Load pre-configured test wallet for development/demo
4. **Wallet Reset**: Clear active wallet and return to selection state

#### Transaction Management Integration
- Transactions appear immediately in pending state after creation
- Polling service updates transaction status (10-second intervals for 5 minutes)
- UI auto-refreshes every 5 seconds when pending transactions exist
- Transactions sorted by creation date (newest first)
- Transaction history only accessible when wallet is active
- Reset clears transaction state along with wallet data

### Dependencies (Swift Package Manager)
- **web3swift** (3.3.0): Ethereum blockchain interaction and smart contract calls
- **BigInt** (5.4.1): Large number arithmetic for blockchain values and gas calculations
- **CryptoSwift** (1.9.0): Cryptographic operations and hashing
- **secp256k1.swift** (0.10.0): Elliptic curve operations for wallet key management

### Network Configuration
- **Polygon Mainnet**: Production environment (Chain ID: 137)
- **Router V6 Contract**: `0x111111125421cA6dc452d289314280a0f8842A65`
- **WMATIC Token**: `0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270`
- **USDC Token**: `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359`

### Debug and Testing
- Debug logging writes to `/Users/makevoid/apps/1Limit/logs/` directory with timestamped files
- Python debug scripts in `scripts/`:
  - `check_wallet_transactions.py`: Verify wallet transactions on Polygon Mainnet
  - `check_wallet_balances.py`: Check token balances for debugging
  - `analyze_failed_tx.py`: Analyze failed transaction details
- Factory pattern supports both production and test configurations
- Widget extension (`1LimitWidget`) provides iOS home screen widgets with price/chart data

## Development Notes

- **Target Device**: Always use iPhone 16 as the target when using xcodebuild
- **Wallet Security**: Wallet data loads from `wallet_0x3f847d.json` in bundle or documents directory
- **Logging**: Debug transactions create timestamped log files for debugging Router V6 flows
- **Architecture**: Follow the existing protocol-based dependency injection pattern when adding new services
- **Code Organization**: 
  - Models: Transaction data structures
  - Services: Business logic with protocol-based dependency injection
  - Views: SwiftUI views for each tab (Home, Trade, Transactions)
  - DesignSystem: Reusable UI components (Buttons, Cards, Colors, Typography)
  - Protocols: Interface definitions for testability and modularity

## Git Commit Style

When creating commit messages, use lots of emojis including:
- 👩‍💻 Girl doing jobs emojis (👩‍🔧👩‍🎨👩‍🚀👩‍💼👩‍🔬👩‍🎓👩‍⚕️👩‍🏫👩‍🌾👩‍🍳👩‍🎤👩‍🎬👩‍🎯👩‍🏭👩‍💻👩‍🔧👩‍✈️)
- 🎯 Action emojis (🚀🎨🔧💫✨🎯🔥💎⚡️🎪🎭🎨🎬🎵🎪)
- 🦄 Animals (🦄🐱🐶🐼🐨🐸🐧🦋🐝🦊🐺🐯🦁🐘🐙🦀🐬🐳🦈🦖🦕🐲)

Example: "👩‍💻🦄 Fix wallet creation tests with sparkly new assertions! ✨🎯🐱"

## Debugging Commands

```bash
# Check if build succeeds (RECOMMENDED - use this for build testing)
python3 scripts/check_build.py

# Manual build check with error/warning filtering
xcodebuild -scheme 1Limit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "(warning|error):"

# Check if build succeeded (quick test)
xcodebuild -scheme 1Limit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED)"

# Run Python debugging scripts
python3 scripts/check_wallet_transactions.py
python3 scripts/check_wallet_balances.py

# Check recent debug logs
ls -la logs/ | tail -5
tail -50 logs/1limit_debug_$(date +%Y-%m-%d)*.log
```

## Testing Strategy

### Wallet State Testing
Tests must account for the progressive wallet activation model:

- **Initial State**: Tests expect only Home tab visible, no wallet buttons active
- **After Wallet Load**: Tests expect all tabs visible, wallet-specific buttons available
- **After Reset**: Tests expect return to initial no-wallet state

### Common Test Patterns
```swift
// Check if wallet is already active before testing wallet creation buttons
let activeWalletText = app.staticTexts["Active Wallet"]
if !activeWalletText.exists {
    // Test wallet creation buttons
} else {
    // Skip wallet creation tests, wallet already active
}
```

### Test Environment Considerations
- Tests may run in environments where wallets persist between runs
- Use conditional logic to handle both fresh and wallet-active states
- Bundled tests are more reliable than individual test execution
- Reset functionality should be tested to ensure proper state cleanup

## Reminder Notes

- ask me to run these
- **NEVER commit without explicit user confirmation** - Always ask the user to confirm before creating any git commits

## Git Commit Policy

**IMPORTANT**: Claude must NEVER create git commits automatically. Always follow this process:

1. Stage changes with `git add`
2. Show the user what will be committed with `git status` and `git diff --cached`
3. Ask the user: "Ready to commit these changes?"
4. Only proceed with `git commit` after explicit user confirmation