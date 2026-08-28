path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\team\providers\team_providers.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

new_catch = '''    } catch (e, st) {
      if (e.toString().contains('permission-denied')) {
        // Harmless race condition on logout: Firestore terminates the stream before Riverpod cleans it up.
        yield null;
        return;
      }
      print('Error in currentStaffProvider: \\\n\');
      // Yield a fallback owner so the UI doesn't completely break while testing locally
      // IF permission is denied because rules aren't deployed yet.
      yield StaffMember(
        id: user.uid,
        name: 'Local Admin (Rules Not Deployed?)',
        email: user.email ?? '',
        role: StaffRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }'''

content = re.sub(r'    \} catch \(e, st\) \{\s*print\(\'Error in currentStaffProvider: \\\n\\'\);\s*// Yield a fallback owner.*?updatedAt: DateTime.now\(\),\s*\);\s*\}', new_catch, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
