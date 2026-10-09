import re

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make rates optional in the rendering so it doesn't take up space on the right
content = re.sub(
    r"(Widget _buildRateOverviewTile\(String label, String rates\) \{\s*return Padding\(\s*padding: const EdgeInsets\.symmetric\(vertical: 6\.0\),\s*child: Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*Text\(\s*label,\s*style: const TextStyle\(fontWeight: FontWeight\.w500, fontSize: 13\),\s*\),\s*Text\(\s*rates,\s*style: const TextStyle\(fontWeight: FontWeight\.bold, fontSize: 13\),\s*\),\s*\])",
    "Widget _buildRateOverviewTile(String label, String rates) {\n    return Padding(\n      padding: const EdgeInsets.symmetric(vertical: 6.0),\n      child: Row(\n        mainAxisAlignment: MainAxisAlignment.spaceBetween,\n        children: [\n          Text(\n            label,\n            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),\n          ),\n          if (rates.isNotEmpty)\n            Text(\n              rates,\n              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),\n            ),\n        ]",
    content
)

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
