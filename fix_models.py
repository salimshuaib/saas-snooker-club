import os
import re

filepath = 'lib/features/games/domain/models/game_models.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add pendingBill to TableStatus
if 'pendingBill' not in content:
    content = content.replace('  completed,\n}', '  completed,\n  pendingBill,\n}')

# 2. Add fields to GameSession
fields = '''
  final String? pendingBillCustomerId;
  final String? pendingBillCustomerName;
  final DateTime? markedPendingAt;
  final String? markedPendingByUserId;
  final String? markedPendingByName;
'''
if 'pendingBillCustomerId' not in content:
    content = content.replace('  final String? paymentStatus;', '  final String? paymentStatus;\n' + fields)

# 3. Add to constructor
constructor_args = '''
    this.pendingBillCustomerId,
    this.pendingBillCustomerName,
    this.markedPendingAt,
    this.markedPendingByUserId,
    this.markedPendingByName,
'''
if 'this.pendingBillCustomerId' not in content:
    content = content.replace('    this.paymentStatus,\n  });', '    this.paymentStatus,\n' + constructor_args + '  });')

# 4. Add to copyWith signature
copy_with_args = '''
    String? pendingBillCustomerId,
    String? pendingBillCustomerName,
    DateTime? markedPendingAt,
    String? markedPendingByUserId,
    String? markedPendingByName,
'''
if 'String? pendingBillCustomerId' not in content:
    content = content.replace('    String? paymentStatus,\n  }) {', '    String? paymentStatus,\n' + copy_with_args + '  }) {')

# 5. Add to copyWith return
copy_with_ret = '''
      pendingBillCustomerId: pendingBillCustomerId ?? this.pendingBillCustomerId,
      pendingBillCustomerName: pendingBillCustomerName ?? this.pendingBillCustomerName,
      markedPendingAt: markedPendingAt ?? this.markedPendingAt,
      markedPendingByUserId: markedPendingByUserId ?? this.markedPendingByUserId,
      markedPendingByName: markedPendingByName ?? this.markedPendingByName,
'''
if 'pendingBillCustomerId: pendingBillCustomerId' not in content:
    content = content.replace('      paymentStatus: paymentStatus ?? this.paymentStatus,\n      paidAmount:', '      paymentStatus: paymentStatus ?? this.paymentStatus,\n' + copy_with_ret + '      paidAmount:')

# 6. Add to toMap
to_map = '''
      'pendingBillCustomerId': pendingBillCustomerId,
      'pendingBillCustomerName': pendingBillCustomerName,
      'markedPendingAt': markedPendingAt?.toIso8601String(),
      'markedPendingByUserId': markedPendingByUserId,
      'markedPendingByName': markedPendingByName,
'''
if "'pendingBillCustomerId': pendingBillCustomerId" not in content:
    content = content.replace("      'paymentStatus': paymentStatus,\n      'paidAmount':", "      'paymentStatus': paymentStatus,\n" + to_map + "      'paidAmount':")

# 7. Add to fromMap
from_map = '''
      pendingBillCustomerId: map['pendingBillCustomerId'] as String?,
      pendingBillCustomerName: map['pendingBillCustomerName'] as String?,
      markedPendingAt: map['markedPendingAt'] != null ? DateTime.parse(map['markedPendingAt'] as String) : null,
      markedPendingByUserId: map['markedPendingByUserId'] as String?,
      markedPendingByName: map['markedPendingByName'] as String?,
'''
if "pendingBillCustomerId: map['pendingBillCustomerId']" not in content:
    content = content.replace("      paymentStatus: map['paymentStatus'] as String?,\n      paidAmount:", "      paymentStatus: map['paymentStatus'] as String?,\n" + from_map + "      paidAmount:")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('game_models fixed')
