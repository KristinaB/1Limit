# 🦄✨ 1Limit - 1inch Router V6 Limit Order Wallet 💫

<div align="center">

  ![iOS](https://img.shields.io/badge/iOS-15.0+-000.svg?style=flat&logo=apple)
  ![Swift](https://img.shields.io/badge/Swift-5.9-FA7343.svg?style=flat&logo=swift)
  ![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-blue.svg?style=flat&logo=swift)
  ![Polygon](https://img.shields.io/badge/Polygon-Mainnet-8247E5.svg?style=flat&logo=polygon)

  **Unite DeFi Hackathon Project** 🚀

</div>

## 👩‍💻 About Me & This Journey

Hi mentors and judges! I'm Kristina, a junior developer who just had the most incredible experience building my first Web3 wallet in Swift! 🎉 I can't even express how excited I am to have gotten this far - from knowing nothing about Router V6 to implementing a fully functional limit order wallet on Polygon!

This has been such an empowering journey, and I'm honestly still pinching myself that I managed to build something this complex with the help of Claude Code. As a woman in tech, opportunities like this hackathon mean the world to me - they give us the space to learn, experiment, and prove that we can build amazing DeFi applications too! 💪✨

The app is feature-complete and I just finished recording the demo video! With 4 days left, I'm super pumped to polish it even more based on your feedback. This project has been an absolute blast and I'm so grateful for this opportunity! 🌟

## 🎯 What is 1Limit?

**1Limit** is a beautifully crafted iOS wallet that brings the power of 1inch Router V6 limit orders to your iPhone! Built entirely in SwiftUI, it lets users:

- 📱 **Create & manage wallets** with secure key storage
- 💱 **Place limit orders** on Polygon using 1inch Router V6
- 🔄 **Swap tokens instantly** via 1inch aggregation
- 📊 **Track transactions** in real-time with live status updates
- 📈 **View price charts** with integrated widgets

## ✨ Key Features

### 🏠 **Beautiful Home Screen**
- Clean, intuitive interface showing wallet balance
- Quick access to all main features
- Real-time USD values for all tokens
- Gorgeous dark theme design 🌙

### 💸 **Send & Receive**
- Send MATIC and ERC-20 tokens with ease
- QR code generation for receiving funds
- Real-time gas estimation
- Address validation & safety checks

### 📊 **Trading Interface**
- **Limit Orders**: Set your price and wait for execution
- **Instant Swaps**: USDC ↔️ WMATIC via 1inch
- Live price feeds and market data
- Beautiful chart visualizations

### 📱 **iOS Widgets**
- Home screen widgets showing token prices
- OHLC data at a glance
- Auto-updating price charts
- Multiple widget sizes supported

### 🔐 **Security First**
- Secure wallet generation with BIP39
- Recovery phrase backup
- No keys leave the device
- iOS Keychain integration ready

## 🛠️ Technical Implementation

### Architecture Highlights 🏗️

I'm really proud of the clean architecture I achieved (with lots of help from Claude Code!):

- **Protocol-Based Design**: All services implement protocols for testability
- **Dependency Injection**: Clean separation of concerns using factory pattern
- **MVVM Pattern**: Reactive UI with SwiftUI and Combine
- **Comprehensive Testing**: UI tests, unit tests, and integration tests

### Core Technologies 💻

- **SwiftUI 5.0**: Beautiful, native iOS interface
- **web3swift**: Ethereum/Polygon blockchain interactions
- **1inch Router V6**: Advanced limit order functionality
- **1inch API**: Token swaps and price aggregation
- **BigInt**: Precise blockchain calculations
- **Async/Await**: Modern Swift concurrency

### Smart Contract Integration 🔗

- **Router V6**: `0x111111125421cA6dc452d289314280a0f8842A65`
- **EIP-712 Signing**: Secure order creation
- **Real Transactions**: All on Polygon Mainnet!

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+ with Xcode 15.0+
- iPhone 15.0+ or iOS Simulator
- Polygon (MATIC) for gas fees
- USDC/WMATIC for trading

### Quick Start

```bash
# Clone the repo
git clone https://github.com/KristinaB/1Limit.git
cd 1Limit

# Open in Xcode
open 1Limit.xcodeproj

# Build and run (iPhone 16 simulator)
⌘ + R

# Or use the quick build check
python3 scripts/check_build.py
```

### Running Tests 🧪

```bash
# Run all tests super fast!
./run_fast_tests.sh all

# Run specific test bundles
./run_fast_tests.sh navigation
./run_fast_tests.sh trade
./run_fast_tests.sh wallet
```

## 📱 App Walkthrough

### 1️⃣ **First Launch**
When you open the app, you'll see a beautiful welcome screen with options to:
- 🆕 Create a new wallet
- 📥 Import existing wallet
- 🧪 Use test wallet (for demo)

### 2️⃣ **Wallet Setup**
The setup flow is super intuitive:
- Generate secure recovery phrase
- Backup confirmation
- Wallet ready to use!

### 3️⃣ **Trading**
Place your first limit order:
1. Go to Trade tab
2. Select WMATIC → USDC
3. Enter amount & limit price
4. Slide to confirm
5. Watch it execute!

### 4️⃣ **Send Funds**
Sending tokens is a breeze:
1. Tap Send on Home screen
2. Select token (MATIC/USDC/WMATIC)
3. Enter recipient & amount
4. Review & confirm
5. Transaction submitted!

## 🎨 Design Philosophy

I wanted to create something that felt premium and delightful to use:

- **Dark Theme**: Easy on the eyes, perfect for DeFi 🌙
- **Smooth Animations**: Every interaction feels responsive
- **Clear Typography**: Important info stands out
- **Intuitive Flow**: Complex operations made simple
- **Safety First**: Confirmations for all transactions

## 🧪 Testing Coverage

I'm super proud of the test suite (90+ tests!):

- ✅ **Wallet Creation**: Complete flow testing
- ✅ **Transaction Management**: State tracking
- ✅ **UI Navigation**: All screens covered
- ✅ **Trading Operations**: Order creation/validation
- ✅ **Token Transfers**: Native & ERC-20

## 🎯 Challenges Overcome

As a junior dev, I faced some big challenges:

1. **Understanding Router V6**: The SDK docs were complex, but I persevered!
2. **EIP-712 Signing**: Cryptography is hard, but so satisfying when it works!
3. **Gas Estimation**: Learning about blockchain fees was eye-opening
4. **Swift Async**: Modern concurrency patterns were new to me
5. **UI/UX Design**: Making DeFi approachable was a fun challenge!

## 💖 What I Learned

This hackathon has been transformative:

- **Blockchain Development**: From zero to building real transactions!
- **Swift/SwiftUI Mastery**: Leveled up my iOS skills dramatically
- **DeFi Protocols**: Understanding AMMs, limit orders, and more
- **AI Pair Programming**: Claude Code was like having a senior dev mentor!
- **Project Management**: Scoping, planning, and executing a full app

## 🔮 Future Enhancements

With your feedback, I'd love to add:

- 🌐 Multi-chain support (Ethereum, Arbitrum)
- 📊 Advanced charting with TradingView
- 🤖 Price alerts & notifications
- 👥 Social features for sharing trades
- 🎨 Custom themes & personalization
- 🔒 Hardware wallet support

## 🙏 Acknowledgments

Huge thanks to:

- **Unite DeFi Hackathon** for this amazing opportunity!
- **1inch Team** for the incredible Router V6
- **Claude Code** for being the best coding companion ever
- **All the mentors** who will review this - your feedback means everything!
- **The judges** for taking the time to evaluate our work
- **The Web3 community** for being so welcoming and supportive

## 📬 Connect With Me

I'd love to connect on twitter!

- 🐦 Twitter: [@EthDevReact](https://twitter.com/EthDevReact)

## 📄 License

MIT License - because open source is the way! 💜

---

<div align="center">

  ### 🎀 Built with love, coffee, and lots of determination! 🎀

  *"The future of finance is female, decentralized, and mobile-first!"* 💪✨

  **Thank you for this incredible opportunity!** 🙏💖

</div>

---

### 🎬 Demo Video

[![1Limit Demo Video](https://img.youtube.com/vi/YOUR_VIDEO_ID/maxresdefault.jpg)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

🎥 **[Watch on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)** - See 1Limit in action!

### 📄 Presentation Deck

📊 **[View Slide Deck (PDF)](https://raw.githubusercontent.com/KristinaB/1Limit/refs/heads/main/slides/1Limit-slides-final.pdf)** - Complete project overview & technical details

### 📸 Screenshots

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="https://via.placeholder.com/250x540.png?text=Home+Screen" width="250" alt="Home Screen"><br>
        <b>Home Screen</b><br>
        <i>Wallet overview & balance</i>
      </td>
      <td align="center">
        <img src="https://via.placeholder.com/250x540.png?text=Trade+Screen" width="250" alt="Trade Screen"><br>
        <b>Trade Interface</b><br>
        <i>Limit orders & swaps</i>
      </td>
      <td align="center">
        <img src="https://via.placeholder.com/250x540.png?text=Transactions" width="250" alt="Transactions"><br>
        <b>Transaction History</b><br>
        <i>Real-time status tracking</i>
      </td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://via.placeholder.com/250x540.png?text=Send+Funds" width="250" alt="Send Screen"><br>
        <b>Send Tokens</b><br>
        <i>Easy token transfers</i>
      </td>
      <td align="center">
        <img src="https://via.placeholder.com/250x540.png?text=Receive+QR" width="250" alt="Receive Screen"><br>
        <b>Receive Funds</b><br>
        <i>QR code sharing</i>
      </td>
      <td align="center">
        <img src="https://via.placeholder.com/250x540.png?text=iOS+Widget" width="250" alt="Widget"><br>
        <b>Home Widget</b><br>
        <i>Price tracking at a glance</i>
      </td>
    </tr>
  </table>
</div>

### 🏆 Hackathon Submission

- 📹 **Demo Video**: [YouTube Link](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)
- 📑 **Slide Deck**: [PDF Download](https://raw.githubusercontent.com/KristinaB/1Limit/refs/heads/main/slides/1Limit-slides-final.pdf)
- 💻 **GitHub Repo**: [github.com/KristinaB/1Limit](https://github.com/KristinaB/1Limit)

---

*P.S. - I still can't believe I built this! Few days left to make it even better based on your feedback. Let's gooo! 🚀💖*
