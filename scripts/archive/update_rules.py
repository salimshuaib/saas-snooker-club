import re

def modify_rules(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    helpers = """
    // Helper function to check if the user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    function getStaffDoc() {
      return get(/databases/$(database)/documents/team_members/$(request.auth.uid));
    }
    
    function isOwner() {
      return getStaffDoc() == null || getStaffDoc().data.role == 'owner';
    }
    
    function isActive() {
      return getStaffDoc() == null || getStaffDoc().data.isActive == true;
    }
    
    function canAccess() {
      return isAuthenticated() && isActive();
    }
    
    function canDelete() {
      return isOwner(); // Only owners can actually perform permanent deletes of games/sales
    }"""
    
    content = re.sub(r'// Helper function to check if the user is authenticated\s*function isAuthenticated\(\) \{\s*return request\.auth != null;\s*\}', '', content, flags=re.DOTALL)
    content = content.replace('// Existing Collections', helpers + '\n\n    // Existing Collections')

    content = content.replace('allow read, write: if isAuthenticated();', 'allow read, write: if canAccess();')
    content = content.replace('allow read: if isAuthenticated();', 'allow read: if canAccess();')
    content = content.replace('allow write: if isAuthenticated();', 'allow write: if canAccess();')
    content = content.replace('allow create, delete: if isAuthenticated();', 'allow create: if canAccess(); allow delete: if canDelete();')
    content = content.replace('allow create: if isAuthenticated();', 'allow create: if canAccess();')

    # Add team and audit logs
    collections = """
    match /team_members/{userId} {
      allow read: if canAccess();
      allow write: if isOwner();
    }
    
    match /audit_logs/{logId} {
      allow read: if isOwner() || (getStaffDoc() != null && getStaffDoc().data.role == 'manager');
      allow create: if canAccess();
      allow update, delete: if false;
    }
"""
    if "match /team_members" not in content:
        content = content.replace('// Settings Collection', collections + '\n    // Settings Collection')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_rules('firestore.rules')
    print("Done")
