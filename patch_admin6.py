import re

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r"\s*Widget _buildRateOverviewTile\(String label, String rates\) \{\s*return Padding\(\s*padding: const EdgeInsets\.symmetric\(vertical: 6\.0\),\s*child: Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*Text\(\s*label,\s*style: const TextStyle\(fontWeight: FontWeight\.w500, fontSize: 13\),\s*\),\s*if \(rates\.isNotEmpty\)\s*Text\(\s*rates,\s*style: const TextStyle\(fontWeight: FontWeight\.bold, fontSize: 13\),\s*\),\s*\],\s*\),\s*\);\s*\}",
    "",
    content
)

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
