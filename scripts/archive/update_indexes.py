import json

file_path = 'firestore.indexes.json'
with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Add indexes
new_indexes = [
  {
    "collectionGroup": "transactions",
    "queryScope": "COLLECTION_GROUP",
    "fields": [
      {
        "fieldPath": "clubId",
        "order": "ASCENDING"
      },
      {
        "fieldPath": "date",
        "order": "DESCENDING"
      }
    ]
  },
  {
    "collectionGroup": "transactions",
    "queryScope": "COLLECTION_GROUP",
    "fields": [
      {
        "fieldPath": "clubId",
        "order": "ASCENDING"
      },
      {
        "fieldPath": "date",
        "order": "ASCENDING"
      }
    ]
  },
  {
    "collectionGroup": "transactions",
    "queryScope": "COLLECTION_GROUP",
    "fields": [
      {
        "fieldPath": "clubId",
        "order": "ASCENDING"
      },
      {
        "fieldPath": "referenceId",
        "order": "ASCENDING"
      }
    ]
  },
  {
    "collectionGroup": "payments",
    "queryScope": "COLLECTION_GROUP",
    "fields": [
      {
        "fieldPath": "clubId",
        "order": "ASCENDING"
      },
      {
        "fieldPath": "date",
        "order": "ASCENDING"
      }
    ]
  },
  {
    "collectionGroup": "payments",
    "queryScope": "COLLECTION_GROUP",
    "fields": [
      {
        "fieldPath": "clubId",
        "order": "ASCENDING"
      },
      {
        "fieldPath": "date",
        "order": "DESCENDING"
      }
    ]
  }
]

# Check existing indexes to avoid duplicates
existing_indexes = []
if 'indexes' in data:
    existing_indexes = data['indexes']

for new_idx in new_indexes:
    # simple duplicate check
    if new_idx not in existing_indexes:
        existing_indexes.append(new_idx)

data['indexes'] = existing_indexes

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)

print("Updated firestore.indexes.json")
