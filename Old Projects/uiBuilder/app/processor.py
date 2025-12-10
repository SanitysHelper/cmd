#!/usr/bin/env python3
"""
uiBuilder Python Backend Processor

This demonstrates multi-language integration:
- Receives menu data as JSON via stdin or command-line args
- Processes the data (can do complex calculations, data analysis, etc.)
- Returns structured data back to PowerShell UI

Usage from PowerShell:
    $input = @{ menu = "data" } | ConvertTo-Json
    $output = python processor.py $input | ConvertFrom-Json
"""

import json
import sys
from datetime import datetime


def process_menu_data(data):
    """Process incoming menu data and return results."""
    
    # Example: Add metadata about processing
    result = {
        "status": "success",
        "timestamp": datetime.now().isoformat(),
        "input_received": data,
        "processing": {
            "items_processed": len(data.get("items", [])),
            "performance_ms": 42,
            "cache_hits": 15
        },
        "output": {
            "message": "Data processed successfully",
            "total_items": len(data.get("items", [])) if isinstance(data.get("items"), list) else 0
        }
    }
    
    return result


def process_calculation(operation, values):
    """Example: Perform calculations and return results."""
    
    try:
        if operation == "sum":
            result = sum(float(v) for v in values)
        elif operation == "average":
            result = sum(float(v) for v in values) / len(values)
        elif operation == "product":
            result = 1
            for v in values:
                result *= float(v)
        else:
            return {"status": "error", "message": f"Unknown operation: {operation}"}
        
        return {
            "status": "success",
            "operation": operation,
            "values": values,
            "result": result,
            "precision": 2
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


def main():
    """Main entry point."""
    
    try:
        # Check for command-line arguments first
        if len(sys.argv) > 1:
            # Argument passed as string
            input_data = json.loads(sys.argv[1])
        else:
            # Try to read from stdin
            input_str = sys.stdin.read().strip()
            if input_str:
                input_data = json.loads(input_str)
            else:
                # Default test data if nothing provided
                input_data = {
                    "mode": "test",
                    "items": ["item1", "item2", "item3"]
                }
        
        # Determine what to process
        if input_data.get("mode") == "calculation":
            result = process_calculation(
                input_data.get("operation", "sum"),
                input_data.get("values", [])
            )
        else:
            result = process_menu_data(input_data)
        
        # Output as JSON
        print(json.dumps(result, indent=2))
        
        # Exit with success code
        sys.exit(0)
        
    except json.JSONDecodeError as e:
        error_result = {
            "status": "error",
            "message": f"JSON parsing error: {str(e)}",
            "input_received": sys.argv[1] if len(sys.argv) > 1 else "(stdin)"
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(1)
        
    except Exception as e:
        error_result = {
            "status": "error",
            "message": f"Unexpected error: {str(e)}"
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
