import re

def fix_model():
    path = 'lib/features/credit/domain/models/credit_models.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_const = """  const CreditTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.referenceId,
    required this.amount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    required this.status,
    required this.date,
    required this.title,
    this.subtitle,
  });"""
  
    new_const = """  const CreditTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.referenceId,
    required this.amount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    required this.status,
    required this.date,
    this.paymentMethod,
    required this.title,
    this.subtitle,
  });"""
    
    content = content.replace(old_const, new_const)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_model()
