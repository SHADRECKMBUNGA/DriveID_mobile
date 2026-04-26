import urllib.request
import json
import ssl

# Supabase credentials from the config
SUPABASE_URL = 'https://gpdoptmvqafdfsmjublp.supabase.co'
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwZG9wdG12cWFmZGZzbWp1YmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NDkyMTgsImV4cCI6MjA4OTQyNTIxOH0.qUgZr9-t5Yfwmxy6uQvu1C3Jm6-LiEmLAuB2SDygkyA'

def get_licenses():
    url = f"{SUPABASE_URL}/rest/v1/licenses"
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }

    # Create SSL context to handle certificates
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

def check_table_exists():
    # Try to get table info
    url = f"{SUPABASE_URL}/rest/v1/"
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx) as response:
            print(f"API endpoint accessible: {response.status}")
    except Exception as e:
        print(f"API access error: {e}")

def get_licenses():
    url = f"{SUPABASE_URL}/rest/v1/licenses?select=*"
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }

    # Create SSL context to handle certificates
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx) as response:
            data = response.read().decode('utf-8')
            licenses = json.loads(data)
            print(f"Found {len(licenses)} licenses:")
            for i, license in enumerate(licenses):
                print(f"License {i+1}:")
                for key, value in license.items():
                    print(f"  {key}: {value}")
                print()
    except Exception as e:
        print(f"Error accessing licenses: {e}")

if __name__ == "__main__":
    check_table_exists()
    get_licenses()