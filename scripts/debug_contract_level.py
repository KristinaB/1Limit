#!/usr/bin/env python3

import requests
import json
from web3 import Web3

# Transaction details
FAILED_TX_HASH = "0x14a0cda5e295672191e9538d00cb54de934c247b22cee5ab63f3b8775e284d5e"
RPC_URL = "https://polygon-bor-rpc.publicnode.com"
ROUTER_V6 = "0x111111125421cA6dc452d289314280a0f8842A65"
USDC_CONTRACT = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
WMATIC_CONTRACT = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"

print("🔍 1Limit Contract-Level Transaction Debugger")
print("============================================")
print(f"🚨 Analyzing failed transaction: {FAILED_TX_HASH}")
print(f"🏗️  Router V6 Contract: {ROUTER_V6}")
print()

# Initialize Web3
w3 = Web3(Web3.HTTPProvider(RPC_URL))

try:
    # Get transaction details
    print("📋 Step 1: Analyzing transaction input data...")
    tx = w3.eth.get_transaction(FAILED_TX_HASH)
    receipt = w3.eth.get_transaction_receipt(FAILED_TX_HASH)
    
    input_data = tx['input'].hex()
    print(f"📝 Full Input Data: {input_data}")
    print(f"📏 Length: {len(input_data)} characters")
    print()
    
    # Decode fillOrder parameters
    if input_data.startswith("0x9fda64bd"):
        print("✅ Method: fillOrder(tuple order, bytes32 r, bytes32 vs, uint256 amount, uint256 takerTraits)")
        print()
        
        # Remove method ID and decode parameters
        params_data = input_data[10:]  # Remove 0x9fda64bd
        print(f"📊 Parameters data: {params_data}")
        print(f"📏 Parameters length: {len(params_data)} characters")
        print()
        
        # Decode individual parameters (each is 64 characters / 32 bytes)
        print("🔧 Decoding fillOrder parameters:")
        
        # Order tuple components (first 8 * 64 = 512 characters)
        order_data = params_data[:512]
        print(f"📦 Order tuple data: {order_data}")
        
        # Extract order fields (32 bytes each)
        salt = int(order_data[0:64], 16)
        maker = "0x" + order_data[64:128][-40:]  # Last 40 chars (20 bytes)
        receiver = "0x" + order_data[128:192][-40:]
        makerAsset = "0x" + order_data[192:256][-40:]
        takerAsset = "0x" + order_data[256:320][-40:]
        makingAmount = int(order_data[320:384], 16)
        takingAmount = int(order_data[384:448], 16)
        makerAssetData = "0x" + order_data[448:512]
        
        print(f"  🧂 Salt: {salt}")
        print(f"  👤 Maker: {maker}")
        print(f"  📨 Receiver: {receiver}")
        print(f"  💰 Maker Asset: {makerAsset}")
        print(f"  💱 Taker Asset: {takerAsset}")
        print(f"  📈 Making Amount: {makingAmount}")
        print(f"  📉 Taking Amount: {takingAmount}")
        print()
        
        # Check token addresses
        print("🔍 Token Analysis:")
        if makerAsset.lower() == USDC_CONTRACT.lower():
            print(f"  ✅ Maker Asset: USDC ({makerAsset})")
        elif makerAsset.lower() == WMATIC_CONTRACT.lower():
            print(f"  ✅ Maker Asset: WMATIC ({makerAsset})")
        else:
            print(f"  ❓ Unknown Maker Asset: {makerAsset}")
            
        if takerAsset.lower() == USDC_CONTRACT.lower():
            print(f"  ✅ Taker Asset: USDC ({takerAsset})")
        elif takerAsset.lower() == WMATIC_CONTRACT.lower():
            print(f"  ✅ Taker Asset: WMATIC ({takerAsset})")
        else:
            print(f"  ❓ Unknown Taker Asset: {takerAsset}")
        print()
        
        # Calculate exchange rate
        if makingAmount > 0 and takingAmount > 0:
            if makerAsset.lower() == USDC_CONTRACT.lower():
                # USDC has 6 decimals, WMATIC has 18 decimals
                usdc_amount = makingAmount / 10**6
                wmatic_amount = takingAmount / 10**18
                rate = wmatic_amount / usdc_amount
                print(f"💱 Exchange Rate: {usdc_amount} USDC → {wmatic_amount} WMATIC")
                print(f"🎯 Rate: {rate:.6f} WMATIC per USDC")
            else:
                # WMATIC → USDC
                wmatic_amount = makingAmount / 10**18
                usdc_amount = takingAmount / 10**6
                rate = usdc_amount / wmatic_amount
                print(f"💱 Exchange Rate: {wmatic_amount} WMATIC → {usdc_amount} USDC")
                print(f"🎯 Rate: {rate:.6f} USDC per WMATIC")
        print()
        
        # Get signature and amount parameters
        remaining_data = params_data[512:]
        
        # Parse r, vs, amount, takerTraits
        if len(remaining_data) >= 256:  # 4 params * 64 chars each
            r = "0x" + remaining_data[0:64]
            vs = "0x" + remaining_data[64:128]
            amount = int(remaining_data[128:192], 16)
            takerTraits = int(remaining_data[192:256], 16)
            
            print(f"✍️  Signature r: {r}")
            print(f"✍️  Signature vs: {vs}")
            print(f"💰 Fill Amount: {amount}")
            print(f"🏷️  Taker Traits: {takerTraits}")
            print()
    
    # Check wallet state at the time of transaction
    print("📋 Step 2: Checking wallet state at transaction block...")
    block_number = receipt['blockNumber']
    wallet = tx['from']
    
    # Check USDC balance
    usdc_balance_data = {
        "jsonrpc": "2.0",
        "method": "eth_call",
        "params": [{
            "to": USDC_CONTRACT,
            "data": "0x70a08231" + wallet[2:].zfill(64)  # balanceOf(address)
        }, hex(block_number)],
        "id": 1
    }
    
    response = requests.post(RPC_URL, json=usdc_balance_data)
    if response.status_code == 200:
        result = response.json()
        if 'result' in result and result['result'] != '0x':
            usdc_balance = int(result['result'], 16) / 10**6  # USDC has 6 decimals
            print(f"💰 USDC Balance: {usdc_balance} USDC")
        else:
            print("💰 USDC Balance: 0 USDC")
    
    # Check USDC allowance for Router V6
    allowance_data = {
        "jsonrpc": "2.0",
        "method": "eth_call",
        "params": [{
            "to": USDC_CONTRACT,
            "data": "0xdd62ed3e" + wallet[2:].zfill(64) + ROUTER_V6[2:].zfill(64)  # allowance(owner, spender)
        }, hex(block_number)],
        "id": 2
    }
    
    response = requests.post(RPC_URL, json=allowance_data)
    if response.status_code == 200:
        result = response.json()
        if 'result' in result and result['result'] != '0x':
            usdc_allowance = int(result['result'], 16) / 10**6
            print(f"🔐 USDC Allowance: {usdc_allowance} USDC")
        else:
            print("🔐 USDC Allowance: 0 USDC")
    print()
    
    # Analyze failure reasons
    print("🔧 Contract-Level Failure Analysis:")
    print("===================================")
    print("🚨 Transaction failed during Router V6 execution")
    print("⛽ Low gas usage (33,462) indicates early revert")
    print()
    print("💡 Most likely contract-level failures:")
    print("   1. 🔐 Insufficient USDC allowance for Router V6")
    print("   2. 💰 Insufficient USDC balance")
    print("   3. ✍️  Invalid order signature")
    print("   4. ⏰ Order expired or already filled")
    print("   5. 🚫 Order validation failed (invalid parameters)")
    print("   6. 🎯 Order conditions not met (price/slippage)")
    print()
    
    # Check current market conditions
    print("📊 Current market conditions check recommended:")
    print("   - Verify order parameters match intended swap")
    print("   - Check if limit price is achievable")
    print("   - Ensure proper token approvals")
    
except Exception as e:
    print(f"❌ Error during contract analysis: {e}")

print()
print("💖 Generated with Claude Code 🤖❤️🎉")