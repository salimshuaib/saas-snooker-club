import 'dart:io';

void main() {
  final file = File(
    'lib/features/settings/presentation/screens/settings_screen.dart',
  );
  final lines = file.readAsLinesSync();
  final newLines = lines.sublist(0, 392);

  newLines.addAll([
    "  void _showCurrencyPicker(BuildContext context, WidgetRef ref, Currency currentCurrency) {",
    "    showModalBottomSheet(",
    "      context: context,",
    "      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),",
    "      builder: (context) {",
    "        return SafeArea(",
    "          child: Column(",
    "            mainAxisSize: MainAxisSize.min,",
    "            crossAxisAlignment: CrossAxisAlignment.start,",
    "            children: [",
    "              Padding(",
    "                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),",
    "                child: Text('Select Currency', style: Theme.of(context).textTheme.titleLarge),",
    "              ),",
    "              ...Currency.supportedCurrencies.map(",
    "                (c) => ListTile(",
    "                  leading: Text(c.symbol, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),",
    "                  title: Text(c.name),",
    "                  subtitle: Text(c.code),",
    "                  trailing: c.code == currentCurrency.code ? const Icon(Icons.check, color: AppColors.success) : null,",
    "                  onTap: () {",
    "                    ref.read(currencyProvider.notifier).setCurrency(c);",
    "                    Navigator.of(context).pop();",
    "                  },",
    "                ),",
    "              ),",
    "              const Gap(24),",
    "            ],",
    "          ),",
    "        );",
    "      },",
    "    );",
    "  }",
    "}",
  ]);

  file.writeAsStringSync(newLines.join('\n'));
}
