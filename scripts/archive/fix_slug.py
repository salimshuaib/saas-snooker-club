with open('lib/features/settings/data/settings_repository.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("generatedSlug ??= 'club-';", "generatedSlug ??= 'club-' + chr(36) + '{clubId!.substring(0, 6).toLowerCase()}';")

with open('lib/features/settings/data/settings_repository.dart', 'w', encoding='utf-8') as f:
    f.write(content)
