with open('lib/features/dashboard/presentation/widgets/financial_summary_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("\\'Pending Bills\\'", "'Pending Bills'")

with open('lib/features/dashboard/presentation/widgets/financial_summary_card.dart', 'w', encoding='utf-8') as f:
    f.write(content)
