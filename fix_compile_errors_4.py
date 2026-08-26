import os

# 1. Revert PaymentMethod enum in game_models.dart
path = 'lib/features/games/domain/models/game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    """enum PaymentMethod {
  cash,
  upi,
  credit,
  split;""",
    """enum PaymentMethod {
  cash,
  upi,
  credit;"""
)

c = c.replace(
    """    case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.split:
        return 'Split';
    }
  }
}""",
    """    case PaymentMethod.credit:
        return 'Credit';
    }
  }
}"""
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)

# 2. Fix GamesRepository
path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    "if (session.paymentMethod == PaymentMethod.split && session.playerPaymentMethods != null) {",
    "if (session.paymentMethod == null && session.playerPaymentMethods != null && session.playerPaymentMethods!.isNotEmpty) {"
)

c = c.replace(
    "} else if (session.paymentMethod != null && session.paymentMethod != PaymentMethod.split && session.paidBy != null) {",
    "} else if (session.paymentMethod != null && session.paidBy != null) {"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
