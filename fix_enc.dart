import 'dart:io';

void main() {
  final files = [
    'lib/features/games/presentation/screens/billing_screen.dart',
    'lib/features/games/presentation/screens/table_details_screen.dart',
    'lib/features/games/presentation/widgets/payer_selection_widget.dart'
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    
    // Replace the specific corrupted bytes
    content = content.replaceAll('Ã¢â€šÂ¹', '₹');
    content = content.replaceAll('â,¹', '₹');
    content = content.replaceAll('â”€â”€', '──');
    
    file.writeAsStringSync(content);
    print('Fixed $path');
  }
}
