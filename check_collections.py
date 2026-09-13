import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# We don't have a service account JSON, so we can use the default credentials if gcloud is logged in.
try:
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {
        'projectId': 'saas-snooker-club',
    })

    db = firestore.client()
    club_ref = db.collection('clubs').document('cuezone')
    collections = club_ref.collections()
    for coll in collections:
        print(coll.id)
except Exception as e:
    print(f"Error: {e}")
