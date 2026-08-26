import os

path = 'lib/features/games/domain/models/game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    """enum PaymentMethod {
  cash,
  upi,
  credit;""",
    """enum PaymentMethod {
  cash,
  upi,
  credit,
  split;"""
)

c = c.replace(
    """    case PaymentMethod.credit:
        return 'Credit';
    }
  }
}""",
    """    case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.split:
        return 'Split';
    }
  }
}"""
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
