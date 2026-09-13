import json
import urllib.request
import subprocess

try:
    url = f"https://firestore.googleapis.com/v1/projects/saas-snooker-club/databases/(default)/documents/clubs/bM6nwP2S64ZvJJaaV44q/staff"
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read())
        print("STAFF:")
        print(json.dumps(data, indent=2))
except Exception as e:
    print(f"Error: {e}")
