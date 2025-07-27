#!/usr/bin/env python3

import json
import requests
from web3 import Web3

# Configuration
WALLET_FILE = "1Limit/wallet_0x3f847d.json"
RPC_URL = "https://polygon-bor-rpc.publicnode.com"
ROUTER_V6 = "0x111111125421cA6dc452d289314280a0f8842A65"

# Token contracts on Polygon
TOKENS = {
    "WMATIC": {
        "address": "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
        "decimals": 18,
        "symbol": "WMATIC"
    },
    "USDC": {
        "address": "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359", 
        "decimals": 6,
        "symbol": "USDC"
    },
    "USDT": {
        "address": "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
        "decimals": 6, 
        "symbol": "USDT"
    },
    "DAI": {
        "address": "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
        "decimals": 18,
        "symbol": "DAI"
    }
}

print("💰 1Limit Wallet Balance & Approval Checker")
print("==========================================")
print(f"🔗 RPC: {RPC_URL}")
print(f"🏗️  Router V6: {ROUTER_V6}")
print()

def load_wallet():
    """Load wallet from JSON file"""
    try:
        with open(WALLET_FILE, 'r') as f:
            wallet_data = json.load(f)
        return wallet_data['address']
    except Exception as e:
        print(f"❌ Error loading wallet: {e}")
        return None

def check_balance(w3, token_address, wallet_address, decimals):
    """Check token balance"""
    try:
        # balanceOf(address) - function signature: 0x70a08231
        data = "0x70a08231" + wallet_address[2:].zfill(64)
        
        response = requests.post(RPC_URL, json={
            "jsonrpc": "2.0",
            "method": "eth_call", 
            "params": [{"to": token_address, "data": data}, "latest"],
            "id": 1
        })
        
        if response.status_code == 200:
            result = response.json()
            if 'result' in result and result['result'] != '0x':
                balance = int(result['result'], 16) / (10 ** decimals)
                return balance
        return 0.0
    except Exception as e:
        print(f"❌ Error checking balance: {e}")
        return 0.0

def check_allowance(w3, token_address, wallet_address, spender_address, decimals):
    """Check token allowance for spender"""
    try:
        # allowance(owner, spender) - function signature: 0xdd62ed3e  
        data = "0xdd62ed3e" + wallet_address[2:].zfill(64) + spender_address[2:].zfill(64)
        
        response = requests.post(RPC_URL, json={
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [{"to": token_address, "data": data}, "latest"], 
            "id": 1
        })
        
        if response.status_code == 200:
            result = response.json()
            if 'result' in result and result['result'] != '0x':
                allowance = int(result['result'], 16) / (10 ** decimals)
                return allowance
        return 0.0
    except Exception as e:
        print(f"❌ Error checking allowance: {e}")
        return 0.0

def check_matic_balance(w3, wallet_address):
    """Check native MATIC balance"""
    try:
        balance_wei = w3.eth.get_balance(wallet_address)
        return w3.from_wei(balance_wei, 'ether')
    except Exception as e:
        print(f"❌ Error checking MATIC balance: {e}")
        return 0.0

def format_balance(balance, symbol):
    """Format balance for display"""
    if balance == 0:
        return f"❌ 0 {symbol}"
    elif balance < 0.000001:
        return f"⚠️  {balance:.8f} {symbol}"
    elif balance < 1:
        return f"⚠️  {balance:.6f} {symbol}"
    else:
        return f"✅ {balance:.6f} {symbol}"

def format_allowance(allowance, symbol):
    """Format allowance for display"""
    if allowance == 0:
        return f"❌ No approval"
    elif allowance > 1e15:  # Very large number (likely MAX_UINT256)
        return f"✅ Unlimited approval"
    else:
        return f"✅ {allowance:.6f} {symbol} approved"

def main():
    # Load wallet
    wallet_address = load_wallet()
    if not wallet_address:
        return
    
    print(f"👛 Wallet: {wallet_address}")
    print()
    
    # Initialize Web3
    w3 = Web3(Web3.HTTPProvider(RPC_URL))
    
    if not w3.is_connected():
        print("❌ Failed to connect to RPC")
        return
    
    print("✅ Connected to Polygon RPC")
    print()
    
    # Check native MATIC balance
    print("🔵 Native MATIC Balance:")
    matic_balance = check_matic_balance(w3, wallet_address)
    print(f"   {format_balance(matic_balance, 'MATIC')}")
    print()
    
    # Check token balances and approvals
    print("💰 Token Balances & Router V6 Approvals:")
    print("=" * 50)
    
    for token_name, token_info in TOKENS.items():
        print(f"🪙 {token_name} ({token_info['address'][:10]}...):")
        
        # Check balance
        balance = check_balance(w3, token_info['address'], wallet_address, token_info['decimals'])
        print(f"   Balance: {format_balance(balance, token_name)}")
        
        # Check Router V6 allowance
        allowance = check_allowance(w3, token_info['address'], wallet_address, ROUTER_V6, token_info['decimals'])
        print(f"   Router V6: {format_allowance(allowance, token_name)}")
        
        # Trading readiness check
        if balance > 0 and allowance >= balance:
            print(f"   Status: ✅ Ready for trading")
        elif balance > 0 and allowance == 0:
            print(f"   Status: ⚠️  Has balance but needs approval")
        elif balance == 0:
            print(f"   Status: ❌ No balance - acquire {token_name} first")
        else:
            print(f"   Status: ⚠️  Insufficient approval")
        
        print()
    
    # Summary and recommendations
    print("📊 Trading Readiness Summary:")
    print("=" * 30)
    
    # Check WMATIC
    wmatic_balance = check_balance(w3, TOKENS['WMATIC']['address'], wallet_address, TOKENS['WMATIC']['decimals'])
    wmatic_allowance = check_allowance(w3, TOKENS['WMATIC']['address'], wallet_address, ROUTER_V6, TOKENS['WMATIC']['decimals'])
    
    # Check USDC  
    usdc_balance = check_balance(w3, TOKENS['USDC']['address'], wallet_address, TOKENS['USDC']['decimals'])
    usdc_allowance = check_allowance(w3, TOKENS['USDC']['address'], wallet_address, ROUTER_V6, TOKENS['USDC']['decimals'])
    
    print(f"🔄 WMATIC → USDC: {'✅ Ready' if wmatic_balance > 0 and wmatic_allowance >= wmatic_balance else '❌ Not Ready'}")
    print(f"🔄 USDC → WMATIC: {'✅ Ready' if usdc_balance > 0 and usdc_allowance >= usdc_balance else '❌ Not Ready'}")
    
    print()
    print("💡 Next Steps:")
    if usdc_balance == 0:
        print("   1. 💰 Acquire USDC (buy on exchange or swap MATIC→USDC)")
    if usdc_allowance == 0 and usdc_balance > 0:
        print("   2. 🔐 Approve Router V6 for USDC spending")
    if wmatic_allowance == 0 and wmatic_balance > 0:
        print("   3. 🔐 Approve Router V6 for WMATIC spending")
    
    print()
    print("🏗️  Router V6 Contract Address for approvals:")
    print(f"   {ROUTER_V6}")

if __name__ == "__main__":
    main()
    print()
    print("💖 Generated with Claude Code 🤖❤️🎉")