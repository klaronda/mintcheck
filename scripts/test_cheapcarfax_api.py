#!/usr/bin/env python3
"""
Test CheapCARFAX API from Python (panel.cheapcarfax.net, x-api-key).

Usage:
  CHEAPCARFAX_API_KEY=your_key python scripts/test_cheapcarfax_api.py
  CHEAPCARFAX_API_KEY=your_key TEST_VIN=1HGBH41JXMN109186 python scripts/test_cheapcarfax_api.py
"""
import json
import os
import sys

try:
    import requests
except ImportError:
    print("Install requests: pip install requests", file=sys.stderr)
    sys.exit(1)

API_KEY = os.environ.get("CHEAPCARFAX_API_KEY")
VIN = os.environ.get("TEST_VIN", "JH4DC4360SS001610")

if not API_KEY:
    print("Set CHEAPCARFAX_API_KEY in the environment.", file=sys.stderr)
    sys.exit(1)

url = f"https://panel.cheapcarfax.net/api/carfax/vin/{VIN}/html"
headers = {"x-api-key": API_KEY}

print(f"GET {url}")
response = requests.get(url, headers=headers)
print(f"Status: {response.status_code}")
print(f"Content-Type: {response.headers.get('Content-Type', '')}")

# Try JSON first (like your snippet: response.json())
try:
    data = response.json()
    print("Response (JSON):")
    if isinstance(data, dict):
        if "html" in data:
            print(f"  yearMakeModel: {data.get('yearMakeModel')}")
            print(f"  id: {data.get('id')}")
            print(f"  html length: {len(data.get('html', ''))} chars")
        # Print JSON with html replaced by "<...>" so output is readable
        summary = {k: ("<...>" if k == "html" else v) for k, v in data.items()} if isinstance(data, dict) else data
        print(json.dumps(summary, indent=2))
except (ValueError, TypeError):
    # Not JSON: show start of body (e.g. Cloudflare HTML)
    print("Body (first 500 chars):", response.text[:500])
    if "cloudflare" in response.text.lower() or "Just a moment" in response.text:
        print("\n-> Cloudflare challenge page.")
