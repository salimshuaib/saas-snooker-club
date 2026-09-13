import json
import urllib.request

try:
    url = "https://firestore.googleapis.com/v1/projects/saas-snooker-club/databases/(default)/documents/clubs"
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read())
        print(json.dumps(data, indent=2))
except Exception as e:
    print(f"Error: {e}")
