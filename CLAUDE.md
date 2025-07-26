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
xcodebuild -scheme 1Limit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -A 5 -B 5 "error:"
```

## Build and Development Notes

- When using xcodebuild use iPhone 16 as target

[Rest of the existing content remains unchanged...]