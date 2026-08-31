with open('lib/features/settings/presentation/widgets/business_edit_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("content: Text('Error saving settings: \'),", "content: Text('Error saving settings: ' + e.toString()),")

with open('lib/features/settings/presentation/widgets/business_edit_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)
