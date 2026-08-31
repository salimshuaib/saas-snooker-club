with open('lib/core/models/club.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final String? logoUrl;", "final String? logoUrl;\n  final String? slug;")
content = content.replace("this.logoUrl,", "this.logoUrl,\n    this.slug,")
content = content.replace("logoUrl: map['logoUrl'] as String?,", "logoUrl: map['logoUrl'] as String?,\n      slug: map['slug'] as String?,")
content = content.replace("'logoUrl': logoUrl,", "'logoUrl': logoUrl,\n      'slug': slug,")

with open('lib/core/models/club.dart', 'w', encoding='utf-8') as f:
    f.write(content)
