#!/usr/bin/env python3

import requests
import json
from web3 import Web3

# Transaction details
FAILED_TX_HASH = "0x14a0cda5e295672191e9538d00cb54de934c247b22cee5ab63f3b8775e284d5e"
RPC_URL = "https://polygon-bor-rpc.publicnode.com"

print("🔍 1Limit Failed Transaction Debugger")
print("====================================")
print(f"🚨 Analyzing failed transaction: {FAILED_TX_HASH}")
print(f"📊 Direction: USDC → WMATIC (reverse direction)")
print(f"💰 Amount: 1 USDC")
print(f"🎯 Limit Price: 3 WMATIC per USDC")
print()

# Initialize Web3
w3 = Web3(Web3.HTTPProvider(RPC_URL))

try:
    # Get transaction receipt
    print("📋 Step 1: Getting transaction receipt...")
    receipt = w3.eth.get_transaction_receipt(FAILED_TX_HASH)
    
    print(f"✅ Transaction found!")
    print(f"📦 Block Number: {receipt['blockNumber']}")
    print(f"⛽ Gas Used: {receipt['gasUsed']:,}")
    print(f"💸 Gas Price: {receipt['effectiveGasPrice']:,} wei")
    print(f"❌ Status: {'Success' if receipt['status'] == 1 else 'Failed'}")
    print(f"📍 Contract: {receipt['to']}")
    print()
    
    # Get transaction details
    print("📋 Step 2: Getting transaction details...")
    tx = w3.eth.get_transaction(FAILED_TX_HASH)
    
    print(f"👤 From: {tx['from']}")
    print(f"📍 To: {tx['to']}")
    print(f"💰 Value: {w3.from_wei(tx['value'], 'ether')} ETH")
    print(f"⛽ Gas Limit: {tx['gas']:,}")
    print()
    
    # Analyze transaction input data
    print("📋 Step 3: Analyzing transaction input data...")
    input_data = tx['input'].hex()
    print(f"📝 Method ID: {input_data[:10]}")
    
    # Check if it's fillOrder method (0x9fda64bd)
    if input_data[:10] == "0x9fda64bd":
        print("✅ Method: fillOrder - Router V6 limit order execution")
    else:
        print(f"❓ Unknown method: {input_data[:10]}")
    
    print(f"📏 Input Data Length: {len(input_data)} characters")
    print()
    
    # Analyze logs for failure reasons
    print("📋 Step 4: Analyzing event logs...")
    if len(receipt['logs']) > 0:
        print(f"📊 Found {len(receipt['logs'])} event logs:")
        
        for i, log in enumerate(receipt['logs']):
            print(f"  📝 Log {i+1}:")
            print(f"    📍 Address: {log['address']}")
            print(f"    📋 Topics: {len(log['topics'])} topics")
            if len(log['topics']) > 0:
                print(f"    🏷️  Event Signature: {log['topics'][0].hex()}")
            print()
    else:
        print("❌ No event logs found")
    
    # Check for revert reason
    print("📋 Step 5: Checking for revert reason...")
    
    # Try to get transaction trace (may not work on all RPC providers)
    try:
        trace_response = requests.post(RPC_URL, json={
            "jsonrpc": "2.0",
            "method": "debug_traceTransaction",
            "params": [FAILED_TX_HASH, {"tracer": "callTracer"}],
            "id": 1
        })
        
        if trace_response.status_code == 200:
            trace_data = trace_response.json()
            if 'result' in trace_data:
                print("✅ Transaction trace available")
                # Analyze trace for revert reason
                if 'revertReason' in trace_data['result']:
                    print(f"🚨 Revert Reason: {trace_data['result']['revertReason']}")
                else:
                    print("❓ No specific revert reason in trace")
            else:
                print("❌ No trace result available")
        else:
            print("❌ Trace request failed")
    except Exception as e:
        print(f"❌ Could not get transaction trace: {e}")
    
    print()
    print("🔧 Analysis Summary:")
    print("==================")
    print("🚨 Transaction FAILED during execution")
    print("💡 Possible reasons for USDC → WMATIC swap failure:")
    print("   1. 🎯 Limit price too high (3 WMATIC per USDC)")
    print("   2. 💰 Insufficient USDC balance or allowance")
    print("   3. 📊 Market conditions - price didn't reach limit")
    print("   4. ⛽ Gas limit too low for complex swap")
    print("   5. 🔒 Token approval issues")
    print("   6. 🏗️  Router V6 contract state issues")
    print()
    print("🔍 Next steps:")
    print("   1. Check USDC balance and allowance")
    print("   2. Verify limit price is reasonable")
    print("   3. Check current USDC/WMATIC market price")
    print("   4. Review Router V6 order parameters")
    
except Exception as e:
    print(f"❌ Error analyzing transaction: {e}")

print()
print("💖 Generated with Claude Code 🤖❤️🎉")