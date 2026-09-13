import os

providers_path = 'lib/features/inventory/providers/inventory_providers.dart'
with open(providers_path, 'r', encoding='utf-8') as f:
    prov_text = f.read()

prov_text = prov_text.replace("return InventoryRepository(\n    ref.watch(firestoreServiceProvider).db,\n    clubId: clubId,\n  );", "return InventoryRepository(\n    ref.watch(firestoreServiceProvider).db,\n    ref: ref,\n    clubId: clubId,\n  );")

with open(providers_path, 'w', encoding='utf-8') as f:
    f.write(prov_text)
