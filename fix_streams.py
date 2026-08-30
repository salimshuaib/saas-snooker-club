import os
import glob

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # 1. Remove microtasks
    content = content.replace("await Future.microtask(() {});\n", "")
    content = content.replace("await Future.microtask(() {});", "")

    # 2. Fix Stream.empty() in async* generators
    # In analytics_providers.dart, credit_providers.dart, inventory_providers.dart
    content = content.replace("yield* const Stream.empty();\n    return;", "yield [];\n    return;")

    # 3. Fix Stream.empty() in normal functions
    # List providers
    content = content.replace("return const Stream.empty();", "return Stream.value([]);")
    
    # Fix the double and GameSession? providers manually since they were falsely caught by the above rule
    # In games_providers.dart:
    if "games_providers.dart" in filepath:
        content = content.replace("return Stream.value([]);\n  return repo.watchActiveGame(tableId);", "return Stream.value(null);\n  return repo.watchActiveGame(tableId);")
        
        content = content.replace("if (repo.clubId == null) return Stream.value([]);\n  return repo.watchAllGamesByDate(dateStr).map((", "if (repo.clubId == null) return Stream.value(0.0);\n  return repo.watchAllGamesByDate(dateStr).map((")
        
    if "club_scope_provider.dart" in filepath:
        content = content.replace("if (user == null) return Stream.value([]);", "if (user == null) return Stream.value(null);")
        content = content.replace("if (clubId == null) return Stream.value([]);", "if (clubId == null) return Stream.value(null);")
        content = content.replace("return const PlatformConfig();", "return Stream.value(const PlatformConfig());")

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
