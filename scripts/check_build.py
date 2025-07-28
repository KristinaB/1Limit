#!/usr/bin/env python3
"""
Build checker script for 1Limit iOS project
Runs xcodebuild and reports success/failure with clear output
"""

import subprocess
import sys
import time
from datetime import datetime

def run_build():
    """Run the iOS build and check if it succeeds"""
    print("🚀 Starting iOS build check...")
    print("=" * 50)
    
    start_time = time.time()
    
    # Build command
    cmd = [
        'xcodebuild',
        '-scheme', '1Limit',
        '-configuration', 'Debug',
        '-destination', 'platform=iOS Simulator,name=iPhone 16',
        'build'
    ]
    
    try:
        # Run the build command
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        end_time = time.time()
        build_time = end_time - start_time
        
        # Check the output for success/failure
        output_lines = result.stdout.split('\n')
        
        # Look for build result
        build_succeeded = False
        build_failed = False
        
        for line in output_lines:
            if "** BUILD SUCCEEDED **" in line:
                build_succeeded = True
                break
            elif "** BUILD FAILED **" in line:
                build_failed = True
                break
        
        # Count errors and warnings
        error_count = 0
        warning_count = 0
        errors = []
        warnings = []
        
        for line in output_lines:
            if ": error:" in line:
                error_count += 1
                errors.append(line.strip())
            elif ": warning:" in line:
                warning_count += 1
                warnings.append(line.strip())
        
        # Print results
        print(f"⏱️  Build time: {build_time:.1f} seconds")
        print(f"📊 Errors: {error_count}, Warnings: {warning_count}")
        print()
        
        if build_succeeded:
            print("✅ BUILD SUCCEEDED!")
            if warning_count > 0:
                print(f"⚠️  {warning_count} warnings found:")
                for warning in warnings[:5]:  # Show first 5 warnings
                    print(f"   {warning}")
                if len(warnings) > 5:
                    print(f"   ... and {len(warnings) - 5} more warnings")
            return True
        
        elif build_failed:
            print("❌ BUILD FAILED!")
            if error_count > 0:
                print(f"🚫 {error_count} errors found:")
                for error in errors:
                    print(f"   {error}")
            if warning_count > 0:
                print(f"⚠️  {warning_count} warnings found:")
                for warning in warnings[:3]:  # Show first 3 warnings
                    print(f"   {warning}")
            return False
        
        else:
            print("❓ BUILD STATUS UNKNOWN")
            print("Could not determine build result from output")
            return False
            
    except subprocess.TimeoutExpired:
        print("⏰ BUILD TIMEOUT!")
        print("Build took longer than 5 minutes")
        return False
        
    except subprocess.CalledProcessError as e:
        print(f"❌ BUILD COMMAND FAILED!")
        print(f"Return code: {e.returncode}")
        return False
        
    except Exception as e:
        print(f"💥 UNEXPECTED ERROR: {str(e)}")
        return False

def main():
    """Main function"""
    print(f"🕐 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    success = run_build()
    
    print()
    print("=" * 50)
    
    if success:
        print("🎉 Build check completed successfully!")
        sys.exit(0)
    else:
        print("💔 Build check failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()