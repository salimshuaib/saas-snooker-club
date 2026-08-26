import os
import re

def fix_dispose():
    path = 'lib/features/games/presentation/screens/billing_screen.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # Add dispose before didChangeDependencies
    c = c.replace(
        "  bool _liabilitiesInitialized = false;",
        """  @override
  void dispose() {
    _finalAmountController.dispose();
    super.dispose();
  }

  bool _liabilitiesInitialized = false;"""
    )
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

fix_dispose()
