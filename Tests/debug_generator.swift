#!/usr/bin/swift

// Quick test to see what generator produces for simple text field
print("Testing generator output for text field...")
print()

let expectedOutput = """
Should contain:
- "next": "Enter name address" or similar
- "label": "Name"
- "type": "TextField" or similar

Common issue: Maybe describeView() isn't returning proper data for simple views?
