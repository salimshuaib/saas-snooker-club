import re

def update_credit_transaction():
    path = 'lib/features/credit/domain/models/credit_models.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add final PaymentMethod? paymentMethod; to CreditTransaction
    old_fields = """  final double remainingAmount;
  final CreditTransactionStatus status;
  final DateTime date;
  
  // Minimal info for display without needing to fetch the referenced doc immediately
  final String title; 
  final String? subtitle;"""
    
    new_fields = """  final double remainingAmount;
  final CreditTransactionStatus status;
  final DateTime date;
  final PaymentMethod? paymentMethod;
  
  // Minimal info for display without needing to fetch the referenced doc immediately
  final String title; 
  final String? subtitle;"""
    content = content.replace(old_fields, new_fields)
    
    # Add to constructor
    old_constructor = """    required this.amount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.status = CreditTransactionStatus.pending,
    required this.date,
    required this.title,
    this.subtitle,
  });"""
    
    new_constructor = """    required this.amount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.status = CreditTransactionStatus.pending,
    required this.date,
    this.paymentMethod,
    required this.title,
    this.subtitle,
  });"""
    content = content.replace(old_constructor, new_constructor)
    
    # Add to copyWith
    old_copy = """    CreditTransactionStatus? status,
    DateTime? date,
    String? title,
    String? subtitle,
  }) {
    return CreditTransaction("""
    
    new_copy = """    CreditTransactionStatus? status,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? title,
    String? subtitle,
  }) {
    return CreditTransaction("""
    content = content.replace(old_copy, new_copy)
    
    old_copy_body = """      status: status ?? this.status,
      date: date ?? this.date,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );"""
    
    new_copy_body = """      status: status ?? this.status,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );"""
    content = content.replace(old_copy_body, new_copy_body)
    
    # Add to toMap
    old_tomap = """      'remainingAmount': remainingAmount,
      'status': status.name,
      'date': Timestamp.fromDate(date),
      'title': title,
      'subtitle': subtitle,
    };
  }"""
    
    new_tomap = """      'remainingAmount': remainingAmount,
      'status': status.name,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod?.name,
      'title': title,
      'subtitle': subtitle,
    };
  }"""
    content = content.replace(old_tomap, new_tomap)
    
    # Add to fromMap
    old_frommap = """      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      status: CreditTransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CreditTransactionStatus.pending,
      ),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title: map['title'] as String? ?? 'Unknown',
      subtitle: map['subtitle'] as String?,
    );"""
    
    new_frommap = """      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      status: CreditTransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CreditTransactionStatus.pending,
      ),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] != null 
          ? PaymentMethod.values.firstWhere((e) => e.name == map['paymentMethod'], orElse: () => PaymentMethod.credit) 
          : null,
      title: map['title'] as String? ?? 'Unknown',
      subtitle: map['subtitle'] as String?,
    );"""
    content = content.replace(old_frommap, new_frommap)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_credit_transaction()
