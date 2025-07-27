#!/usr/bin/env python3

import requests
import json
from web3 import Web3

# Transaction details
FAILED_TX_HASH = "0x5939651d78b17fd8d1a0cfca79c47cbe58c7d14f620cf76738fa5980526e8f16"
RPC_URL = "https://polygon-bor-rpc.publicnode.com"
ROUTER_V6 = "0x111111125421cA6dc452d289314280a0f8842A65"
USDC_CONTRACT = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
WMATIC_CONTRACT = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"

print("🔍 Quick Transaction Analysis")
print("============================")
print(f"TX: {FAILED_TX_HASH}")
print()

# Initialize Web3
w3 = Web3(Web3.HTTPProvider(RPC_URL))

try:
    # Get transaction details
    tx = w3.eth.get_transaction(FAILED_TX_HASH)
    receipt = w3.eth.get_transaction_receipt(FAILED_TX_HASH)
    
    print(f"🎯 Status: {'SUCCESS' if receipt['status'] == 1 else 'FAILED'}")
    print(f"⛽ Gas Used: {receipt['gasUsed']:,}")
    print(f"💰 Gas Price: {tx['gasPrice']:,} wei")
    print(f"💸 Transaction Fee: {receipt['gasUsed'] * tx['gasPrice'] / 10**18:.6f} MATIC")
    print(f"👤 From: {tx['from']}")
    print(f"🎯 To: {tx['to']}")
    print(f"💰 Value: {tx['value']} wei")
    print()
    
    # Decode input data
    input_data = tx['input'].hex()
    if input_data.startswith("0x9fda64bd"):
        print("✅ Method: fillOrder")
        
        # Extract the transaction parameters more carefully
        params_data = input_data[10:]  # Remove method signature
        
        # Parse order parameters (simplified)
        print("📋 Order Parameters:")
        
        # Each parameter is 64 hex chars (32 bytes)
        chunks = [params_data[i:i+64] for i in range(0, len(params_data), 64)]
        
        if len(chunks) >= 12:  # fillOrder has 12 parameters
            salt = int(chunks[0], 16) if chunks[0] else 0
            maker = "0x" + chunks[1][-40:] if len(chunks[1]) >= 40 else "0x" + chunks[1].zfill(40)
            receiver = "0x" + chunks[2][-40:] if len(chunks[2]) >= 40 else "0x" + chunks[2].zfill(40)
            makerAsset = "0x" + chunks[3][-40:] if len(chunks[3]) >= 40 else "0x" + chunks[3].zfill(40)
            takerAsset = "0x" + chunks[4][-40:] if len(chunks[4]) >= 40 else "0x" + chunks[4].zfill(40)
            makingAmount = int(chunks[5], 16) if chunks[5] else 0
            takingAmount = int(chunks[6], 16) if chunks[6] else 0
            
            print(f"   Salt: {salt}")
            print(f"   Maker: {maker}")
            print(f"   Receiver: {receiver}")
            print(f"   Maker Asset: {makerAsset}")
            print(f"   Taker Asset: {takerAsset}")
            print(f"   Making Amount: {makingAmount}")
            print(f"   Taking Amount: {takingAmount}")
            print()
            
            # Check token types
            print("🔍 Token Analysis:")
            if makerAsset.lower() == USDC_CONTRACT.lower():
                usdc_amount = makingAmount / 10**6
                print(f"   Maker Asset: USDC ({usdc_amount} USDC)")
            elif makerAsset.lower() == WMATIC_CONTRACT.lower():
                wmatic_amount = makingAmount / 10**18
                print(f"   Maker Asset: WMATIC ({wmatic_amount} WMATIC)")
            else:
                print(f"   Maker Asset: Unknown ({makerAsset})")
                
            if takerAsset.lower() == USDC_CONTRACT.lower():
                usdc_amount = takingAmount / 10**6
                print(f"   Taker Asset: USDC ({usdc_amount} USDC)")
            elif takerAsset.lower() == WMATIC_CONTRACT.lower():
                wmatic_amount = takingAmount / 10**18
                print(f"   Taker Asset: WMATIC ({wmatic_amount} WMATIC)")
            else:
                print(f"   Taker Asset: Unknown ({takerAsset})")
        print()
    
    # Check wallet state at transaction time
    print("💰 Wallet State at Transaction Time:")
    block_number = receipt['blockNumber']
    wallet = tx['from']
    
    # Check USDC balance
    balance_request = {
        "jsonrpc": "2.0",
        "method": "eth_call",
        "params": [{
            "to": USDC_CONTRACT,
            "data": "0x70a08231" + wallet[2:].zfill(64)
        }, hex(block_number)],
        "id": 1
    }
    
    response = requests.post(RPC_URL, json=balance_request)
    if response.status_code == 200:
        result = response.json()
        if 'result' in result and result['result'] != '0x':
            usdc_balance = int(result['result'], 16) / 10**6
            print(f"   USDC Balance: {usdc_balance} USDC")
        else:
            print("   USDC Balance: 0 USDC")
    
    # Check WMATIC balance  
    try:
        wmatic_balance = w3.eth.get_balance(wallet, block_identifier=block_number) / 10**18
        print(f"   MATIC Balance: {wmatic_balance:.6f} MATIC")
    except:
        print("   MATIC Balance: Could not fetch")
    
    print()
    print("🚨 Likely Failure Reasons:")
    print("1. 🎯 Limit price not achievable at current market rates")
    print("2. ⏰ Order expired (timestamp/deadline passed)")
    print("3. ✍️  EIP-712 signature validation failed")
    print("4. 🔢 Nonce/salt already used (duplicate order)")
    print("5. 💎 Order conditions not met (Router V6 validation)")

except Exception as e:
    print(f"❌ Error during analysis: {e}")

print()
print("💖 Generated with Claude Code 🤖❤️🎉")