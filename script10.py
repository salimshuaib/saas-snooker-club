import re

with open('lib/core/routes/route_names.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("static const String live = '/live';\n  static const String live = '/live';", "static const String live = '/live';")

with open('lib/core/routes/route_names.dart', 'w', encoding='utf-8') as f:
    f.write(text)
