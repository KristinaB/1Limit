#!/usr/bin/env python3
"""
🔍 Wallet Transaction Checker for Polygon Mainnet
=====================================================

This script loads the wallet JSON file and checks if the wallet address
has any transactions on Polygon Mainnet using the public RPC endpoint.

Can also check specific transaction details for debugging Router V6 failures.

Ported wallet verification logic to complement the Swift Router V6 implementation.

Usage:
    python3 scripts/check_wallet_transactions.py                    # Check wallet activity
    python3 scripts/check_wallet_transactions.py --tx 0x123...     # Check specific transaction
    python3 scripts/check_wallet_transactions.py --latest          # Check latest transactions

Requirements:
    pip install requests

Author: Generated with Claude Code 🤖❤️🎉
"""

import json
import requests
import sys
import os
import argparse
from typing import Optional, Dict, Any

# Polygon Mainnet RPC endpoint (matching iOS app configuration)
POLYGON_RPC_URL = "https://polygon-bor-rpc.publicnode.com"

# Wallet file path (same as used in iOS app)
WALLET_FILE_PATH = "1Limit/wallet_0x3f847d.json"

class PolygonWalletChecker:
    """🏦 Polygon wallet transaction checker (ported from Go/Swift concepts)"""
    
    def __init__(self, rpc_url: str = POLYGON_RPC_URL):
        self.rpc_url = rpc_url
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'User-Agent': '1Limit-iOS-Wallet-Checker/1.0'
        })
    
    def load_wallet(self, wallet_path: str) -> Optional[Dict[str, str]]:
        """📁 Load wallet JSON file (matching Swift WalletLoader logic)"""
        try:
            if not os.path.exists(wallet_path):
                print(f"❌ Wallet file not found: {wallet_path}")
                return None
            
            with open(wallet_path, 'r') as f:
                wallet_data = json.load(f)
            
            # Validate wallet structure (matching Swift validation)
            if 'address' not in wallet_data or 'private_key' not in wallet_data:
                print("❌ Invalid wallet structure - missing address or private_key")
                return None
            
            address = wallet_data['address']
            private_key = wallet_data['private_key']
            
            # Basic validation (matching Swift patterns)
            if not address.startswith('0x') or len(address) != 42:
                print(f"❌ Invalid address format: {address}")
                return None
            
            if not private_key.startswith('0x') or len(private_key) != 66:
                print(f"❌ Invalid private key format")
                return None
            
            print(f"✅ Wallet loaded: {self.mask_address(address)}")
            print(f"🔐 Private key: {self.mask_private_key(private_key)}")
            
            return wallet_data
        
        except json.JSONDecodeError as e:
            print(f"❌ Failed to parse wallet JSON: {e}")
            return None
        except Exception as e:
            print(f"❌ Failed to load wallet: {e}")
            return None
    
    def mask_address(self, address: str) -> str:
        """🎭 Mask address for safe logging (matching Swift implementation)"""
        if len(address) < 10:
            return address
        return f"{address[:6]}...{address[-4:]}"
    
    def mask_private_key(self, private_key: str) -> str:
        """🔒 Mask private key for safe logging (matching Swift implementation)"""
        if len(private_key) < 10:
            return private_key
        return f"{private_key[:6]}..." + "*" * 56 + "***"
    
    def json_rpc_call(self, method: str, params: list) -> Optional[Dict[str, Any]]:
        """🌐 Make JSON-RPC call to Polygon node"""
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        }
        
        try:
            response = self.session.post(self.rpc_url, json=payload, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            if 'error' in data:
                print(f"❌ RPC Error: {data['error']}")
                return None
            
            return data.get('result')
        
        except requests.exceptions.RequestException as e:
            print(f"❌ Network error: {e}")
            return None
        except json.JSONDecodeError as e:
            print(f"❌ Failed to parse RPC response: {e}")
            return None
    
    def get_transaction_count(self, address: str) -> Optional[int]:
        """📊 Get transaction count (nonce) for address"""
        result = self.json_rpc_call("eth_getTransactionCount", [address, "latest"])
        if result is None:
            return None
        
        try:
            # Convert hex to int
            return int(result, 16)
        except ValueError as e:
            print(f"❌ Failed to parse transaction count: {e}")
            return None
    
    def get_balance(self, address: str) -> Optional[float]:
        """💰 Get MATIC balance for address"""
        result = self.json_rpc_call("eth_getBalance", [address, "latest"])
        if result is None:
            return None
        
        try:
            # Convert hex wei to MATIC
            balance_wei = int(result, 16)
            balance_matic = balance_wei / 10**18
            return balance_matic
        except ValueError as e:
            print(f"❌ Failed to parse balance: {e}")
            return None
    
    def get_latest_block(self) -> Optional[int]:
        """🧱 Get latest block number"""
        result = self.json_rpc_call("eth_blockNumber", [])
        if result is None:
            return None
        
        try:
            return int(result, 16)
        except ValueError as e:
            print(f"❌ Failed to parse block number: {e}")
            return None
    
    def check_wallet_activity(self, wallet_data: Dict[str, str]) -> bool:
        """🔍 Check if wallet has any activity on Polygon"""
        address = wallet_data['address']
        masked_address = self.mask_address(address)
        
        print(f"\n🔍 Checking wallet activity on Polygon Mainnet...")
        print(f"🏦 Address: {masked_address}")
        print(f"🌐 RPC: {self.rpc_url}")
        
        # Check latest block to verify RPC connection
        print(f"\n📋 Step 1: Verifying RPC connection...")
        latest_block = self.get_latest_block()
        if latest_block is None:
            print("❌ Failed to connect to Polygon RPC")
            return False
        
        print(f"✅ Connected to Polygon! Latest block: {latest_block:,}")
        
        # Check transaction count
        print(f"\n📋 Step 2: Checking transaction count...")
        tx_count = self.get_transaction_count(address)
        if tx_count is None:
            print("❌ Failed to get transaction count")
            return False
        
        print(f"📊 Transaction count (nonce): {tx_count}")
        
        # Check balance
        print(f"\n📋 Step 3: Checking MATIC balance...")
        balance = self.get_balance(address)
        if balance is None:
            print("❌ Failed to get balance")
            return False
        
        print(f"💰 MATIC balance: {balance:.6f} MATIC")
        
        # Determine activity status
        has_activity = tx_count > 0 or balance > 0
        
        print(f"\n{'='*50}")
        if has_activity:
            print(f"🎉 Wallet has activity on Polygon!")
            if tx_count > 0:
                print(f"   📤 Transactions sent: {tx_count}")
            if balance > 0:
                print(f"   💎 Current balance: {balance:.6f} MATIC")
        else:
            print(f"😴 Wallet has no activity on Polygon")
            print(f"   📤 No transactions sent")
            print(f"   💰 Zero balance")
        print(f"{'='*50}")
        
        return has_activity
    
    def get_transaction_receipt(self, tx_hash: str) -> Optional[Dict[str, Any]]:
        """📋 Get transaction receipt for analysis"""
        result = self.json_rpc_call("eth_getTransactionReceipt", [tx_hash])
        return result
    
    def get_transaction_details(self, tx_hash: str) -> Optional[Dict[str, Any]]:
        """📄 Get transaction details"""
        result = self.json_rpc_call("eth_getTransactionByHash", [tx_hash])
        return result
    
    def analyze_transaction(self, tx_hash: str) -> bool:
        """🔍 Analyze specific transaction for Router V6 debugging"""
        print(f"🔍 Analyzing transaction: {tx_hash}")
        print(f"🌐 RPC: {self.rpc_url}\n")
        
        # Get transaction details
        print("📋 Step 1: Getting transaction details...")
        tx_details = self.get_transaction_details(tx_hash)
        if tx_details is None:
            print("❌ Transaction not found or network error")
            return False
        
        print("✅ Transaction found!")
        print(f"   📤 From: {self.mask_address(tx_details.get('from', 'unknown'))}")
        print(f"   📥 To: {self.mask_address(tx_details.get('to', 'unknown'))}")
        print(f"   💰 Value: {int(tx_details.get('value', '0x0'), 16) / 10**18:.6f} MATIC")
        print(f"   ⛽ Gas Limit: {int(tx_details.get('gas', '0x0'), 16):,}")
        print(f"   💸 Gas Price: {int(tx_details.get('gasPrice', '0x0'), 16) / 10**9:.1f} gwei")
        
        # Get transaction receipt
        print("\n📋 Step 2: Getting transaction receipt...")
        receipt = self.get_transaction_receipt(tx_hash)
        if receipt is None:
            print("❌ Transaction receipt not found")
            return False
        
        status = receipt.get('status', '0x0')
        success = status == '0x1'
        
        print(f"✅ Transaction receipt found!")
        print(f"   📊 Status: {'SUCCESS' if success else 'FAILED'}")
        print(f"   🧱 Block: {int(receipt.get('blockNumber', '0x0'), 16):,}")
        print(f"   ⛽ Gas Used: {int(receipt.get('gasUsed', '0x0'), 16):,}")
        
        if not success:
            print(f"\n❌ Transaction failed on-chain!")
            print(f"💡 This means the transaction reached Polygon but Router V6 contract rejected it")
            print(f"🔗 View on Polygonscan: https://polygonscan.com/tx/{tx_hash}")
        else:
            print(f"\n✅ Transaction succeeded!")
            print(f"🔗 View on Polygonscan: https://polygonscan.com/tx/{tx_hash}")
        
        return success
    
    def get_recent_transactions(self, address: str, count: int = 5) -> None:
        """📋 Get recent transactions for debugging (simplified approach)"""
        print(f"📋 Recent transactions for {self.mask_address(address)}:")
        print("💡 Note: This requires a more complex API or indexing service")
        print("🔗 Check manually on Polygonscan: https://polygonscan.com/address/" + address)

def main():
    """🚀 Main execution function"""
    parser = argparse.ArgumentParser(description="🔍 1Limit Wallet Transaction Checker")
    parser.add_argument("--tx", "--transaction", help="🔍 Check specific transaction hash")
    parser.add_argument("--latest", action="store_true", help="📋 Show latest transactions")
    
    args = parser.parse_args()
    
    print("🚀 1Limit Wallet Transaction Checker")
    print("=====================================")
    
    # Initialize checker
    checker = PolygonWalletChecker()
    
    if args.tx:
        # Check specific transaction
        print("🔍 Transaction Analysis Mode")
        print("🌐 Using public RPC endpoint")
        print("💎 Debugging Router V6 transaction\n")
        
        success = checker.analyze_transaction(args.tx)
        print(f"\n🎯 Result: Transaction {'SUCCEEDED' if success else 'FAILED'}")
        print("💖 Generated with Claude Code 🤖❤️🎉")
        sys.exit(0 if success else 1)
    
    elif args.latest:
        # Show latest transactions
        print("📋 Latest Transactions Mode")
        print("💎 Ported from Swift Router V6 implementation\n")
        
        wallet_data = checker.load_wallet(WALLET_FILE_PATH)
        if wallet_data is None:
            print("\n❌ Cannot proceed without valid wallet")
            sys.exit(1)
        
        checker.get_recent_transactions(wallet_data['address'])
        print("💖 Generated with Claude Code 🤖❤️🎉")
        sys.exit(0)
    
    else:
        # Default wallet activity check
        print("🔍 Checking wallet activity on Polygon Mainnet")
        print("🌐 Using public RPC endpoint")
        print("💎 Ported from Swift Router V6 implementation\n")
        
        # Load wallet
        wallet_data = checker.load_wallet(WALLET_FILE_PATH)
        if wallet_data is None:
            print("\n❌ Cannot proceed without valid wallet")
            sys.exit(1)
        
        # Check wallet activity
        has_activity = checker.check_wallet_activity(wallet_data)
        
        print(f"\n🎯 Result: {'ACTIVE' if has_activity else 'INACTIVE'} wallet")
        print("💖 Generated with Claude Code 🤖❤️🎉")
        
        # Exit with appropriate code
        sys.exit(0 if has_activity else 1)

if __name__ == "__main__":
    main()