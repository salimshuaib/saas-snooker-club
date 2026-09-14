import os

filepath = 'lib/core/widgets/responsive_scaffold_wrapper.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace Center+ConstrainedBox with just child
text = text.replace("""              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: child,
                ),
              ),""", "              child: child,")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
