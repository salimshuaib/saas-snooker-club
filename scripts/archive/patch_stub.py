path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\models\game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content += '''
// Stub for OtherGameResource
class OtherGameResource {
  final String id;
  final String name;
  final TableStatus status;
  final bool isActive;
  final String category;
  final Map<String, double> pricing;

  OtherGameResource({
    required this.id,
    required this.name,
    required this.status,
    required this.isActive,
    required this.category,
    required this.pricing,
  });

  factory OtherGameResource.fromMap(Map<String, dynamic> map) {
    return OtherGameResource(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      status: TableStatus.available,
      isActive: map['isActive'] ?? true,
      category: map['category'] ?? '',
      pricing: {},
    );
  }
}
'''
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
