import json
import urllib.request
import subprocess

try:
    token = subprocess.check_output('firebase login:ci --print-access-token', shell=True, text=True).strip()
    # It might print warnings, let's just get the last word if it contains spaces
    token = token.split()[-1]
    
    url = f"https://firestore.googleapis.com/v1/projects/saas-snooker-club/databases/(default)/documents/user_clubs"
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {token}'})
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read())
        print("USER CLUBS:")
        print(json.dumps(data, indent=2))
        
    url2 = f"https://firestore.googleapis.com/v1/projects/saas-snooker-club/databases/(default)/documents/clubs"
    req2 = urllib.request.Request(url2, headers={'Authorization': f'Bearer {token}'})
    with urllib.request.urlopen(req2) as response:
        data2 = json.loads(response.read())
        print("CLUBS:")
        print(json.dumps(data2, indent=2))
        
except Exception as e:
    print(f"Error: {e}")
