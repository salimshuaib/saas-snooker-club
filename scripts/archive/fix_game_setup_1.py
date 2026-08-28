import os
import re

def fix_game_setup():
    path = 'lib/features/games/presentation/widgets/game_setup_sheet.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update BillingType dropdown to use supported types
    old_dropdown = """                              DropdownButtonFormField<BillingType>(
                                isExpanded: true,
                                value: _billingType,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: BillingType.values.map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.displayName),
                                )).toList(),
                                onChanged: (v) => setState(() => _billingType = v!),
                              ),"""
                              
    new_dropdown = """                              DropdownButtonFormField<BillingType>(
                                isExpanded: true,
                                value: TablePricingConfig.supportedBillingTypes(widget.table.type, _gameType).contains(_billingType) ? _billingType : TablePricingConfig.supportedBillingTypes(widget.table.type, _gameType).first,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: TablePricingConfig.supportedBillingTypes(widget.table.type, _gameType).map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.displayName),
                                )).toList(),
                                onChanged: (v) => setState(() => _billingType = v!),
                              ),"""
                              
    content = content.replace(old_dropdown, new_dropdown)
    
    # 2. Hide Target Points for Race games
    # First, let's see where target points is. I should check the file for "targetPoints".

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_game_setup()
